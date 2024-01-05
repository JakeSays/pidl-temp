import '../diagnostics.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../util.dart';
import '../types.dart';
import "extensions.dart";
import 'attribute_builder.dart';
import 'initializer_resolver.dart';

class _ConstType
{
    TypeDefinition defn;
    Import? import;

    _ConstType({
        required this.defn,
        this.import});
}

class ConstantBuilder extends AstVisitor
{
    final Diagnostics diagnostics;

    ConstantBuilder({required this.diagnostics});

    late TypeScope _scope;
    InitializerResolver? _initResolver;
    InitializerResolver get resolver => _initResolver ?? InitializerResolver(diagnostics: diagnostics, scope: _scope);

    void build(TypeScope scope, ConstantSyntax node)
    {
        _scope = scope;
        _initResolver = null;

        visitConstant(node);
    }

    @override
    void visitConstant(ConstantSyntax node) 
    {
        final type = _getType(node);

        final typeRef = TypeReference(
            target: type.defn,
            import: type.import, 
            location: node.type.location, 
            nullable: node.type.nullable);

        final initResult = resolver.build(node, typeRef, node.type);
        if (initResult == null)
        {
            return;
        }

        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);

        final constant = Constant(
            ident: node.name.definition(),
            type: typeRef,
            computedValue: initResult.computedValue,
            value: initResult.literal,
            initializer: initResult.expression, 
            valueKind: type.defn.declKind,
            attributes: attrs);

        _scope.addDefinedItem(constant);
    }

    _ConstType _getType(ConstantSyntax node)
    {
        var types = _scope.findVisible(node.type.name.fullName);
        if (types == null)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidType,
                severity: IssueSeverity.error,
                message: "Unknown type for constant", 
                related: [node], 
                target: node.type));
            return _ConstType(defn: TypeDefinition.error(node.type.name.definition(), node.type.location));
        }

        if (types.length > 1)
        {
            createAmbiguousTypesIssue(diagnostics, node.type, types);
            return _ConstType(defn: TypeDefinition.error(node.type.name.definition(), node.type.location));
        }

        final type = types.first;

        if (type.definition is! TypeDefinition ||
            !(type.definition as TypeDefinition).declKind.isconstant)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidType,
                severity: IssueSeverity.error,
                message: "Unexpected type for constant", 
                related: [node], 
                target: node.type));
            return _ConstType(defn: TypeDefinition.error(node.type.name.definition(), node.type.location));
        }

        return _ConstType(defn: type.definition as TypeDefinition, import: type.import);
    }
}