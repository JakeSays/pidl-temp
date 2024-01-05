import '../type_visitor.dart';
import '../types.dart';
import '../compile_result.dart';

class CompletenessChecker extends TypeVisitor
{
    List<IncompleteDefinition> incompleteNodes = [];
    final Set<Definition> _visited = <Definition>{};
    late CompilationUnit _currentUnit;

    CompletenessChecker._();

    static List<IncompleteDefinition> check(List<CompilationUnit> cus)
    {
        final self = CompletenessChecker._();
        for(final cu in cus)
        {
            self._currentUnit = cu;

            self.visit(cu);
        }

        return self.incompleteNodes;
    }

    void _check(Definition node)
    {
        if (!_visited.add(node))
        {
            return;
        }

        if (!node.iscomplete)
        {
            incompleteNodes.add(IncompleteDefinition(definition: node, declaringUnit: _currentUnit));
        }
    }

    @override
    void visitImport(Import node) { _check(node); super.visitImport(node); }
    @override
    void visitAttributeArg(AttributeArg node) { _check(node); super.visitAttributeArg(node); }
    @override
    void visitAttribute(Attribute node) { _check(node); super.visitAttribute(node); }
    @override
    void visitIdentifier(Identifier node) { _check(node); super.visitIdentifier(node); }
    @override
    void visitLiteral(Literal node) { _check(node); super.visitLiteral(node); }
    @override
    void visitTypeParameter(TypeReference node) { _check(node); super.visitTypeParameter(node); }
    @override
    void visitTypeReference(TypeReference node) { _check(node); super.visitTypeReference(node); }
    @override
    void visitConstReference(ConstantReference node) { _check(node); super.visitConstReference(node); }
    @override
    void visitConstant(Constant node) { _check(node); super.visitConstant(node); }
    @override
    void visitParameterType(TypeReference node) { _check(node); super.visitParameterType(node); }
    @override
    void visitParameter(Parameter node) { _check(node); super.visitParameter(node); }
    @override
    void visitMethodReturnType(TypeReference node) { _check(node); super.visitMethodReturnType(node); }
    @override
    void visitMethod(Method node) { _check(node); super.visitMethod(node); }
    @override
    void visitBaseInterface(TypeReference node) { _check(node); super.visitBaseInterface(node); }
    @override
    void visitInterface(Interface node) { _check(node); super.visitInterface(node); }
    @override
    void visitNamespace(Namespace node) { _check(node); super.visitNamespace(node); }
    @override
    void visitCompilationUnit(CompilationUnit node) { _check(node); super.visitCompilationUnit(node); }
    @override
    void visitEnumerant(Enumerant node) { _check(node); super.visitEnumerant(node); }
    @override
    void visitEnum(Enum node) { _check(node); super.visitEnum(node); }
    @override
    void visitFieldType(TypeReference node) { _check(node); super.visitFieldType(node); }
    @override
    void visitField(Field node) { _check(node); super.visitField(node); }
    @override
    void visitStructBase(TypeReference node) { _check(node); super.visitStructBase(node); }
    @override
    void visitStruct(Struct node) { _check(node); super.visitStruct(node); }
    @override
    void visitTypeAlias(Alias node) { _check(node); super.visitTypeAlias(node); }
    @override
    void visitGenericTypeDefinition(GenericTypeDefinition node) { _check(node); super.visitGenericTypeDefinition(node); }
}