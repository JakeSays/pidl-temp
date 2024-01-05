import '../diagnostics.dart';
import '../type_scope.dart';
import '../parsing/ast.dart';
import '../parsing/ast_visitor.dart';
import '../types.dart';
import "extensions.dart";
import '../stack.dart';

class ExpressionBuilder extends ThrowingAstVisitor
{
    TypeScope scope;
    late TypeReference _expressionType;
    late TypeReferenceSyntax _expressionTypeSyntax;

    final Diagnostics diagnostics;

    final Stack<Expression> _expressionStack = Stack<Expression>();
    Enumerant? Function(IdentifierSyntax ident)? _enumerantResolver;

    ExpressionBuilder({
        required this.diagnostics,
        required this.scope
    });

    Expression build(
        ExpressionSyntax expression, 
        TypeReference expressionType, 
        TypeReferenceSyntax expressionTypeSyntax,
        [Enumerant? Function(IdentifierSyntax ident)? enumerantResolver])
    {
        if (expression.isEmpty)
        {
            return EmptyExpression(location: expression.location);
        }

        _enumerantResolver = enumerantResolver;

        _expressionType = expressionType;
        _expressionTypeSyntax = expressionTypeSyntax;
       
        visit(expression);

        final result = _expressionStack.pop();
        return result;
    }

    Expression _makeBinary(BinaryExpressionSyntax node)
    {
        final rhs = _expressionStack.pop();
        final lhs = _expressionStack.pop();

        switch (node.operator.kind)
        {            
            case OperatorKindSyntax.subtract:
                return Subtract(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.add:
                return Add(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.multiply:
                return Multiply(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.divide:
                return Divide(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.modulo:
                return Modulo(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.or:
                return Or(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.xor:
                return Xor(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.and:
                return And(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.leftShift:
                return LeftShift(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.rightShift:
                return RightShift(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            case OperatorKindSyntax.power:
                return Power(
                    lhs: lhs, 
                    rhs: rhs,
                    location: node.location);
            default:
                throw StateError("fuck!");
        }
    }

    @override
    void visitAssignmentExpression(AssignmentExpressionSyntax node)
    {
        visit(node.value);
        final valueexpr = _expressionStack.pop();
        final expr = AssignmentExpression(valueExpression: valueexpr);
        _expressionStack.push(expr);
    }

    @override
    void visitEmptyExpression(ExpressionSyntax node) 
    {
        _expressionStack.push(EmptyExpression(location: node.location));
    }

    @override
    void visitBinaryExpression(BinaryExpressionSyntax node) 
    {
        visit(node.lhs);
        visit(node.rhs);

        _expressionStack.push(_makeBinary(node));
    }

    @override
    void visitLiteralExpression(LiteralExpressionSyntax node) 
    {
        Literal? literal;
        if (_enumerantResolver != null && node.literal.kind == LiteralKindSyntax.identifier)
        {
            final enumerant = _enumerantResolver!(node.literal.value as IdentifierSyntax);
            if (enumerant != null)            
            {
                final enumType = TypeReference.to(enumerant.declarer, location: node.location);
                literal = Literal.enumerantref(enumerant, enumType, node.location);
            }
        }

        if (literal == null)
        {
            final value = node.literal.toSemanticLiteral(scope, _expressionType, _expressionTypeSyntax);
            literal = value.status.issuccess
                ? value.value!
                : Literal.error(node.location);        
        }

        final expr = LiteralExpression(
            literal: literal,
            location: node.location);
        _expressionStack.push(expr);
    }

    @override
    void visitParenExpression(ParenExpressionSyntax node) 
    {
        visit(node.nestedExpression);
        
        final expr = ParenExpression(
            nestedExpression: _expressionStack.pop(),
            location: node.location);
        _expressionStack.push(expr); 
    }

    @override
    void visitUnaryExpression(UnaryExpressionSyntax node) 
    {        
        visit(node.expression);

        Expression expr;
        if (node.operator.kind == OperatorKindSyntax.negate)
        {
            expr = Negate(
                expression: _expressionStack.pop(),
                location: node.location);
        }
        else if (node.operator.kind == OperatorKindSyntax.compliment)
        {
            expr = Compliment(
                expression: _expressionStack.pop(),
                location: node.location);
        }
        else
        {
            throw StateError("You forgot something...");
        }
        _expressionStack.push(expr);
    }
}