import '../diagnostics.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../types.dart';
import "extensions.dart";
import 'attribute_builder.dart';
import 'initializer_resolver.dart';

class StructBuilder extends AstVisitor
{
    late List<Field> _fields;
    late TypeScope _scope;
    TypeReference? _baseType;

    Diagnostics diagnostics;

    StructBuilder({required this.diagnostics});

    InitializerResolver? _initResolver;
    InitializerResolver get resolver => _initResolver ?? InitializerResolver(diagnostics: diagnostics, scope: _scope);

    void build(TypeScope scope, StructSyntax node)
    {
        _initResolver = null;
        _scope = scope;
        _fields = [];
        _baseType = null;

        visitStruct(node);
    }

    @override
    void visitStruct(StructSyntax node) 
    {
        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);

        super.visitStruct(node);

        final struct = Struct(
            ident: node.name.definition(), 
            fields: _fields,
            base: _baseType,
            location: node.location,
            attributes: attrs);
        _scope.addDefinedItem(struct);
    }

    @override
    void visitField(FieldSyntax node) 
    {        
        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);

        DefinitionState? state;

        final result = _scope.lookupType(node.type, "for field");
        final TypeReference fieldType;
        if (result.status == LookupStatus.error) 
        {
            fieldType = TypeReference.unknown(node.location);
        } 
        else 
        {
            fieldType = TypeReference(
                target: result.as!, 
                import: result.import,
                nullable: node.type.nullable, 
                location: node.type.location);
            if (!fieldType.targetKind.isfield)
            {
                diagnostics.addIssue(SemanticIssue(
                    code: IssueCode.invalidFieldType,
                    severity: IssueSeverity.error,
                    related: [node], 
                    target: node.type));
                state = DefinitionState.error;
            }            
        }

        final initResult = resolver.build(node, fieldType, node.type);

        final field = Field(
            ident: node.name.definition(),
            type: fieldType,
            computedValue: initResult?.computedValue ?? ExprValue.none(),
            initializer: initResult?.expression ?? EmptyExpression.me,
            defaultValue: initResult?.literal,
            location: node.location,
            attributes: attrs);

        field.state = _errorIfDuplicate(field, IssueCode.duplicateFields, node)
            ? DefinitionState.error
            : state ?? DefinitionState.complete;

        _fields.add(field);
    }

    @override
    void visitStructBase(TypeReferenceSyntax node)
    {
        final result = _scope.lookupType(node);
        if (result.status == LookupStatus.error)
        {
            _baseType = TypeReference.unknown(node.location);
            return;
        }

        _baseType = TypeReference(
            target: result.as!, 
            import: result.import,
            nullable: node.nullable, 
            location: node.location);
        if (_baseType!.targetKind != DeclKind.struct)
        {
            _baseType!.state = DefinitionState.error;
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidBaseType,
                severity: IssueSeverity.error,
                related: [node.declaringNode!], 
                target: node));
        }
    }

    bool _errorIfDuplicate(Field field, IssueCode code, NamedSyntax targetNode)
    {
        final existing = _fields.where((e) => e.ident.fullName == field.ident.fullName)
            .toList();
        if (existing.isEmpty)
        {
            return false;
        }

        final sb = StringBuffer();
        for(final item in existing)
        {
            sb.writeln("  at ${item.location!.description}");
        }

        diagnostics.addIssue(SemanticIssue(
            code: code,
            severity: IssueSeverity.error,
            details: sb.toString(),
            related: [targetNode], 
            target: targetNode.name));

        return true;
    }
}
