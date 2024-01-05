import 'types.dart';
import 'expression_visitors.dart';

export 'expression_visitors.dart';

abstract class TypeVisitorInterface
{    
    void visit(Definition node);
    void visitExpression(Expression node);
    bool visitTypeDefinition(TypeDefinition node);
    void visitImport(Import node);
    void visitAttributeArg(AttributeArg node);
    void visitAttribute(Attribute node);
    void visitIdentifier(Identifier node);
    void visitLiteral(Literal node);
    void visitTypeParameter(TypeReference node);
    void visitTypeReference(TypeReference node);
    void visitConstReference(ConstantReference node);
    void visitConstant(Constant node);
    void visitParameterType(TypeReference node);
    void visitParameter(Parameter node);
    void visitMethodReturnType(TypeReference node);
    void visitMethod(Method node);
    void visitBaseInterface(TypeReference node);
    void visitInterface(Interface node);
    void visitNamespace(Namespace node);
    void visitCompilationUnit(CompilationUnit node);
    void visitEnumerant(Enumerant node);
    void visitEnum(Enum node);
    void visitFieldType(TypeReference node);
    void visitField(Field node);
    void visitStructBase(TypeReference node);
    void visitStruct(Struct node);
    void visitTypeAlias(Alias node);
    void visitGenericTypeDefinition(GenericTypeDefinition node);
}

class TypeVisitor extends ExpressionVisitorBase 
    implements TypeVisitorInterface
{    
    @override
    void visit(Definition node)
    {
        if ((node is Interface || 
            node is Enum ||
            node is Struct ||
            node is Alias ||
            node is GenericTypeDefinition) &&
            visitTypeDefinition(node as TypeDefinition))
        {
            return;
        }

        if (node is Expression)
        {
            visitExpression(node);
            return;
        }

        if (node is GenericTypeDefinition)
        {
            visitGenericTypeDefinition(node);
            return;
        }

        if (node is Interface)
        {
            visitInterface(node);
            return;
        }

        if (node is Enum)
        {
            visitEnum(node);
            return;
        }

        if (node is Struct)
        {
            visitStruct(node);
            return;
        }

        if (node is Alias)
        {
            visitTypeAlias(node);
            return;
        }

        if (node is Import)
        {
            visitImport(node);
            return;
        }

        if (node is AttributeArg)
        {
            visitAttributeArg(node);
            return;
        }

        if (node is Attribute)
        {
            visitAttribute(node);
            return;
        }

        if (node is Identifier)
        {
            visitIdentifier(node);
            return;
        }

        if (node is Literal)
        {
            visitLiteral(node);
            return;
        }

        if (node is TypeReference)
        {
            visitTypeReference(node);
            return;
        }

        if (node is Constant)
        {
            visitConstant(node);
            return;
        }

        if (node is Parameter)
        {
            visitParameter(node);
            return;
        }

        if (node is Method)
        {
            visitMethod(node);
            return;
        }

        if (node is Namespace)
        {
            visitNamespace(node);
            return;
        }

        if (node is CompilationUnit)
        {
            visitCompilationUnit(node);
            return;
        }

        if (node is Enumerant)
        {
            visitEnumerant(node);
            return;
        }

        if (node is Field)
        {
            visitField(node);
            return;
        }
    }

    @override
    bool visitTypeDefinition(TypeDefinition node)
    {
        return false;
    }

    @override
    void visitGenericTypeDefinition(GenericTypeDefinition node)
    {
        visit(node.ident);

        for (final param in node.typeParameters)
        {
            visitTypeParameter(param);
        }
    }

    @override
    void visitImport(Import node)
    {
    }

    @override
    void visitAttributeArg(AttributeArg node)
    {
        if (node.value != null)
        {
            visit(node.value!);
        }
    }

    @override
    void visitAttribute(Attribute node)
    {
        visit(node.ident);
        for (final arg in node.args)
        {
            visit(arg);
        }
    }

    @override
    void visitIdentifier(Identifier node)
    {
    }

    @override
    void visitLiteral(Literal node)
    {
        if (node.kind == LiteralKind.enumerantref)
        {
            visit(node.asEnum);
            return;
        }
        if (node.kind == LiteralKind.constref)
        {
            visit(node.asConstRef.target);
        }
    }

    @override
    void visitTypeParameter(TypeReference node)
    {        
        visitTypeReference(node);
    }

    @override
    void visitTypeReference(TypeReference node)
    {
        visit(node.referenced);
    }

    @override
    void visitConstant(Constant node)
    {
        visit(node.ident);

        _visitAttributes(node);
        visit(node.type);

        if (node.value != null)
        {
            visit(node.value!);
        }
    }

    @override
    void visitParameterType(TypeReference node) 
    {
        visitTypeReference(node);
    }

    @override
    void visitParameter(Parameter node)
    {
        visit(node.ident);
        _visitAttributes(node);
        visitParameterType(node.type);

        visitExpression(node.initializer);
        
        if (node.defaultValue != null)
        {
            visit(node.defaultValue!);
        }
    }

    @override
    void visitMethodReturnType(TypeReference node) 
    {
        visitTypeReference(node);
    }

    @override
    void visitMethod(Method node)
    {
        visit(node.ident);
        _visitAttributes(node);
        visitMethodReturnType(node.returnType);
        for (final param in node.parameters)
        {
            visitParameter(param);
        }
    }

    @override
    void visitBaseInterface(TypeReference node)
    {
        visit(node);
    }

    @override
    void visitInterface(Interface node)
    {
        visit(node.ident);
        _visitAttributes(node);
        _visitList(node.bases);
        _visitList(node.methods);
    }

    @override
    void visitNamespace(Namespace node)
    {
        visit(node.ident);
        _visitAttributes(node);
        _visitList(node.constants);
        _visitList(node.enumerations);
        _visitList(node.interfaces);
        _visitList(node.namespaces);
        _visitList(node.structs);
        _visitList(node.typeAliases);
    }

    @override
    void visitCompilationUnit(CompilationUnit node)
    {
        _visitList(node.imports);
        _visitList(node.constants);
        _visitList(node.enumerations);
        _visitList(node.interfaces);
        _visitList(node.namespaces);
        _visitList(node.structs);
        _visitList(node.typeAliases);
    }

    @override
    void visitEnumerant(Enumerant node)
    {
        visit(node.ident);
        _visitAttributes(node);
        visit(node.value);
    }

    @override
    void visitEnum(Enum node)
    {
        visit(node.ident);
        _visitAttributes(node);
        _visitList(node.enumerants);
    }

    @override
    void visitFieldType(TypeReference node) 
    {
        visitTypeReference(node);
    }

    @override
    void visitField(Field node)
    {
        visit(node.ident);
        _visitAttributes(node);
        visitFieldType(node.type);

        if (node.defaultValue != null)
        {
            visit(node.defaultValue!);
        }
    }

    @override
    void visitStructBase(TypeReference node)
    {
        visitTypeReference(node);
    }

    @override
    void visitStruct(Struct node)
    {
        visit(node.ident);        
        _visitAttributes(node);

        if (node.base != null)
        {
            visitStructBase(node.base!);
        }

        _visitList(node.fields);
    }

    @override
    void visitTypeAlias(Alias node)
    {
        visit(node.ident);
        _visitAttributes(node); 

        if (node.istyperef)
        {
            visit(node.typeref);
        }
        else
        {
            visit(node.constref);
        }
    }

    void _visitAttributes(Definition node)
    {
        _visitList(node.attributes);
    }

    void _visitList(List<Definition>? list)
    {
        if (list == null)
        {
            return;
        }

        for (final item in list)
        {
            item.accept(this);
        }
    }
    
    @override
    void visitConstReference(ConstantReference node) 
    {
        _visitAttributes(node);
        visit(node.target);
    }
}
