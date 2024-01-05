import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../graph/directed_sparse_graph.dart';
import '../diagnostics.dart';
import 'package:darq/darq.dart';

class ReferencedDefinition
{
    NamedSyntax definition;
    List<NamedSyntax> references;

    ReferencedDefinition({
        required this.definition,
        required this.references
    });

    @override
    String toString() => definition.toString();
}

List<ReferencedDefinition> getDefinitionsInDependencyOrder(CompilationUnitSyntax cu, Diagnostics diagnostics)
{
    try 
    {
        final collector = _DefinitionCollector();

        collector.go(cu);

        final sd = collector.definitions.TopologicalSort().toList();
        final sortedDefinitions = sd
            .where((e) => e.node is TypeDefinitionSyntax || e.node is ConstantSyntax)
            .map((e) => ReferencedDefinition(
                definition: e.node, 
                references: e.references.map((e) => e.node).toList()))
            .toList();
    
        return sortedDefinitions;      
    } 
    on CycleException catch (e) 
    {
        final target = e.cycle[0] as _TypeDef;
        final dep = target.reverseReferences.where((r) => r.name.fullName == target.name).firstOrDefault();

        if (dep == null)
        {
            rethrow;
        }

        diagnostics.addIssue(SemanticIssue(
            code: IssueCode.circularDependency, 
            severity: IssueSeverity.error,
            message: "Definition ${target.name} either directly or indirectly depends on itself.",
            target: target.node,
            related: [dep]));
            
        return [];
    }
}

enum _NodeType
{
    definition,
    importRef,
    undefined,
    reference
}

class _TypeDef implements Comparable<_TypeDef>
{
    final NamedSyntax node;

    String get name => node.name.fullName;
    bool get isref => node is TypeReferenceSyntax;

    final List<_TypeDef> references = [];
    _NodeType type = _NodeType.undefined;
    final List<TypeReferenceSyntax> reverseReferences = [];

    _TypeDef({
        required this.node
    })
    {
        if (isref)
        {
            type = _NodeType.reference;
        }
        else if (node is TypeDefinitionSyntax ||
            node is ConstantSyntax)
        {
            type = _NodeType.definition;
        }        
    }

    void addReference(NamedSyntax ref) => references.add(_TypeDef(node: ref));

    @override
    bool operator==(Object other) =>
        other is _TypeDef && 
        other.runtimeType == runtimeType &&
        other.node.name == node.name;

    @override
    int get hashCode => node.name.hashCode;
    
    @override
    int compareTo(_TypeDef other) => node.name.compareTo(other.node.name);

    @override
    String toString() => "$name (${references.length})";
}

class _ReferenceAdder extends AstVisitor
{
    late NamedSyntax _reference;
    final _DefinitionCollector _collector;

    _ReferenceAdder(this._collector);

    void go(NamedSyntax reference, [NamedSyntax? targetReference])
    {
        _reference = targetReference ?? reference;
        visit(reference);
    }

    @override
    void visitTypeReference(TypeReferenceSyntax node) 
    {
        if (node.typeParameters.isNotEmpty)
        {
            for(final param in node.typeParameters)
            {
                visitTypeReference(param);
            }
            return;
        }
        _collector.addReference(node, _reference);    
    }
}

class _ExpressionDependencyCollector extends AstVisitor
{
    final _DefinitionCollector _collector;
    late NamedSyntax _dependent;

    _ExpressionDependencyCollector(this._collector);
    
    void go(NamedSyntax depenent, SyntaxNode expression)
    {
        _dependent = depenent;
        visit(expression);
    }

    @override
    void visitLiteralExpression(LiteralExpressionSyntax node) 
    {
        if (node.literal.kind != LiteralKindSyntax.identifier)
        {
            return;
        }
        final target = _collector.find(node.literal.value as IdentifierSyntax);
        if (target == null)
        {
            return;
        }
    
        _collector.addReference(_dependent, target);
    }

    @override
    void visitIdentifierExpression(IdentifierExpressionSyntax node) 
    {
        final target = _collector.find(node.identifier);
        if (target == null)
        {
            return;
        }
    
        _collector.addReference(_dependent, target);
    }
}

class _DefinitionCollector extends AstVisitor
{
    final Map<String, _TypeDef> _index = {};

    final Set<String> _imports = {};

    bool _firstPass = true;

    late final _ReferenceAdder _refAdder;
    late final _ExpressionDependencyCollector _expressionCollector;

    DirectedSparseGraph<_TypeDef> definitions = DirectedSparseGraph();

    _TypeDef? find(IdentifierSyntax ident)
    {
        return _index[ident.fullName] ?? _index[ident.namespace];
    }

    _DefinitionCollector()
    {
        _refAdder = _ReferenceAdder(this);
        _expressionCollector = _ExpressionDependencyCollector(this);
    }        

    void go(CompilationUnitSyntax cu, {bool createDotGraphs = false})
    {
        visit(cu);
        _firstPass = false;
        visit(cu);

        if (createDotGraphs)
        {
            final dot = toDot();
            print(dot);
        }
    }

    String toDot()
    {
        final sb = StringBuffer();
        sb.writeln("digraph Frob {");

        for (final edge in definitions.Edges)
        {
            sb.writeln("    \"${edge.Source.name}\" -> \"${edge.Destination.name}\"");
        }
        sb.writeln("}");

        return sb.toString();
    }

    _TypeDef _add(NamedSyntax node)
    {
        var result = _index[node.name.fullName];

        if (result == null)
        {
            result = _TypeDef(node: node);
            
            if (_imports.contains(node.name.namespace))
            {
                result.type = _NodeType.importRef;
            }            
            definitions.AddVertex(result);
            _index[node.name.fullName] = result;            
        }

        return result;
    }

    void addReference(NamedSyntax target, Object ref)
    {
        _TypeDef dest;
        dest = ref is _TypeDef 
            ? ref 
            : _add(ref as NamedSyntax);

        final source = _add(target);

        definitions.AddEdge(source, dest);

        if (ref is TypeReferenceSyntax)
        {
            source.reverseReferences.add(ref);
        }
        dest.addReference(target);
    }

    @override
    void visitAttributeArg(AttributeArgSyntax node) 
    {
        if (_firstPass)
        {
            return;
        }

        if (node.value == null ||
            node.value!.kind != LiteralKindSyntax.identifier)
        {
            return;            
        }

        var result = find(node.value!.value as IdentifierSyntax);
        if (result == null)
        {
            return;
        }

        addReference(node.declarer.declaringNode as NamedSyntax, result);
    }

    @override
    void visitCompilationUnit(CompilationUnitSyntax node) 
    {
        if (_firstPass)
        {
            for(final import in node.imports)
            {
                if (import.scope != null)
                {
                    _imports.add(import.scope!.name);
                }
            }
        }

        super.visitCompilationUnit(node);
    }

    @override
    void visitBaseInterface(TypeReferenceSyntax node) 
    {
        addReference(node.declaringNode as NamedSyntax, node);
    }

    @override
    void visitInterface(InterfaceSyntax node) 
    {
        if (_firstPass)
        {
            _add(node);
            return;
        }
        
        super.visitInterface(node);
    }

    @override
    void visitParameter(ParameterSyntax node) 
    {
        addReference(node.declarer.declarer, node.type);
        super.visitParameter(node);
    }

    @override
    void visitMethod(MethodSyntax node) 
    {
        addReference(node.declarer, node.type);

        super.visitMethod(node);
    }

    @override
    void visitConstant(ConstantSyntax node) 
    {        
        if (_firstPass)
        {
            _add(node);
            return;
        }

        _expressionCollector.go(node, node.value);
        // if (node.value.kind == LiteralKindSyntax.identifier)
        // {
        //     final ident = node.value.value as IdentifierSyntax;

        //     var result = _index[ident.fullName] ?? _index[ident.namespace];
        //     if (result == null)
        //     {
        //         return;
        //     }

        //     addReference(node, result);
        // }
    }

    void _addLiteral(LiteralSyntax lit, NamedSyntax dependent)
    {
        if (lit.kind != LiteralKindSyntax.identifier)
        {
            return;
        }

        final ident = lit.value as IdentifierSyntax;

        var result = find(ident);
        if (result == null)
        {
            return;
        }

        addReference(dependent, result);
    }

    @override
    void visitStructBase(TypeReferenceSyntax node) 
    {
        addReference(node.declaringNode as NamedSyntax, node);
    }

    @override
    void visitStruct(StructSyntax node) 
    {
        if (_firstPass)
        {
            _add(node);
            return;
        }

        super.visitStruct(node);
    }

    @override
    void visitField(FieldSyntax node) 
    {
        addReference(node.declarer, node.type);
        //addReference(node.type, node.declarer);
    }

    @override
    void visitTypeAlias(TypeAliasSyntax node) 
    {
        if (_firstPass)
        {
            _add(node);
            return;
        }

        if (node.aliasedType.builtinKind == TypeKind.list)
        {
            addReference(node, node.aliasedType.typeParameters[0]);
        }
        else if (node.aliasedType.builtinKind == TypeKind.map)
        {
            addReference(node, node.aliasedType.typeParameters[0]);
            addReference(node, node.aliasedType.typeParameters[1]);
        }
        else
        {
            addReference(node, node.aliasedType);
        }
    }

    @override
    void visitEnumerant(EnumerantSyntax node) 
    {
        if (_firstPass)
        {
            return;
        }

        if (node.initializer.isNotEmpty)
        {
            _expressionCollector.go(node, node.initializer);
        }
    }

    @override
    void visitEnum(EnumSyntax node) 
    {
        if (_firstPass)
        {
            _add(node);
        }

        super.visitEnum(node);
    }

    @override
    void visitTypeReference(TypeReferenceSyntax node) 
    {
        if (_firstPass)
        {
            return;
        }

        //_add(node);
    }
}

