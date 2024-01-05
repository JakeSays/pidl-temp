import 'package:meta/meta.dart';

import '../diagnostics.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../types.dart';
import '../kinds.dart';
import "extensions.dart";

class AttributeBuilder extends AstVisitor
{
    late Diagnostics diagnostics;

    AttributeBuilder();

    late TypeScope _scope;

    Attribute? _currentAttribute;
    List<Attribute> _attributes = [];

    static final AttributeBuilder _instance = AttributeBuilder();

    static List<Attribute> buildAttributes(TypeScope scope, Diagnostics diagnostics, SyntaxNode node)
    {
        _instance._scope = scope;
        _instance.diagnostics = diagnostics;

        _instance.visit(node);

        final results = _instance._attributes;
        _instance._attributes = [];

        return results;
    }

    @override
    void visitAttributeArg(AttributeArgSyntax node) 
    {    
        final value = _makeAttributeArgValue(node);

        final arg = AttributeArg(
            name: !node.name.isunnamed ? node.name.definition() : null,
            value: value.value);

        _currentAttribute!.addArgument(arg);
    }

    @override
    void visitAttribute(AttributeSyntax node) 
    {
        _currentAttribute = Attribute(
            ident: node.name.definition(),
            category: node.category?.definition(),
            args: [],
            location: node.location);
    
        super.visitAttribute(node);

        _attributes.add(_currentAttribute!);
        _currentAttribute = null;
    }

    LiteralWithStatus _makeAttributeArgValue(AttributeArgSyntax arg)
    {
        final varg = arg.value;

        if (varg == null)
        {
            return LiteralWithStatus.success(null);
        }

        if (varg.status != LiteralParseStatus.success ||
            varg.kind == LiteralKindSyntax.error)
        {
            _scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.illFormedLiteral,
                severity: IssueSeverity.error,
                message: arg.value != null ? arg.value as String : null,
                related: [arg.declaringNode!], 
                target: arg));
            return LiteralWithStatus.error(varg.location);
        }

        if (varg.kind == LiteralKindSyntax.nil)
        {
            final type = _scope.lookupBuiltin("nil")!.reference(location: varg.location);
            return LiteralWithStatus.success(Literal.nil(type, arg.location));
        }

        Object? realValue;
        if (varg.kind != LiteralKindSyntax.identifier)
        {
            LiteralKind litKind;
            TypeDefinition? dataType;
            switch(varg.kind)
            {           
                case LiteralKindSyntax.boolean:
                    litKind = LiteralKind.boolean;
                    dataType = _scope.lookupBuiltin("bool");
                    realValue = varg.value as bool;
                    break;
                case LiteralKindSyntax.int:
                    litKind = LiteralKind.number;
                    dataType = _scope.lookupBuiltin("int64");
                    break;
                case LiteralKindSyntax.real:
                    litKind = LiteralKind.number;
                    dataType = _scope.lookupBuiltin("float64");
                    break;
                case LiteralKindSyntax.string:
                    litKind = LiteralKind.string;
                    dataType = _scope.lookupBuiltin("string");
                    realValue = varg.value as String;
                    break;
                default:
                    throw UnsupportedError("Should never reach here!");
            }

            final dataTypeRef = TypeReference(target: dataType!, location: varg.location);

            if (varg.kind == LiteralKindSyntax.int ||
                varg.kind == LiteralKindSyntax.real)
            {
                realValue = varg.toNumber(dataTypeRef,
                    varg.kind == LiteralKindSyntax.int
                        ? TypeKind.int64
                        : TypeKind.float64);
            }

            return LiteralWithStatus.success(Literal(value: realValue, kind: litKind, dataType: dataTypeRef));
        }

        final ident = varg.value as IdentifierSyntax;

        var result = _scope.lookupByName<NamedDefinition>(ident.fullName, varg, null, LookupStatus.notfound);

        if (result.status == LookupStatus.error)
        {
            return LiteralWithStatus.error(varg.location);
        }

        if (result.status == LookupStatus.found)
        {
            if (result.as is! Constant)
            {
                _scope.diagnostics.addIssue(SemanticIssue(
                    code: IssueCode.invalidAttributeArgValue,
                    severity: IssueSeverity.error,
                    related: [arg], 
                    target: ident));
                return LiteralWithStatus.error(varg.location);
            }

            final constv = result.as as Constant;

            return LiteralWithStatus.success(Literal.constref(constv, result.import, constv.type, varg.location));
        }

        if (ident.namespace == null)
        {
            _scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidAttributeArgValue,
                severity: IssueSeverity.error,
                related: [arg], 
                target: ident));
            return LiteralWithStatus.error(varg.location);
        }

        result = _scope.lookupByName<NamedDefinition>(ident.namespace!, varg, null, LookupStatus.notfound);
        if (result.status == LookupStatus.error)
        {
            return LiteralWithStatus.error(varg.location);
        }

        if (result.status == LookupStatus.notfound ||
            result.as is! Enum)
        {
            _scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidAttributeArgValue,
                severity: IssueSeverity.error,
                related: [arg], 
                target: ident));
            return LiteralWithStatus.error(varg.location);
        }

        final enumType = result.as as Enum;

        final evalue = enumType.findEnumerant(ident.name);
        if (evalue == null)
        {
            _scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidAttributeArgValue,
                severity: IssueSeverity.error,
                related: [arg], 
                target: ident));
            return LiteralWithStatus.error(varg.location);
        }
        
        final enumref = TypeReference(target: enumType, import: result.import, location: varg.location);
        return LiteralWithStatus.success(Literal.enumerantref(evalue, enumref, varg.location));       
    }
}