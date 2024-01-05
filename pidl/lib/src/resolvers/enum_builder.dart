import 'package:pidl/src/source.dart';

import '../diagnostics.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../util.dart';
import '../types.dart';
import "extensions.dart";
import 'attribute_builder.dart';
import 'initializer_resolver.dart';
import 'package:darq/darq.dart';

class EnumBuilder extends AstVisitor
{
    BigInt _nextValue = BigInt.zero;
    bool _errorEncountered = false;
    final Set<String> _seenEnumerants = {};
    final Set<BigInt> _seenValues = {};
    late BuiltinTypeDefinition _enumDataType;    
    late TypeReferenceSyntax _enumDataTypeReference;
    Enum? _current;

    late TypeScope _scope;
    InitializerResolver? _initResolver;
    InitializerResolver get resolver => _initResolver ?? InitializerResolver(diagnostics: diagnostics, scope: _scope);

    List<Enum> enums = [];

    Diagnostics diagnostics;

    EnumBuilder({required this.diagnostics});

    void build(TypeScope scope, EnumSyntax node)
    {
        _initResolver = null;
        _scope = scope;
        
        enums.clear();

        visitEnum(node);
    }

    @override
    void visitEnum(EnumSyntax node)     
    {   
        _nextValue = BigInt.zero;
        _errorEncountered = false;
        _seenEnumerants.clear();
        _seenValues.clear();
        _current = null;

        _enumDataTypeReference = node.type;

        _enumDataType = _scope.lookupBuiltin(node.dataType.name) ??
            _scope.lookupBuiltin("int32")!;           

        if (!node.dataType.isint)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidType,
                severity: IssueSeverity.error,
                message: "Enum data type must be an integer.", 
                related: [node], 
                target: node.name));
            return;
        }

        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);
        _current = Enum(
            ident: node.name.definition(), 
            dataType: _enumDataType.reference(), 
            enumerants: [],
            location: node.location,
            attributes: attrs);

        super.visitEnum(node);

        if (_errorEncountered)
        {
            return;
        }

        enums.add(_current!);
        _scope.addDefinedItem(_current!);
    }

    InitializerValue? _resolveNodeValue(EnumerantSyntax node)
    {
        if (node.initializer.value.isEmpty)
        {
            return null;
        }

        final initResult = resolver.build(node, 
            _enumDataType.reference(), _enumDataTypeReference,
            ((ident) => _current!.enumerants.where((e) => e.ident.fullName == ident.fullName).firstOrDefault()));

        if (initResult == null ||
            !initResult.computedValue.hasvalue)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.note,
                severity: IssueSeverity.warning,
                message: "Invalid enumerant initializer. Using default value",
                related: [node], 
                target: node.initializer));
            return null;
        }
        
        return initResult;
    }

    @override
    void visitEnumerant(EnumerantSyntax node) 
    {
        if (!_seenEnumerants.add(node.name.fullName))
        {
            _errorEncountered = true;
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.duplicateName,
                severity: IssueSeverity.error,
                message: "Enumerant names must be unique", 
                related: [node], 
                target: node.name));
        }

        final constValue = _resolveNodeValue(node);

        BigInt value;
        
        BigInt nextAvailableValue()
        {
            var next = _nextValue;
            while (_seenValues.contains(next))
            {
                next += BigInt.one;
            }

            return next;
        }

        if (constValue?.computedValue.hasvalue ?? false) 
        {
            value = constValue!.computedValue.intValue;
        }
        else
        {
            if (_errorEncountered)
            {
                return;
            }
            value = nextAvailableValue();
        }
        
        final nextValue = value + BigInt.one;

        if (!intWithinRangeForType(node.declarer.dataType, value))
        {
            _errorEncountered = true;
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.outOfBounds,
                severity: IssueSeverity.error,
                message: "Value $value is out of bounds for declared enum", 
                related: [node], 
                target: node.initializer.isNotEmpty ? node.initializer : node));
            return;
        }

        //only update _nextvalue if it is in range of the enum type
        _nextValue = nextValue;

        if (!_errorEncountered &&
            !_seenValues.add(value))
        {
            _errorEncountered = true;
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.duplicateValue,
                severity: IssueSeverity.error,
                message: "Enumerant values must be unique", 
                related: [node], 
                target: node.initializer.isNotEmpty ? node.initializer : node));
        }

        if (!_errorEncountered)
        {
            final lit = constValue?.literal ?? _makeLiteral(node.location, value);
            final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);
            final newEnumerant = Enumerant(
                ident: node.name.definition(), 
                value: lit,
                initializer: constValue?.expression,
                computedValue: constValue?.computedValue ?? ExprValue.int(lit.asNumber.asint, lit.asNumber.kind),
                location: node.location,
                attributes: attrs);

            _current!.enumerants.add(newEnumerant);
            _current!.enclose(newEnumerant);
        }
    }

    Literal _makeLiteral(SourceLocation? loc, BigInt value)
    {
        final radix = IntRadix.decimal;

        final typeRef = TypeReference(target: _enumDataType, location: loc);
        final number = Number(
            value: value, 
            kind: _enumDataType.numberKind, 
            radix: radix, 
            scale: NumberScale.none, 
            type: typeRef);

        return Literal.number(number, typeRef, loc);
    }
}
