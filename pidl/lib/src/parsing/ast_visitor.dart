import 'ast.dart';

abstract class AstVisitorBase
{    
    bool visitTypeDefinition(TypeDefinitionSyntax node);
    void visitImport(ImportSyntax node);
    void visitComment(CommentSyntax node);
    void visitAttributeArg(AttributeArgSyntax node);
    void visitAttribute(AttributeSyntax node);
    void visitIdentifier(IdentifierSyntax node);
    void visitLiteral(LiteralSyntax node);
    void visitTypeParameter(TypeReferenceSyntax node);
    void visitTypeReference(TypeReferenceSyntax node);
    void visitConstant(ConstantSyntax node);
    void visitParameter(ParameterSyntax node);
    void visitMethodReturnType(TypeReferenceSyntax node);
    void visitMethod(MethodSyntax node);
    void visitBaseInterface(BaseTypeSyntax node);
    void visitInterface(InterfaceSyntax node);
    void visitNamespace(NamespaceSyntax node);
    void visitCompilationUnit(CompilationUnitSyntax node);
    void visitEnumerant(EnumerantSyntax node);
    void visitEnum(EnumSyntax node);
    void visitEnumType(BaseTypeSyntax node);
    void visitFieldType(TypeReferenceSyntax node);
    void visitField(FieldSyntax node);
    void visitStructBase(TypeReferenceSyntax node);
    void visitStruct(StructSyntax node);
    void visitTypeAlias(TypeAliasSyntax node);
    bool visitExpression(ExpressionSyntax node);
    void visitAssignmentExpression(AssignmentExpressionSyntax node);
    void visitEmptyExpression(ExpressionSyntax node);
    void visitUnaryExpression(UnaryExpressionSyntax node);
    void visitBinaryExpression(BinaryExpressionSyntax node);
    void visitParenExpression(ParenExpressionSyntax node);
    void visitLiteralExpression(LiteralExpressionSyntax node);
    void visitIdentifierExpression(IdentifierExpressionSyntax node);
    void visitOperator(OperatorSyntax node);

    void visit(SyntaxNode node)
    {
        if ((node is InterfaceSyntax || 
            node is EnumSyntax ||
            node is StructSyntax ||
            node is TypeAliasSyntax))
        {
            if (visitTypeDefinition(node as TypeDefinitionSyntax))
            {
                return;
            }

            if (node is InterfaceSyntax)
            {
                visitInterface(node);
                return;
            }

            if (node is EnumSyntax)
            {
                visitEnum(node);
                return;
            }

            if (node is StructSyntax)
            {
                visitStruct(node);
                return;
            }

            visitTypeAlias(node as TypeAliasSyntax);
            return;
        }

        if (node is ExpressionSyntax)
        {
            if (visitExpression(node))
            {
                return;
            }

            if (node.isEmpty)
            {
                visitEmptyExpression(node);
                return;
            }

            if (node is UnaryExpressionSyntax)
            {
                visitUnaryExpression(node);
                return;
            }

            if (node is BinaryExpressionSyntax)
            {
                visitBinaryExpression(node);
                return;
            }

            if (node is ParenExpressionSyntax)
            {
                visitParenExpression(node);
                return;
            }

            if (node is LiteralExpressionSyntax)
            {
                visitLiteralExpression(node);
                return;
            }

            if (node is AssignmentExpressionSyntax)
            {
                visitAssignmentExpression(node);
                return;
            }
            
            visitIdentifierExpression(node as IdentifierExpressionSyntax);
            return;
        }

        if (node is OperatorSyntax)
        {
            visitOperator(node);
            return;
        }

        if (node is ImportSyntax)
        {
            visitImport(node);
            return;
        }

        if (node is CommentSyntax)
        {
            visitComment(node);
            return;
        }

        if (node is AttributeArgSyntax)
        {
            visitAttributeArg(node);
            return;
        }

        if (node is AttributeSyntax)
        {
            visitAttribute(node);
            return;
        }

        if (node is IdentifierSyntax)
        {
            visitIdentifier(node);
            return;
        }

        if (node is LiteralSyntax)
        {
            visitLiteral(node);
            return;
        }

        if (node is BaseTypeSyntax)
        {
            switch(node.kind)
            {
                case BaseKind.interface:
                    visitBaseInterface(node);
                    break;
                case BaseKind.$enum:
                    visitEnumType(node);
                    break;
                case BaseKind.struct:
                    visitStructBase(node);
                    break;
            }
            return;
        }

        if (node is TypeReferenceSyntax)
        {
            visitTypeReference(node);
            return;
        }

        if (node is ConstantSyntax)
        {
            visitConstant(node);
            return;
        }

        if (node is ParameterSyntax)
        {
            visitParameter(node);
            return;
        }

        if (node is MethodSyntax)
        {
            visitMethod(node);
            return;
        }

        if (node is NamespaceSyntax)
        {
            visitNamespace(node);
            return;
        }

        if (node is CompilationUnitSyntax)
        {
            visitCompilationUnit(node);
            return;
        }

        if (node is EnumerantSyntax)
        {
            visitEnumerant(node);
            return;
        }

        if (node is FieldSyntax)
        {
            visitField(node);
            return;
        }

        throw StateError("Oh snap!");
    }
}

class AstVisitor extends AstVisitorBase
{
    AstVisitor get self => this;

    @override
    bool visitTypeDefinition(TypeDefinitionSyntax node)
    {
        return false;
    }

    @override
    void visitImport(ImportSyntax node)
    {
    }

    @override
    void visitComment(CommentSyntax node)
    {
    }

    @override
    void visitAttributeArg(AttributeArgSyntax node)
    {
    }

    @override
    void visitAttribute(AttributeSyntax node)
    {
        for (final arg in node.args?.list ?? [])
        {
            visit(arg);
        }
    }

    @override
    void visitIdentifier(IdentifierSyntax node)
    {
    }

    @override
    void visitLiteral(LiteralSyntax node)
    {
    }

    @override
    void visitTypeParameter(TypeReferenceSyntax node) => visitTypeReference(node);

    @override
    void visitTypeReference(TypeReferenceSyntax node)
    {
        for (final param in node.typeParameters)
        {
            visitTypeParameter(param);
        }
    }

    @override
    void visitConstant(ConstantSyntax node)
    {
        _visitAttributes(node);
        visit(node.type);
        visit(node.value);
    }

    @override
    void visitParameter(ParameterSyntax node)
    {
        _visitAttributes(node);
        visit(node.type);
        if (node.defaultValue != null)
        {
            visit(node.defaultValue!);
        }
    }

    @override
    void visitMethodReturnType(TypeReferenceSyntax node) => visitTypeReference(node);    

    @override
    void visitMethod(MethodSyntax node)
    {
        _visitAttributes(node);
        visitMethodReturnType(node.type);
        for (final param in node.parameters.list)
        {
            visit(param);
        }
    }

    @override
    void visitBaseInterface(BaseTypeSyntax node) => visitTypeReference(node);    

    @override
    void visitInterface(InterfaceSyntax node)
    {
        _visitAttributes(node);        
        _visitList(node.bases?.list);
        _visitList(node.methods?.list);
    }

    @override
    void visitNamespace(NamespaceSyntax node)
    {
        _visitAttributes(node);
        _visitList(node.scopeComments);
        _visitList(node.constants);
        _visitList(node.enumerations);
        _visitList(node.interfaces);
        _visitList(node.namespaces);
        _visitList(node.structs);
        _visitList(node.typeAliases);
    }

    @override
    void visitCompilationUnit(CompilationUnitSyntax node)
    {
        _visitList(node.imports);
        _visitList(node.scopeComments);
        _visitList(node.constants);
        _visitList(node.enumerations);
        _visitList(node.interfaces);
        _visitList(node.namespaces);
        _visitList(node.structs);
        _visitList(node.typeAliases);
    }

    @override
    void visitEnumerant(EnumerantSyntax node)
    {
        _visitAttributes(node);
        visit(node.initializer);
    }

    @override
    void visitEnumType(BaseTypeSyntax node) => visitTypeReference(node);

    @override
    void visitEnum(EnumSyntax node)
    {
        _visitAttributes(node);
        _visitList(node.enumerants?.list);
    }

    @override
    void visitFieldType(TypeReferenceSyntax node) => visitTypeReference(node);    

    @override
    void visitField(FieldSyntax node)
    {
        _visitAttributes(node);
        visitFieldType(node.type);

        if (node.defaultValue != null)
        {
            visit(node.defaultValue!);
        }
    }

    @override
    void visitStructBase(TypeReferenceSyntax node) => visitTypeReference(node);

    @override
    void visitStruct(StructSyntax node)
    {
        _visitAttributes(node);

        if (node.base != null)
        {
            visitStructBase(node.base!);
        }

        _visitList(node.fields.list);
    }

    @override
    void visitTypeAlias(TypeAliasSyntax node)
    {
        _visitAttributes(node);        
        visit(node.aliasedType);
    }

    @override
    bool visitExpression(ExpressionSyntax node)
    {
        return false;
    }

    @override
    void visitEmptyExpression(ExpressionSyntax node) 
    {        
    }

    @override
    void visitAssignmentExpression(AssignmentExpressionSyntax node) => visit(node.value);

    @override
    void visitUnaryExpression(UnaryExpressionSyntax node)
    {
        visit(node.operator);
        visit(node.expression);
    }

    @override
    void visitBinaryExpression(BinaryExpressionSyntax node)
    {
        visit(node.lhs);
        visit(node.operator);
        visit(node.rhs);
    }
    
    @override
    void visitParenExpression(ParenExpressionSyntax node)
    {
        visit(node.nestedExpression);
    }
    
    @override
    void visitLiteralExpression(LiteralExpressionSyntax node)
    {
        visit(node.literal);
    }
    
    @override
    void visitIdentifierExpression(IdentifierExpressionSyntax node)
    {
        visit(node.identifier);
    }
    
    @override
    void visitOperator(OperatorSyntax node)
    {
    }    

    void _visitAttributes(SyntaxNode node)
    {
        _visitList(node.attributes?.list);
    }

    void _visitList(List<SyntaxNode>? list)
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
}

class ThrowingAstVisitor extends AstVisitor
{
    AstVisitor get base => self;

    @override
    bool visitTypeDefinition(TypeDefinitionSyntax node) => false;
    @override
    void visitImport(ImportSyntax node) => throw StateError("Not implemented");
    @override
    void visitComment(CommentSyntax node) => throw StateError("Not implemented");
    @override
    void visitAttributeArg(AttributeArgSyntax node) => throw StateError("Not implemented");
    @override
    void visitAttribute(AttributeSyntax node) => throw StateError("Not implemented");
    @override
    void visitIdentifier(IdentifierSyntax node) => throw StateError("Not implemented");
    @override
    void visitLiteral(LiteralSyntax node) => throw StateError("Not implemented");
    @override
    void visitTypeParameter(TypeReferenceSyntax node) => throw StateError("Not implemented");
    @override
    void visitTypeReference(TypeReferenceSyntax node) => throw StateError("Not implemented");
    @override
    void visitConstant(ConstantSyntax node) => throw StateError("Not implemented");
    @override
    void visitParameter(ParameterSyntax node) => throw StateError("Not implemented");
    @override
    void visitMethodReturnType(TypeReferenceSyntax node) => throw StateError("Not implemented");
    @override
    void visitMethod(MethodSyntax node) => throw StateError("Not implemented");
    @override
    void visitBaseInterface(BaseTypeSyntax node) => throw StateError("Not implemented");
    @override
    void visitInterface(InterfaceSyntax node) => throw StateError("Not implemented");
    @override
    void visitNamespace(NamespaceSyntax node) => throw StateError("Not implemented");
    @override
    void visitCompilationUnit(CompilationUnitSyntax node) => throw StateError("Not implemented");
    @override
    void visitEnumerant(EnumerantSyntax node) => throw StateError("Not implemented");
    @override
    void visitEnum(EnumSyntax node) => throw StateError("Not implemented");
    @override
    void visitEnumType(BaseTypeSyntax node) => throw StateError("Not implemented");
    @override
    void visitFieldType(TypeReferenceSyntax node) => throw StateError("Not implemented");
    @override
    void visitField(FieldSyntax node) => throw StateError("Not implemented");
    @override
    void visitStructBase(TypeReferenceSyntax node) => throw StateError("Not implemented");
    @override
    void visitStruct(StructSyntax node) => throw StateError("Not implemented");
    @override
    void visitTypeAlias(TypeAliasSyntax node) => throw StateError("Not implemented");
    @override
    bool visitExpression(ExpressionSyntax node) => false;
    @override
    void visitAssignmentExpression(AssignmentExpressionSyntax node)=> throw StateError("Not implemented");
    @override
    void visitEmptyExpression(ExpressionSyntax node) => throw StateError("Not implemented");
    @override
    void visitUnaryExpression(UnaryExpressionSyntax node) => throw StateError("Not implemented");
    @override
    void visitBinaryExpression(BinaryExpressionSyntax node) => throw StateError("Not implemented");
    @override
    void visitParenExpression(ParenExpressionSyntax node) => throw StateError("Not implemented");
    @override
    void visitLiteralExpression(LiteralExpressionSyntax node) => throw StateError("Not implemented");
    @override
    void visitIdentifierExpression(IdentifierExpressionSyntax node) => throw StateError("Not implemented");
    @override
    void visitOperator(OperatorSyntax node) => throw StateError("Not implemented");
}