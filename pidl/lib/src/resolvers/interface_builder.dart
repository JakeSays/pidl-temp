import '../diagnostics.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../types.dart';
import "extensions.dart";
import 'attribute_builder.dart';
import 'initializer_resolver.dart';

class InterfaceBuilder extends AstVisitor
{
    List<Method> _methods = [];
    List<Parameter> _parameters = [];
    TypeReference? _returnType;
    List<TypeReference> _bases = [];

    late TypeScope _scope;
    InitializerResolver? _initResolver;
    InitializerResolver get resolver => _initResolver ?? InitializerResolver(diagnostics: diagnostics, scope: _scope);

    Diagnostics diagnostics;

    InterfaceBuilder({required this.diagnostics});

    void build(TypeScope scope, InterfaceSyntax node)
    {
        _initResolver = null;
        _scope = scope;

        visitInterface(node);

        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);

        final name = node.name.definition();
        final result = Interface(ident: name,
            bases: _bases,
            methods: _methods,
            location: node.location,
            attributes: attrs);

        _scope.addDefinedItem(result);

        _methods = [];
        _bases = [];
    }

    @override
    void visitBaseInterface(BaseTypeSyntax node) 
    {
        DefinitionState? state;
        final result = _scope.lookupType(node);
        if (result.status != LookupStatus.found)
        {
            state = DefinitionState.error;
            _returnType = TypeReference.unknown(node.location);
            return;
        }

        final type = result.as!;

        if (type is! Interface)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidBaseType,
                severity: IssueSeverity.error,
                related: [node.declaringNode!], 
                target: node));
            return;
        }

        if (_bases.any((ref) => ref.name == type.ident))
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.duplicateBaseTypes,
                severity: IssueSeverity.error,
                related: [node.declaringNode!], 
                target: node));
            return;
        }

        _bases.add(TypeReference(
            target: type, 
            import: result.import,
            nullable: node.nullable,
            state: state, 
            location: node.location));
    }

    @override
    void visitMethod(MethodSyntax node) 
    {
        _returnType = null;
        DefinitionState? state;

        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);

        super.visitMethod(node);

        final name = node.name.definition();
        final existing = _methods.where((e) => e.ident.fullName == name.fullName)
            .toList();

        if (existing.isNotEmpty)
        {
            state = DefinitionState.error;
            _duplicateError(IssueCode.duplicateMethods, node, existing);
        }

        final method = Method(
            ident: name, 
            returnType: _returnType!, 
            parameters: _parameters,
            state: state,
            attributes: attrs);
        
        _methods.add(method);
        _parameters = [];
    }

    bool _errorIfInterface(NamedDefinition type, NamedSyntax target, IssueCode code)
    {
        if (type is! Interface)
        {
            return false;
        }

        diagnostics.addIssue(SemanticIssue(
            code: code,
            severity: IssueSeverity.error,
            related: [target.declaringNode!], 
            target: target));
        
        return true;
    }

    @override
    void visitMethodReturnType(TypeReferenceSyntax node) 
    {
        DefinitionState? state;
        final result = _scope.lookupType(node);
        if (result.status != LookupStatus.found)
        {
            state = DefinitionState.error;
            _returnType = TypeReference.unknown(node.location);
            return;
        }
        
        if (_errorIfInterface(result.as!, node, IssueCode.invalidReturnType))
        {
            state = DefinitionState.error;
        }

        _returnType = TypeReference(
            target: result.as!, 
            import: result.import,
            nullable: node.nullable,
            state: state, 
            location: node.location);
    }

    @override
    void visitParameter(ParameterSyntax node) 
    {        
        DefinitionState? state;

        final name = node.name.definition();
        final existing = _parameters.where((e) => e.ident.fullName == name.fullName)
            .toList();
        
        if (existing.isNotEmpty)
        {
            state = DefinitionState.error;
            _duplicateError(IssueCode.duplicateParameters, node, existing);
        }

        TypeReference paramType;
        final result = _scope.lookupType(node.type, null, LookupStatus.error);
        if (result.status == LookupStatus.error)
        {
            paramType = TypeReference.unknown(node.type.location);
            state = DefinitionState.error;
        }
        else
        {
            if (_errorIfInterface(result.value!.definition, node, IssueCode.invalidParameterType))            
            {
                state = DefinitionState.error;
            }
            paramType = TypeReference(
                target: result.as!, 
                import: result.import,
                nullable: node.type.nullable, 
                location: node.type.location);
        }

        final initResult = resolver.build(node, paramType, node.type);

        final attrs = AttributeBuilder.buildAttributes(_scope, diagnostics, node);

        final param = Parameter(
            ident: name, 
            type: paramType,
            initializer: initResult?.expression,
            computedValue: initResult?.computedValue ?? ExprValue.none(),
            defaultValue: initResult?.literal,
            location: node.location,
            attributes: attrs);
        param.state = state ?? param.state;

        _parameters.add(param);
    }

    void _duplicateError(IssueCode code, NamedSyntax targetNode, List<Definition> duplicates)
    {
            final sb = StringBuffer();
            for(final item in duplicates)
            {
                sb.writeln("  at ${item.location!.description}");
            }

            diagnostics.addIssue(SemanticIssue(
                code: code,
                severity: IssueSeverity.error,
                details: sb.toString(),
                related: [targetNode], 
                target: targetNode.name));
    }
}
