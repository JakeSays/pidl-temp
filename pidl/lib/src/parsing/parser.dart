// ignore_for_file: prefer_conditional_assignment

import '../petit/petitparser.dart';
import '../petit/reflection.dart';
import '../petit/src/debug/trace.dart';
import '../petit/src/definition/internal/reference.dart';
import 'ast.dart';
import '../console.dart';
import 'util.dart';
import '../source.dart';
import '../kinds.dart';
import "../diagnostics.dart";
import '../source_code_provider.dart';
import 'tracer.dart';
import 'parser_configuration.dart';
import 'token_syntax_parser.dart';
import 'parser_name_util.dart';
import 'parser_context.dart';
import 'location_builder.dart';
import 'reduction_parser.dart';

class ParseError extends Error
{
    final String message;

    ParseError({required this.message});
}

class ParseResult
{
    CompilationUnitSyntax mainUnit;
    List<CompilationUnitSyntax> allImportedUnits;

    List<CompilationUnitSyntax> allUnits = [];

    ParseResult({
        required this.mainUnit,
        required this.allImportedUnits
    })
    {
        allUnits.add(mainUnit);
        allUnits.addAll(allImportedUnits);
    }
}

class IdlParser
{
    Diagnostics diagnostics;
    final SourceCodeProvider _sourceProvider;
    final ParserConfiguration _config;

    IdlParser({
        required SourceCodeProvider sourceProvider,
        required this.diagnostics,
        ParserConfiguration? config
    }) : _sourceProvider = sourceProvider,
         _config = config ?? ParserConfiguration();

    CompilationUnitSyntax? parseSingleFile(String sourcePath) => _parseSingleFile(sourcePath, false);

    CompilationUnitSyntax? _parseSingleFile(String sourcePath, bool isimport)
    {
        try 
        {
            final source = isimport
                ? _sourceProvider.loadImport(sourcePath)
                : _sourceProvider.loadMainFile(sourcePath);

            if (source == null)
            {
                return null;
            }
            return _parse(source);
        }
        on Exception catch (e)
        {
            diagnostics.addIssue(ExceptionIssue(exception: e));
            return null;
        }
    }

    ParseResult? parseFile(String mainFile)
    {
        final imports = <CompilationUnitSyntax>[];
        
        final mainCu = _parseSingleFile(mainFile, false);

        if (mainCu == null)
        {
            return null;
        }

        if (mainCu.imports.isEmpty)
        {
            return ParseResult(mainUnit: mainCu, allImportedUnits: []);
        }
        
        final cuIndex = <String, CompilationUnitSyntax>{};
        cuIndex[mainCu.source.path] = mainCu;

        final importQueue = <ImportSyntax>[];
        importQueue.addAll(mainCu.imports);

        while (importQueue.isNotEmpty)
        {
            final import = importQueue.removeLast();
            final importPath = _sourceProvider.normalizePath(import.path);
            var cu = cuIndex[importPath];
            if (cu != null)
            {
                import.unit = cu;
                continue;
            }

            import.unit = _parseSingleFile(import.path, true);
            if (import.unit == null)
            {
                return null;
            }
            imports.add(import.unit!);
            cuIndex[importPath] = import.unit!;

            importQueue.addAll(import.unit!.imports);            
        }

        return ParseResult(mainUnit: mainCu, allImportedUnits: imports);
    }

    CompilationUnitSyntax? _parse(SourceFile source)
    {
        final parser = _IdlParser(_config, diagnostics);

        source.buildLineIndex();

        final result = parser.go(source);
        if (result.isSuccess)
        {
            return result.value as CompilationUnitSyntax;
        }

        diagnostics.addIssue(ParseIssue(
            code: IssueCode.somethingBadHappened, 
            severity: IssueSeverity.error,
            message: result.message,
            lastSuccessfulNode: parser.lastSuccessfulNode,
            deepestFailure: parser.deepestFailure,
            location: SourceLocation(source: source, startOffset: result.position, length: 1)
        ));

        return null;
    }

    void validate()
    {
        final parser = _IdlParser.dummy().build();

        linter(parser, callback: (issue) {
            redln("Issue: ${issue.title}, ${issue.description}");
        });
    }

    void dump()
    {
        final root = _IdlParser(_config, diagnostics).build<CompilationUnitSyntax>();
        
        for (final info in IdlParserIterable(root))
        {
            //Instance of 'CastParser<void, CompilationUnit>'
            final indent = "   " * info.depth;
            var text = info.parser.toString();
            text = text.substring(13, text.length)
                .replaceAll('\'', '')
                .replaceAll("Parser", "");
            writeln("$indent$text");
        }
    }
}

abstract class SourceProvider
{
    SourceFile get currentSource;
}

class _IdlParser extends GrammarDefinition
    implements SourceProvider,
        ParserContext
{
    @override
    late final SourceFile source;

    final Diagnostics diagnostics;

    CommentsSyntax? _attachedComments;
    final List<CommentsSyntax?> _commentScopes = [];
    SyntaxConfiguration get _syntax => _config.syntax;
    final ParserConfiguration _config;
    ParserTracer? _tracer;
    SyntaxNode? _lastSuccessfulNode;
    bool _haveError = false;

    _IdlParser(this._config, this.diagnostics);

    @override
    SyntaxNode? get lastSuccessfulNode => _lastSuccessfulNode;

    @override
    set lastSuccessfulNode(SyntaxNode? node)
    {
        if (node is ListSyntax && node.list.isEmpty)
        {
            return;
        }

        if (node!.parseDepth < (_lastSuccessfulNode?.parseDepth ?? -1))
        {
            return;
        }    

        _lastSuccessfulNode = node;
    }

    @override
    ParseFailure? get deepestFailure => null;

    @override
    SourceFile get currentSource => source;

    @override
    void notifyFailure(int position, int depth, [String? message])
    {
        if (_haveError)
        {
            return;
        }

        diagnostics.addIssue(
            ParseIssue(
                code: IssueCode.syntaxError, 
                severity: IssueSeverity.error,
                message: message,
                location: SourceLocation(source: source, startOffset: position, length: 1)
            ));

        _haveError = true;
    }
   
    _IdlParser.dummy()
        : source = SourceFile.unknown,
          diagnostics = Diagnostics(),
          _config = ParserConfiguration();

    Result test(SourceFile sourceFile)
    {
        source = sourceFile;
        final parser = build(start: enumerant);
        final result = parser.parse(sourceFile.content);

        return result;
    }

    Result go(SourceFile sourceFile)
    {
        source = sourceFile;
        var parser = build();

        completeParser(parser);

        if (!_config.enableTracingParser)
        {
            return parser.parse(sourceFile.content);
        }

        try
        {
            _tracer = ParserTracer();
            return trace(parser, output: _tracer!.trace).parse(sourceFile.content);
        }
        finally
        {
            _tracer?.dump();
        }
    }

    Parser completeParser(Parser parser)
    {
        parser.makeName();
        for (final info in IdlParserIterable(parser))
        {
            info.parser.makeName();
            if (info.parser.depth == -1)
            {
                info.parser.depth = info.depth;
            }

            //print("${info.depth}: ${info.parser.makeName()}");
        }

        return parser;
    }

    void _addComment(CommentSyntax comment)
    {
        (_attachedComments ??= CommentsSyntax()).addComment(comment);
    }

    void _pushCommentScope()
    {
        _commentScopes.add(_attachedComments);
        _attachedComments = null;
    }

    CommentsSyntax? _popCommentScope()
    {
        return null;
        // _attachedComments = _commentScopes.removeLast();
        // return attachedComments;
    }

    CommentsSyntax? get attachedComments
    {
        final comments = _attachedComments;
        _attachedComments = null;
        return comments;
    }

    Parser keyword(String keyword) => 
        ref2(_wholeWord, _token, keyword, "'$keyword'")
            .reduce(this, (location, nodes) 
            {
                final token = nodes.takeAs<TokenSyntax>();
                return KeywordSyntax(
                    keyword: token.token,
                    location: location);
            });

    @override
    Parser start() => _(compilationUnit).end();

    Parser compilationUnit() =>
        _(topLevelDefinitions).star()
            .reduce(this, (location, nodes) 
            {
                final types = nodes.takeAllAs<SyntaxNode>();
                return CompilationUnitSyntax.fromNodes(source, types);
            });

    Parser topLevelDefinitions() =>
        (_(definition) | _($import));

    Parser definition() =>
        (_(struct) |
        _(constant) |
        _($enum) |
        _(interface) |
        _(alias) |
        _($namespace));

        //_(comments));

    Parser $import() =>
        (_(attributes).optional() &
         keyword(_syntax.importKeyword) &
         _(stringLiteral).error(this, "Missing import path") &
         (keyword(_syntax.asKeyword) & _(ident).error(this, "Missing import alias")).optional() & semicolon())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final importKw = nodes.keyword();
                final importPath = nodes.takeAs<LiteralSyntax>();
                final asKw = nodes.keywordOpt();
                final scope = nodes.takeIf<IdentifierSyntax>();
                final semi = nodes.token();

                return ImportSyntax(
                    importKeyword: importKw,
                    importPath: importPath,
                    asKeyword: asKw,
                    semicolon: semi,
                    scope: scope,
                    location: location,
                    attributes: attrs);
            });

    Parser semicolon() => 
        _(() => token(";").error(this));

    Parser openScope() =>
        _(() => token(_syntax.scopeOpenToken, "${_syntax.scopeOpenToken} expected").error(this));
    Parser closeScope() =>
        _(() => token(_syntax.scopeCloseToken, "${_syntax.scopeCloseToken} expected").error(this));

    Parser $namespace() =>
        (_(attributes).optional() &
         keyword(_syntax.namespaceKeyword) &
         _(ident).error(this, "Missing identifier") &
         openScope() &
         _(definition).star() &
         closeScope())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final kw = nodes.keyword();
                final os = nodes.token();
                final name = nodes.takeAs<IdentifierSyntax>();
                final members = nodes.takeRestAs<SyntaxNode>();
                final cs = nodes.token();

                return NamespaceSyntax.fromNodes(
                    kw,
                    os,
                    cs,
                    name,
                    members,
                    location,
                    attrs,
                    _popCommentScope());
            });

    Parser alias() =>
        (_(attributes).optional() &
         keyword(_syntax.aliasKeyword) &
         _(ident).error(this, "Missing identifier") &
         token(_syntax.assignmentToken).error(this) &
         _(typeReference).error(this, "Missing alias target") & semicolon())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final keyword = nodes.keyword();
                final name = nodes.takeAs<IdentifierSyntax>();
                final assign = nodes.token();
                final type = nodes.takeAs<TypeReferenceSyntax>();
                final semi = nodes.token();

                return TypeAliasSyntax(                    
                    name: name,
                    assignmentToken: assign, 
                    keyword: keyword,
                    semicolon: semi,
                    aliasedType: type,
                    location: location,
                    attachedComments: attachedComments,
                    attributes: attrs);
            });

    Parser interface() =>
        (_(attributes).optional() &
         keyword(_syntax.interfaceKeyword) &
         _(ident).error(this, "Missing identifier") &
         _(baseInterfaces).optional() &
         openScope() &
         _(methods).optional() &
         closeScope())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final kw = nodes.keyword();
                final name = nodes.takeAs<IdentifierSyntax>();
                final bases = nodes.takeIf<BaseInterfacesSyntax>();
                final open = nodes.token();
                final methods = nodes.takeIf<MethodsSyntax>();
                final close = nodes.token();

                return InterfaceSyntax(                
                    name: name, 
                    bases: bases,
                    keyword: kw,
                    openScopeToken: open,
                    closeScopeToken: close,
                    methods: methods,
                    location: location,
                    attachedComments: _popCommentScope(),
                    attributes: attrs);
            });

    Parser _baseTypeReference(BaseTypeCreator creator, BaseKind kind) =>
        (token(",") & 
        _(qualIdent).error(this, "Trailing comma not allowed")).reduce(this, (location, nodes) 
        {            
            return creator(
                location: location,
                kind: kind,
                separator: nodes.token(),
                name: nodes.takeAs<IdentifierSyntax>());
        });

    Parser baseType(BaseKind kind, [BaseTypeCreator? creator]) =>
        ref2(_baseTypeReference, creator ?? BaseTypeSyntax.create, kind);

    Parser _primaryBaseTypeReference(BaseKind kind, BaseTypeCreator creator) =>
        (keyword(_syntax.baseSeparatorKeyword) & 
        _(kind == BaseKind.$enum ? integerType : qualIdent).error(this))
            .reduce(this, (location, nodes) 
            {            
                if (kind == BaseKind.$enum)
                {
                    final extkwd = nodes.keyword();
                    final base = nodes.takeAs<TypeReferenceSyntax>();

                    return creator(
                        location: location,
                        kind: kind,
                        extendsKeyword: extkwd,
                        name: base.name,
                        builtinKind: base.builtinKind,
                        keyword: base.keyword);
                }
                else
                {
                    return creator(
                        location: location,
                        kind: kind,
                        extendsKeyword: nodes.keyword(),
                        name: nodes.takeAs<IdentifierSyntax>());
                }
            });

    Parser primaryBaseType(BaseKind kind, [BaseTypeCreator? creator]) =>
        ref2(_primaryBaseTypeReference, kind, creator ?? BaseTypeSyntax.create);

    Parser baseInterfaces() =>
        (primaryBaseType(BaseKind.interface) &
        baseType(BaseKind.interface).star())
            .reduce(this, (location, nodes) 
            {
                final bases = nodes.filterRestAs<BaseTypeSyntax>();
                return BaseInterfacesSyntax(
                    list: bases,
                    location: location);
            });

    Parser methods() =>
        (_(method) & _(method).star())
            .reduce(this, (location, nodes) 
            {
                final methods = nodes.takeAllAs<MethodSyntax>();
                return MethodsSyntax(                    
                    list: methods,
                    location: location);
            });

    Parser method() =>
        (_(attributes).optional() &
         _(methodReturnType) &
         _(ident).error(this, "Missing identifier") &
         token(_syntax.parenOpenToken).error(this) &
         _(methodParameters).optional() &
         token(_syntax.parenCloseToken).error(this) & semicolon())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final returnType = nodes.takeAs<TypeReferenceSyntax>();
                final name = nodes.takeAs<IdentifierSyntax>();
                final open = nodes.token();
                final parameters = nodes.takeIf<ParametersSyntax>() ?? ParametersSyntax();
                final close = nodes.token();
                final semi = nodes.token();
                return MethodSyntax(                    
                    name: name, 
                    type: returnType,
                    semicolon: semi,
                    openParen: open,
                    closeParen: close,
                    parameters: parameters,
                    location: location,
                    attachedComments: attachedComments,
                    attributes: attrs);
            });

    Parser methodReturnType() =>
        (_(typeReference) | _(voidType))
            .reduce(this, (location, nodes) 
            {
                final returnType = nodes.takeAs<TypeReferenceSyntax>();
                return returnType;
            });

    Parser methodParameters() =>
        (_(methodParameter) & _(methodParameterRest))
            .reduce(this, (location, nodes) 
            {
                final parameters = nodes.filterRestAs<ParameterSyntax>();
                return ParametersSyntax(                    
                    list: parameters,
                    location: location);
            })
        ;

    Parser methodParameterRest() =>
        (token(",") & _(methodParameter).error(this, "Trailing comma not allowed")).star()
            .reduce(this, (location, nodes) 
            {
                if (nodes.done)
                {
                    return null;
                }
                final separator = nodes.token();
                final param = nodes.takeAs<ParameterSyntax>();
                param.separator = separator;
                return param;
            });

    Parser methodParameter() =>
        (_(attributes).optional() &
         _(typeReference) &
         _(qualIdent).error(this, "Missing identifier") &
         _(initExpressionOpt))
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final type = nodes.takeAs<TypeReferenceSyntax>();
                final name = nodes.takeAs<IdentifierSyntax>();
                final dflt = nodes.takeIf<AssignmentExpressionSyntax>();

                return ParameterSyntax(                    
                    name: name, 
                    type: type,
                    initializer: dflt,
                    location: location,
                    attributes: attrs);
            });

    Parser $enum() =>
        (_(attributes).optional() &
         keyword(_syntax.enumKeyword) &
         _(ident).error(this, "Missing identifier") &
         primaryBaseType(BaseKind.$enum).optional() &
         openScope() &
         _(enumerants).optional() &
         closeScope())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final keyword = nodes.keyword();
                final name = nodes.takeAs<IdentifierSyntax>();
                var baseType = nodes.takeIf<BaseTypeSyntax>();
                final open = nodes.token();
                final members = nodes.takeIf<EnumerantsSyntax>();
                final close = nodes.token();

                if (baseType == null)
                {
                    final loc = SourceLocation(
                        source: source, 
                        startOffset: name.location!.start.offset,
                        length: 0);
                    baseType = BaseTypeSyntax(
                        kind: BaseKind.$enum,
                        name: IdentifierSyntax(nameToken: TokenSyntax(token: _syntax.int32Keyword, location: loc)),
                        keyword: KeywordSyntax(keyword: _syntax.int32Keyword, location: loc),
                        builtinKind: TypeKind.int32, 
                        location: loc);                    
                }

                return EnumSyntax(                    
                    name: name,
                    type: baseType, 
                    keyword: keyword,
                    openScopeToken: open,
                    closeScopeToken: close,
                    enumerants: members,
                    location: location,
                    attachedComments: _popCommentScope(),
                    attributes: attrs);
            });

    Parser enumType() =>
        keyword(_syntax.baseSeparatorKeyword) & baseType(BaseKind.$enum).error(this, "Missing base type");
    
    Parser enumerants() =>
        (_(enumerant) & _(enumerant).star())
            .reduce(this, (location, nodes) 
            {
                final values = nodes.takeAllAs<EnumerantSyntax>();
                return EnumerantsSyntax(
                    list: values, location: location);
            })
        ;

    Parser initExpressionOpt() =>
        _(assignmentExpression).optional();

    Parser enumerant() =>
        (attributes().optional() &
         _(ident) &
         _(initExpressionOpt) &
          (token(",") | closeScope().and()))
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final name = nodes.takeAs<IdentifierSyntax>();
                final value = nodes.takeIf<AssignmentExpressionSyntax>();
                final separator = nodes.tokenOpt();
                
                return EnumerantSyntax(                    
                    name: name,
                    initializer: value,
                    location: location,
                    separator: separator,
                    attachedComments: attachedComments,
                    attributes: attrs);
            });

    Parser comments() =>
        (_(docComment) |
         _(lineComment) |
         _(blockComment)).plus().flatten();
            // .reduce(source, (location, nodes) 
            // {
            //     return CommentsSyntax(
                    
            //         list: nodes != null && !nodes.done
            //             ? nodes.takeAllAs<CommentSyntax>()
            //             : [], 
            //         location: location);
            // });

    Parser docComment() =>
        (string('///') & (_(_newLine).neg().star() & _(_newLine).optional()).flatten());
            // .reduce(source, (location, objects) 
            // {
            //     objects!.token();
            //     final text = objects.takeAs<String>();
            //     final result = CommentSyntax(kind: CommentKind.doc, text: text);
            //     _addComment(result);
            //     return result;
            // });
    
    Parser lineComment() =>
        (string('//') & (_(_newLine).neg().star() & _(_newLine).optional()).flatten());
            // .reduce(source, (location, objects) 
            // {
            //     objects!.token();
            //     final text = objects.takeAs<String>();
            //     return CommentSyntax(kind: CommentKind.line, text: text);
            // });

    Parser blockComment() =>
        _(_blockComment);
            // .reduce(source, (location, objects) 
            // {
            //     objects!.token();
            //     final text = objects.takeAs<String>();
            //     return CommentSyntax(kind: CommentKind.block, text: text);
            // });

    Parser _blockComment() =>
        (string('/*') &
         (_(_blockComment) | string('*/').neg()).star().flatten() &
         string('*/'));

    Parser constant() =>
        (_(attributes).optionalWith(AttributesSyntax.none) &
         keyword(_syntax.constantKeyword) & 
         _(typeReference).error(this, "Missing type") & 
         _(ident).error(this, "Missing identifier") &
         _(assignmentExpression) & semicolon())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final keyword = nodes.keyword();
                final type = nodes.takeAs<TypeReferenceSyntax>();
                final name = nodes.takeAs<IdentifierSyntax>();
                final value = nodes.takeAs<AssignmentExpressionSyntax>();
                final semi = nodes.token();

                return ConstantSyntax(
                    name: name, 
                    type: type, 
                    value: value,
                    keyword: keyword,
                    semicolon: semi,
                    location: location,
                    attachedComments: attachedComments,
                    attributes: attrs);
            });

    Parser<OperatorSyntax> oper(OperatorKindSyntax op) 
    {
        String optoken()
        {
            switch(op)
            {
                case OperatorKindSyntax.negate:
                    return _syntax.negateOperatorKeyword;
                case OperatorKindSyntax.subtract:
                    return _syntax.subtractOperatorKeyword;
                case OperatorKindSyntax.add:
                    return _syntax.addOperatorKeyword;
                case OperatorKindSyntax.multiply:
                    return _syntax.multiplyOperatorKeyword;
                case OperatorKindSyntax.divide:
                    return _syntax.divideOperatorKeyword;
                case OperatorKindSyntax.modulo:
                    return _syntax.moduloOperatorKeyword;
                case OperatorKindSyntax.or:
                    return _syntax.orOperatorKeyword;
                case OperatorKindSyntax.xor:
                    return _syntax.xorOperatorKeyword;
                case OperatorKindSyntax.and:
                    return _syntax.andOperatorKeyword;
                case OperatorKindSyntax.leftShift:
                    return _syntax.leftShiftOperatorKeyword;
                case OperatorKindSyntax.rightShift:
                    return _syntax.rightShiftOperatorKeyword;
                case OperatorKindSyntax.compliment:
                    return _syntax.negateOperatorKeyword;
                case OperatorKindSyntax.power:
                    return _syntax.powerOperatorKeyword;
            }
        }

        return ref2(_token, optoken(), 'Operator "${optoken()}" expected')
            .reduceAs(this, (location, objects) 
            {
                final value = objects.takeAs<TokenSyntax>();

                return OperatorSyntax(
                    kind: op,
                    token: value,
                    location: location
                );
            });
    }

    Parser expression() 
    {
        final builder = ExpressionBuilder<ExpressionSyntax>();

        BinaryExpressionSyntax _binaryExpression(ExpressionSyntax lhs, OperatorSyntax op, ExpressionSyntax rhs)
        {
            final loc = LocationBuilder(source: source);
            loc.addSyntax(lhs);
            loc.addSyntax(op);
            loc.addSyntax(rhs);
            final location = loc.done();

            return BinaryExpressionSyntax(operator: op, lhs: lhs, rhs: rhs, location: location);
        }

        UnaryExpressionSyntax _unaryExpression(OperatorSyntax op, ExpressionSyntax rhs)
        {
            final loc = LocationBuilder(source: source);
            loc.addSyntax(op);
            loc.addSyntax(rhs);
            final location = loc.done();
            
            return UnaryExpressionSyntax(operator: op, expression: rhs, location: location);
        }

        Parser<ExpressionSyntax> literalExpression() => _(anyLiteral)
            .reduceAs(this, (location, nodes) 
            {
                final lit = nodes.takeAs<LiteralSyntax>();
                return LiteralExpressionSyntax(literal: lit, location: location);
            });

        Parser<TokenExpressionSyntax> token(String value) => this.token(value)
            .reduceAs(this, (location, nodes) 
            {
                final tok = nodes.takeAs<TokenSyntax>();
                return TokenExpressionSyntax(token: tok, location: location);
            });

        ParenExpressionSyntax parenExpression(TokenExpressionSyntax leftParen, ExpressionSyntax expression, TokenExpressionSyntax rightParen)
        {
            final loc = LocationBuilder(source: source);
            loc.addSyntax(leftParen);
            loc.addSyntax(expression);
            loc.addSyntax(rightParen);
            final location = loc.done();

            return ParenExpressionSyntax(
                leftParen: leftParen, 
                nestedExpression: expression, 
                rightParen: rightParen,
                location: location);
        }

        builder.group()
            ..primitive(literalExpression())
            ..wrapper<TokenExpressionSyntax, TokenExpressionSyntax>(
                token(_syntax.parenOpenToken), 
                token(_syntax.parenCloseToken), 
                parenExpression);
        
        //unary operators
        builder.group()
            ..prefix<OperatorSyntax>(oper(OperatorKindSyntax.negate), _unaryExpression)
            ..prefix<OperatorSyntax>(oper(OperatorKindSyntax.compliment), _unaryExpression);

        // builder.group()
        //     .right<OperatorSyntax>(oper(OperatorKindSyntax.power), _binaryExpression);

        //multiplicatives
        builder.group()
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.multiply), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.divide), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.modulo), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.power), _binaryExpression);

        //additives
        builder.group()
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.add), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.subtract), _binaryExpression);

        //bit shifts
        builder.group()
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.leftShift), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.rightShift), _binaryExpression);
        
        //bit operators
        builder.group()
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.or), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.xor), _binaryExpression)
            ..left<OperatorSyntax>(oper(OperatorKindSyntax.and), _binaryExpression);

        final parser = builder.build();
        return parser;
    }

    Parser assignmentExpression() =>
        (token(_syntax.assignmentToken) &
        _(expression).error(this, "Expression expected"))
            .reduce(this, (location, nodes) 
            {
                final assignment = nodes.token();
                final expression = nodes.takeAs<ExpressionSyntax>();

                return AssignmentExpressionSyntax(
                    assignmentToken: assignment, 
                    value: expression,
                    location: location);
            });
    
    Parser attributes() =>
        _(attributeList).star()
            .reduce(this, (location, nodes) 
            {
                final attributes = nodes.takeAllAs<AttributeSyntax>();
                return attributes.isEmpty
                    ? AttributesSyntax.none
                    : AttributesSyntax(list: attributes, location: location);
            });

    Parser attributeList() =>
        (token(_syntax.attributeOpenToken) &
         _(attribute) & (token(",") & _(attribute).error(this, "Trailing comma not allowed")).star() &
         token(_syntax.attributeCloseToken).error(this))
            .reduce(this, (location, nodes) 
            {
                nodes.token();
                final attributes = nodes.filterRestAs<AttributeSyntax>();
                return attributes;
            });

    Parser attribute() =>
        ((_(ident) & token(":").error(this)).optional() & _(qualIdent).error(this, "Missing identifier") &
         (token("(") &
          _(attributeArgs).optional() &
          token(")").error(this)).optional()).optional()
            .reduce(this, (location, nodes) 
            {
                IdentifierSyntax? category = nodes.takeAs<IdentifierSyntax>();
                nodes.tokenOpt();
                var name = nodes.takeIf<IdentifierSyntax>();
                if (name == null)
                {
                    name = category;
                    category = null;
                }

                nodes.tokenOpt();
                final args = nodes.takeIf<AttributeArgsSyntax>();
                
                return AttributeSyntax(                    
                    name: name,
                    category: category,
                    args: args,
                    location: location);
            });

    // Parser attribute() =>
    //     _(_attribute);
        
    Parser attributeArgs() =>
        (_(attributeArg) &
        (token(",") & _(attributeArg).error(this, "Trailing comma not allowed")).star())
            .reduce(this, (location, nodes) 
            {
                final args = nodes.filterRestAs<AttributeArgSyntax>();

                return AttributeArgsSyntax(list: args, location: location);
            });
    
    Parser attributeArg() =>
        ((_(ident) &
            token("=") & _(anyLiteral).error(this, "Literal value expected")) | _(anyLiteral))
            .reduce(this, (location, nodes) 
            {
                if (nodes.done)
                {
                    return null;
                }

                if (nodes.count == 1)
                {
                    var name = nodes.takeIf<IdentifierSyntax>() ?? IdentifierSyntax.unnamed;
                    var value = nodes.takeIf<LiteralSyntax>();
                    return AttributeArgSyntax(
                        location: location,
                        name: name,
                        value: value);
                }

                final argName = nodes.takeAs<IdentifierSyntax>();
                nodes.token();
                final argValue = nodes.takeAs<LiteralSyntax>();

                return AttributeArgSyntax(
                    location: location,
                    name: argName,
                    value: argValue);
            })
        ;

    Parser struct() =>
        (_(attributes).optional() &
         keyword(_syntax.structKeyword) &
         _(ident).error(this, "Missing identifier") &
         primaryBaseType(BaseKind.struct).optional() &
         openScope() &
         _(fields) &
         closeScope())
            .reduce(this, (location, nodes) 
            {
                final attrs = nodes.takeIf<AttributesSyntax>();  
                final keyword = nodes.keyword();              
                final name = nodes.takeAs<IdentifierSyntax>();
                final base = nodes.takeIf<BaseTypeSyntax>();
                final open = nodes.token();
                final fields = nodes.takeAs<FieldsSyntax>();
                final close = nodes.token();

                return StructSyntax(
                    name: name,
                    fields: fields,                    
                    base: base,
                    keyword: keyword,
                    openScopeToken: open,
                    closeScopeToken: close,
                    location: location,
                    attachedComments: _popCommentScope(), 
                    attributes: attrs);
            });

    Parser _<T>(Parser<T> Function() function) =>
        ReferenceParser<T>(function, const []);

    Parser fields() =>
        (_(field).star())
            .reduce(this, (location, nodes) 
            {
                return FieldsSyntax(list: nodes.takeAllAs<FieldSyntax>());                
            });

    Parser field() =>
        (_(attributes).optional() & _(typeReference) & _(ident).error(this, "Missing identifier") &
         _(initExpressionOpt) & semicolon())
            .reduce(this, (location, nodes)
            {
                final attrs = nodes.takeIf<AttributesSyntax>();
                final type = nodes.takeAs<TypeReferenceSyntax>();
                final name = nodes.takeAs<IdentifierSyntax>();
                final defaultValue = nodes.takeIf<AssignmentExpressionSyntax>();
                final semi = nodes.token();

                return FieldSyntax(
                    name: name,
                    type: type,
                    initializer: defaultValue,
                    semicolon: semi,
                    location: location,
                    attachedComments: attachedComments,
                    attributes: attrs);
            });

    // Parser xinheritsOpt() => 
    //     (token(_syntax.baseSeparatorKeyword) & _(qualIdent)).optional()
    //         .reduce(source, (location, nodes) 
    //         {
    //             if (nodes == null)
    //             {
    //                 return null;
    //             }

    //             final separator = nodes.keyword();
    //             final ident = nodes.takeAs<IdentifierSyntax>();
    //             return PrimaryBaseTypeSyntax(
    //                     location: ident.location,
    //                     keyword: separator,
    //                     name: ident);
    //         });

    Parser typeReference() => _typeReference<TypeReferenceSyntax>(CreateTypeReference);

    Parser _typeReference<TReference extends TypeReferenceSyntax>(ReferenceCreator creator) 
    {
        final list = 
            (keyword(_syntax.listKeyword) &
            token('<').error(this) &
            _(typeReference).error(this, "Missing type") &
            token('>').error(this))
                .reduce(this, (location, nodes) 
                {                    
                    final listtok = nodes.keyword();
                    final leftAngle = nodes.token();
                    final arg = nodes.takeAs<TypeReferenceSyntax>();
                    final rightAngle = nodes.token();
                    return creator(                        
                        location: location,
                        keyword: listtok,
                        builtinKind: TypeKind.list,
                        name: IdentifierSyntax(nameToken: listtok.toToken(), location: listtok.location), 
                        typeParameters: [leftAngle, rightAngle, arg]);
                });

        final map =
            (keyword(_syntax.mapKeyword) &
            token('<').error(this) &
            _(typeReference).error(this, "Missing type") &
            token(',').error(this) &
            _(typeReference).error(this, "Missing type") &
            token('>').error(this))                
                .reduce(this, (location, nodes) 
                {
                    final maptok = nodes.keyword();
                    final leftAngle = nodes.token();
                    final keyArg = nodes.takeAs<TypeReferenceSyntax>();
                    final rightAngle = nodes.token();
                    final valueArg = nodes.takeAs<TypeReferenceSyntax>();

                    return creator(
                        location: location,
                        keyword: maptok,
                        builtinKind: TypeKind.map, 
                        name: IdentifierSyntax(nameToken: maptok.toToken(), location: maptok.location), 
                        typeParameters: [leftAngle, rightAngle, keyArg, valueArg]);
                });

        final qualifiedType = _(qualIdent).reduce(this, (location, nodes) 
        {
            final name = nodes.takeAs<IdentifierSyntax>();
            final keyword = KeywordSyntax(keyword: name.fullName, location: name.location);

            return creator(
                location: location,
                keyword: keyword, 
                name: name);
        });

        final types = 
            _(primitiveType) |
             list |
             map |
             qualifiedType;

        return (types & _(nullableOpt))
            .reduce(this, (location, value) 
            {
                final type = value.takeAs<TReference>();
                type.nullable = value.takeAs<bool>();
                if (type.nullable)
                {
                    //update the location to include the '?'
                    type.location = location;
                }
                return type;
            });
    }
    
    Parser primitiveType() =>
        (_(realType) |
        _(integerType) |
        _(boolType) |
        _(stringType))
            .forward(this);

    Parser boolType() =>
        keyword(_syntax.booleanKeyword).reduceKeyword(this, (result) => _makeTypeRefKeyword(result!, TypeKind.boolean));

    Parser voidType() =>
        keyword(_syntax.voidKeyword).reduceKeyword(this, (result) => _makeTypeRefKeyword(result!, TypeKind.$void));

    Parser integerType() =>
        (keyword(_syntax.int8Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.int8)) |
        keyword(_syntax.uint8Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.uint8)) |
        keyword(_syntax.int16Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.int16)) |
        keyword(_syntax.uint16Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.uint16)) |
        keyword(_syntax.int32Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.int32)) |
        keyword(_syntax.uint32Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.uint32 )) |
        keyword(_syntax.int64Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.int64)) |
        keyword(_syntax.uint64Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.uint64)))
            .forward(this);

    Parser realType() =>
        (keyword(_syntax.float32Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.float32)) | 
        keyword(_syntax.float64Keyword).reduceKeyword(this, (value) => _makeTypeRefKeyword(value!, TypeKind.float64)))
            .forward(this);

    Parser stringType() =>
        keyword(_syntax.stringKeyword).reduceKeyword(this, (result) 
            => _makeTypeRefKeyword(result!, TypeKind.string));

    TypeReferenceSyntax _makeTypeRefKeyword(KeywordSyntax typeName, TypeKind kind) 
    {
        final loc = typeName.location;
        return TypeReferenceSyntax(
            builtinKind: kind,
            keyword: typeName, 
            name: IdentifierSyntax(nameToken: typeName.toToken(), location: loc), location: loc);
    }
    
    Parser nullableOpt() => token('?').optional()
        .reduce(this, (location, nodes) 
        {
            final value = nodes.tokenOpt();
            if (value != null)
            {
                return value.token == '?' ? true : false;
            }

            return false;
        });

    Parser token(String value, [String? message]) =>
        ref2(_token, value, message, "'$value'");

    Parser _tokenOpt(String value, [String? message]) =>
        token(value, message).optional();

    Parser tokenOpt(String value, [String? message]) =>
        ref2(_tokenOpt, value, message);

    Parser ws() => whitespace().plus().flatten();//.located(this);

    Parser wsOrComment() => _(ws) | _(comments);

    Parser _token(Object input, [String? message])
    {
        if (input is Parser<String>)
        {
            final s = TokenParser<String>(input);
            return s.trim(wsOrComment()).asToken(this);
        }
        else if (input is Parser)
        {
            return input.token().trim(wsOrComment()).asToken(this);
        }
        else if (input is String)
        {
            final s = TokenParser<String>(input.toParser(message: message));
            return s.trim(wsOrComment()).asToken(this);
        }

        throw ArgumentError('unknown token type: $input');
    }

    Parser _namespacePart() 
    {
        Parser part() => 
            (_(_identifier) & token("."))
                .reduce(this, (location, nodes) 
                {
                    final ident = nodes.token();
                    final separator = nodes.token();
        
                    return IdentNamespaceSyntax(
                        namespaceToken: ident,
                        separator: separator,
                        location: location);                    
                });

        return (_(part).plus())
            .reduce(this, (location, nodes) 
            {
                final ns = nodes.takeAs<IdentNamespaceSyntax>();
                var prefix = ns;

                while (!nodes.done)
                {
                    final next = nodes.takeAs<IdentNamespaceSyntax>();
                    prefix.setNext(next);
                    prefix = next;
                }
                return ns;
            });
    }

    Parser qualIdent() => (_(_namespacePart).optional() & _(_identifier))
        .reduce(this, (location, nodes) 
        {
            final ns = nodes.takeIf<IdentNamespaceSyntax>();
            final ident = nodes.token();
            
            final qualident = IdentifierSyntax(
                nameToken: ident,
                namespacePart: ns,
                location: location);
            _tracer?.message("qualident: $qualident", prefix: ">");
            return qualident;
        });

    Parser ident() => _(_identifier)
        .reduce(this, (location, nodes) 
        {
            final name = nodes.token();
            _tracer?.message("ident: $name", prefix: "*");
            return IdentifierSyntax(nameToken: name, location: location);
        });

//    Parser _identPart() => ref2(_token, _(_identifier), 'identifier').flatten();

    Parser _identifier() =>
        (pattern('a-zA-Z_') &
        pattern('0-9a-zA-Z_').star()).flatten().asToken(this).trim(wsOrComment());

    Parser literalOrNull() =>
        (_(nullLiteral) | _(literal))
            .reduce(this, (location, nodes) 
            {
                return nodes.current;
            });

    Parser anyLiteral() =>
        (_(nullLiteral) |
         _(literal) |
         _(qualIdentLiteral))
            .reduce(this, (location, nodes)
            {
                final lit = nodes.takeAs<LiteralSyntax>();
                return lit;
            });

    Parser qualIdentLiteral() =>
        _(qualIdent)
            .reduce(this, (location, list)
            {
                final ident = list.takeAs<IdentifierSyntax>();
                return LiteralSyntax.ident(ident, location);
            });

    Parser literal() =>    
        (_(booleanLiteral) |
         _(stringLiteral) |
         _(literalNumber))
            .forward(this);

    Parser nullLiteral() =>
        keyword(_syntax.nullKeyword)
            .reduce(this, (location, nodes) 
            {
                final keyword = nodes.keyword();
                return LiteralSyntax.nil(null, keyword, location);
            });

    Parser booleanLiteral() => (keyword(_syntax.trueKeyword) | keyword(_syntax.falseKeyword))
        .reduceKeyword(this, (value) 
        {
            final loc = value!.location;
            return LiteralSyntax.boolean(value.keyword == _syntax.trueKeyword, value, loc);
        });

    Parser stringPart() =>
        (pattern('^${_syntax.stringDelimiterToken}').star()).flatten()
            .reduce(this, (location, nodes) 
            {
                final value = nodes.string();

                return TokenSyntax(token: value, location: location);
            });

    Parser stringLiteral() => 
        (token(_syntax.stringDelimiterToken) & _(stringPart) & token(_syntax.stringDelimiterToken).error(this))
            .reduce(this, (location, nodes) 
            {
                final start = nodes.token();
                final string = nodes.token();
                final end = nodes.token();

                final value = StringSyntax(value: string, startDelim: start, endDelim: end, location: location);
                return LiteralSyntax.string(value, location);
            });

    Parser literalNumber() 
    {
        final numberTypes =
            hexIntLiteral() | 
            binaryIntLiteral() |
            octalIntLiteral() | 
            realLiteral() |
            decimalIntLiteral();

        return numberTypes.reduce(this, (location, nodes) 
        {
            final lit = nodes.takeAs<LiteralSyntax>();

            if (lit.kind == LiteralKindSyntax.error)
            {
                return lit;
            }
            return lit;
        });
    }
    
    Parser scale(NumberScale scale) => 
        _(() => char(scale.n)
            .reduce(this, (location, value) => NumberScaleSyntax(value: scale, location: location)));

    Parser intScale() =>
        (scale(NumberScale.kilo2) |
        scale(NumberScale.kilo10) |
        scale(NumberScale.mega2) |
        scale(NumberScale.mega10) |
        scale(NumberScale.giga2) |
        scale(NumberScale.giga10) |
        scale(NumberScale.tera2) |
        scale(NumberScale.tera10) |
        scale(NumberScale.peta2) |
        scale(NumberScale.peta10) |
        scale(NumberScale.exa2) |
        scale(NumberScale.exa10) |
        scale(NumberScale.zetta2) |
        scale(NumberScale.zetta10) |
        scale(NumberScale.yotta2) |
        scale(NumberScale.yotta10)).optional()
            .reduce(this, ((location, nodes) 
            {
                if (nodes.done)
                {
                    return NumberScaleSyntax.none(location: location);
                }
                return nodes.takeAs<NumberScaleSyntax>();
            }));

    Parser decimal() => (digit() & (digit() | char(_syntax.digitSeparatorToken)).star()).flatten().asToken(this);
    
    Parser decimalIntLiteral() => intParser(decimal);

    Parser zeroOne() =>
        char("0") | char("1");

    Parser binary() => (_(zeroOne) & (_(zeroOne) | char(_syntax.digitSeparatorToken)).star()).flatten().asToken(this);

    Parser binaryIntLiteral() => intParser(binary, "0b", IntRadix.binary);

    Parser hex() => (pattern('0-9a-fA-F') & (pattern('0-9a-fA-F') | char(_syntax.digitSeparatorToken)).star()).flatten().asToken(this);

    Parser hexIntLiteral() => intParser(hex, "0x", IntRadix.hex);

    Parser octal() => 
        (pattern('0-7') & (pattern('0-7') | char(_syntax.digitSeparatorToken)).star()).flatten().asToken(this);

    Parser octalIntLiteral() => intParser(octal, "0o", IntRadix.octal);

    Parser intParser(Parser Function() digitParser, [String? radixPrefix, IntRadix? radixValue])
    {
        Parser radix(String prefix, IntRadix type) =>
            _(() => string(prefix)
                .reduce(this, (location, nodes) 
                {
                    return RadixSyntax(token: nodes.string(), radix: type, location: location);
                }));

        Parser parser;
        if (radixPrefix != null)
        {
            parser = (radix(radixPrefix, radixValue!) & _(digitParser).error(this, "Ill-formed literal value")) & _(intScale);
        }
        else
        {
            parser = _(digitParser) & _(intScale);
        }

        parser = parser.reduce(this, (location, nodes) 
        {
            final radix = nodes.takeIf<RadixSyntax>() ?? RadixSyntax.none();
            final value = nodes.token();
            final scale = nodes.takeAs<NumberScaleSyntax>();

            return _makeIntLiteral(value, radix, scale, location);
        });
        return parser;
    }

    LiteralSyntax _makeIntLiteral(TokenSyntax value, RadixSyntax radix, NumberScaleSyntax scale, SourceLocation location, [String? valueOverride])
    {
        try 
        {
            final groups = (valueOverride ?? value.token).split(_syntax.digitSeparatorToken);
            int separatorSpacing = 0;
            if (groups.length > 1)
            {
                final spacings = <int>{};

                groups.skip(1).forEach((group) { spacings.add(group.length); });
                if (spacings.length > 1)
                {
                    return LiteralSyntax.error("Ill formed numeric literal (separator spacing)", LiteralKindSyntax.int, location);
                }

                separatorSpacing = spacings.isEmpty
                    ? 0
                    : spacings.first;
                valueOverride = groups.join("");
            }

            return LiteralSyntax.int(
                    BigInt.parse(valueOverride ?? value.token, radix: radix.radix.base),
                    value,
                    radix,
                    scale,
                    separatorSpacing,
                    location);            
        } 
        on FormatException catch(e) 
        {
            return LiteralSyntax.error(e.message, LiteralKindSyntax.int, location);
        }
    }

    Parser realLiteral() 
    {
        // [0-9]+\.[0-9]*|[0-9]*\.[0-9]+
        final group0 = (digit().plus() & char('.') & digit().star()) |
            (digit().star() & char('.') & digit().plus());

        // [Ee][+-]?[0-9]+
        final group1 = pattern('Ee') & pattern('+-').optional() & digit().plus();

        // [0-9]+[Ee][+-]?[0-9]+
        final group2 = digit().plus() &
            pattern('Ee') &
            pattern('+-').optional() &
            digit().plus();

        // ((group0)(group1)?|group2)
        return (group0 & group1.optional() | group2).asToken(this)
            .reduce(this, (location, nodes)
            {
                final token = nodes.token();
                try 
                {
                    return LiteralSyntax.real(double.parse(token.token), token, token.location);
                } 
                on FormatException catch(e) 
                {
                    return LiteralSyntax.error(e.message, LiteralKindSyntax.real, token.location);
                }            
            });
    }
   
    Parser trivia() => _(_triviaRest).plus().flatten();//.located(this);

    Parser _triviaRest() =>
        (whitespace() | 
        _(_singleLineCommentOpt) | 
        _(_multiLineComment));

    Parser _singleLineCommentOpt() =>
        (string('//') & _(_newLine).neg().star() & _(_newLine).optional()).flatten();

    Parser _multiLineComment() =>
        (string('/*') &
        (_(_multiLineComment) | string('*/').neg()).star() &
        string('*/')).flatten();

    Parser _newLine() => pattern('\n\r');

    Parser _wholeWord(
        Parser Function(Object, String?) callback,
        String value,
    ) => ref2(callback, value.toParser() & word().not(), value);
}
