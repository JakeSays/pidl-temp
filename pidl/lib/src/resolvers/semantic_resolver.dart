import 'package:pidl/src/type_visitor.dart';

import '../types.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../diagnostics.dart';
import 'topological_sort.dart';
import 'builtin_types.dart';
import 'type_builder.dart';
import '../source.dart';
import 'extensions.dart';
import '../compile_result.dart';
import 'completeness_checker.dart';

class SemanticResolver
{
    final _NamespaceRenamer _namespaceRenamer = _NamespaceRenamer();
    final _FileAttributeExtractor _fileAttributeExtractor;
    final TypeBuilder _typeBuilder;
    late final TypeScope _builtinScope;
    final Diagnostics _diagnostics;    

    SemanticResolver(this._diagnostics)
        : _typeBuilder = TypeBuilder(diagnostics: _diagnostics),
          _fileAttributeExtractor = _FileAttributeExtractor(diagnostics: _diagnostics)
    {
        final unit = CompilationUnit.empty(SourceFile.builtins, SourceLocation.unknown, []);

        _builtinScope = TypeScope(unit: unit, diagnostics: _diagnostics);
        for(final builtin in builtinTypes)
        {
            _builtinScope.addDefinedItem(builtin);
        }
    }
          
    CompileResult go(List<CompilationUnitSyntax> compilations, String mainFilePath)
    {
        compilations = _orderByDependenies(compilations);

        CompilationUnit? mainCu;

        List<CompilationUnit> dependencyOrder = [];

        for(final cu in compilations)
        {
            final unit = CompilationUnit(ident: cu.name.definition(), source: cu.source);
            dependencyOrder.add(unit);

            if (mainCu == null && cu.source.path == mainFilePath)
            {
                mainCu = unit;
            }
            cu.fileScope = TypeScope(unit: unit, diagnostics: _diagnostics, builtins: _builtinScope);

            _namespaceRenamer.visit(cu);
        }

        for(final cu in compilations)
        {
            _typeBuilder.go(cu);
        }

        _fileAttributeExtractor.go(dependencyOrder);

        final incompletes = CompletenessChecker.check(dependencyOrder);

        final result = CompileResult(mainFile: mainCu!, unitsInDependencyOrder: dependencyOrder, incompleteDefinitions: incompletes);
        return result;
    }

    List<CompilationUnitSyntax> _orderByDependenies(List<CompilationUnitSyntax> compilations)
    {
        Iterable<CompilationUnitSyntax> dependencies(CompilationUnitSyntax cu) sync*
        {
            for(final imp in cu.imports)
            {
                yield imp.unit!;
            }
        }

        try 
        {
            final ordered = topologicalSort(compilations, dependencies).reversed.toList();
            return ordered;          
        } 
        on CycleException<CompilationUnitSyntax> catch (e) 
        {
            final message = StringBuffer();
            message.writeln(e.cycle.length > 2
                ? "Circular dependencies exist between the following files: "
                : "A circular dependency exist between the following files: ");

            for (final cu in e.cycle)
            {
                message.writeln("    ${cu.source.path}");
            }

            throw SemanticIssue(
                code: IssueCode.circularDependency,
                severity: IssueSeverity.error,
                message: message.toString());
        }
    }
}

class _NamespaceRenamer extends AstVisitor
{
    @override
    void visitNamespace(NamespaceSyntax node) 
    {        
        if (node.declaringNode is NamespaceSyntax)
        {
            node.name.updateNamespace((node.declaringNode as NamespaceSyntax).name);
        }

        super.visitNamespace(node);
    }

    @override
    void visitConstant(ConstantSyntax node) 
    {
        if (node.declaringNode is NamespaceSyntax)
        {
            node.name.updateNamespace((node.declaringNode as NamespaceSyntax).name);
        }
    }

    @override
    bool visitTypeDefinition(TypeDefinitionSyntax node) 
    {
        if (node.declaringNode is NamespaceSyntax)
        {
            node.name.updateNamespace((node.declaringNode as NamespaceSyntax).name);
        }

        return true;
    }
}

class _FileAttributeExtractor extends TypeVisitor
{
    late CompilationUnit unit;
    final Diagnostics diagnostics;

    _FileAttributeExtractor({required this.diagnostics});

    void go(List<CompilationUnit> units)
    {
        for(final unit in units)
        {
            this.unit = unit;
            visit(unit);
        }        
    }

    @override
    void visitAttribute(Attribute node)
    {
        if (node.category == null ||
            node.category!.fullName != "file" ||
            node.declaringNode is CompilationUnit)
        {
            return;
        }

        if (node.declaringNode?.declaringNode is! CompilationUnit)
        {
            diagnostics.addIssue(
                SemanticIssue(
                    code: IssueCode.invalidFileAttribute, 
                    severity: IssueSeverity.error,
                    target: node)
            );
            return;
        }

        node.reparent(unit);
        unit.attributes.add(node);
    }
}