import '../types.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../diagnostics.dart';
import 'builder_util.dart';
import 'enum_builder.dart';
import 'constant_builder.dart';
import 'interface_builder.dart';
import 'struct_builder.dart';
import 'extensions.dart';
import '../type_visitor.dart';
import '../version_calculator.dart';

class TypeBuilder extends AstVisitor
{
    late TypeScope _scope;

    Diagnostics diagnostics;
    final EnumBuilder _enumBuilder;
    final ConstantBuilder _constantBuilder;
    final InterfaceBuilder _interfaceBuilder;
    final StructBuilder _structBuilder;

    TypeBuilder({required this.diagnostics})
        : _enumBuilder = EnumBuilder(diagnostics: diagnostics),
          _constantBuilder = ConstantBuilder(diagnostics: diagnostics),
          _interfaceBuilder = InterfaceBuilder(diagnostics: diagnostics),
          _structBuilder = StructBuilder(diagnostics: diagnostics);

    void go(CompilationUnitSyntax unitSyntax)
    {
        _scope = unitSyntax.fileScope;

        for (final import in unitSyntax.imports)
        {
            final scope = import.unit!.fileScope;
            final importDefn = Import(
                path: import.path,
                importedUnit: scope.unit, 
                prefix: import.scope?.definition(), 
                location: import.location,
                state: DefinitionState.complete);
            _scope.unit.addImport(importDefn);
            _scope.addImportedScope(scope, importDefn);
        }

        final definitions = getDefinitionsInDependencyOrder(unitSyntax, diagnostics);        
        if (diagnostics.hasErrors)
        {
            return;
        }
        
        for (final defn in definitions)
        {
            visit(defn.definition);
        }

        final aliasResolver = _AliasResolver();

        aliasResolver.visit(_scope.unit);

        _scope.unit.version = VersionCalculator(cu: _scope.unit).version;        
    }

    @override
    void visitNamespace(NamespaceSyntax node) 
    {
        final ns = Namespace.empty(
            name: node.name.definition(), 
            location: node.location);
        _scope.unit.addMember(ns);
        _scope.pushContainer(ns);

        super.visitNamespace(node);

        _scope.popContainer();
    }

    @override
    void visitEnum(EnumSyntax node) 
    {
        _enumBuilder.build(_scope, node);
    }

    @override
    void visitConstant(ConstantSyntax node) 
    {
        _constantBuilder.build(_scope, node);
    }

    @override
    void visitInterface(InterfaceSyntax node) 
    {
        _interfaceBuilder.build(_scope, node);
    }

    @override
    void visitStruct(StructSyntax node) 
    {
        _structBuilder.build(_scope, node);
    }

    @override
    void visitTypeAlias(TypeAliasSyntax node) 
    {
        final type = _scope.lookupNamedDefinition(node.aliasedType);
        Reference target;
        if (type.status == LookupStatus.error)
        {
            target = UnknownReference(location: node.aliasedType.location);
        }
        else if (type.as is Constant)
        {
            target = ConstantReference(
                target: type.as as Constant, 
                import: type.import,
                location: node.aliasedType.location);
        }
        else
        {
            target = TypeReference(
                target: type.as! as TypeDefinition, 
                import: type.import,
                nullable: node.aliasedType.nullable, 
                location: node.aliasedType.location);
        }
        
        final alias = Alias(ident: node.name.definition(), target: target);
    
        _scope.addDefinedItem(alias);
    }
}

class _AliasResolver extends TypeVisitor
{
    @override
    void visitTypeAlias(Alias node) 
    {
        Definition defn = node.target.referenced;

        while (defn is TypeReference || 
               defn is Alias ||
               defn is Constant)
        {
            if (defn is TypeReference)
            {
                defn = defn.referenced;
                continue;
            }
            else if (defn is Constant)
            {
                break;
            }

            defn = (defn as Alias).target;
        }

        node.resolved = defn;
    }
}