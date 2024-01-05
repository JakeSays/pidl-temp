import 'types.dart';

abstract class ExpressionVisitorInterface
{
//    void visitExpression(Expression node);
    void visitOperator(OperatorKind kind);  
    void visitAssignmentExpression(AssignmentExpression node);  
    void visitParenExpression(ParenExpression node);
    bool visitUnaryExpression(UnaryExpression node);
    bool visitBinaryExpression(BinaryExpression node);
    void visitLiteralExpr(LiteralExpression node);
    void visitAdd(Add node);
    void visitSubtract(Subtract node);
    void visitMultiply(Multiply node);
    void visitDivide(Divide node);
    void visitModulo(Modulo node);
    void visitAnd(And node);
    void visitOr(Or node);
    void visitXor(Xor node);
    void visitNegate(Compliment node);
    void visitNegative(Negate node);
    void visitLeftShift(LeftShift node);
    void visitRightShift(RightShift node);
    void visitPower(Power node);
    void visitEmptyExpression(EmptyExpression node);
}

abstract class ExpressionVisitorBase implements ExpressionVisitorInterface
{
    void visitExpression(Expression node)
    {
        if (node is EmptyExpression)
        {
            visitEmptyExpression(node);
            return;
        }

        if (node is UnaryExpression)
        {
            if (visitUnaryExpression(node))
            {
                return;
            }
            
            if(node is Compliment)
            {
                visitNegate(node);
                return;
            }
            if (node is Negate)
            {
                visitNegative(node);
                return;
            }
            throw StateError("You forgot something...");
        }

        if (node is AssignmentExpression)
        {
            visitAssignmentExpression(node);
            return;
        }

        if (node is ParenExpression)
        {
            visitParenExpression(node);
            return;
        }

        if (node is LiteralExpression)
        {
            visitLiteralExpr(node);
            return;
        }

        if (node is BinaryExpression)
        {
            if (visitBinaryExpression(node))
            {
                return;
            }
            else if (node is Add)
            {
                visitAdd(node);
            }
            else if (node is Subtract)
            {
                visitSubtract(node);
            }
            else if (node is Multiply)
            {
                visitMultiply(node);
            }
            else if (node is Divide)
            {
                visitDivide(node);
            }
            else if (node is Modulo)
            {
                visitModulo(node);
            }
            else if (node is And)
            {
                visitAnd(node);
            }
            else if (node is Or)
            {
                visitOr(node);
            }
            else if (node is Xor)
            {
                visitXor(node);
            }
            else if (node is LeftShift)
            {
                visitLeftShift(node);
            }
            else if (node is RightShift)
            {
                visitRightShift(node);
            }
            else if (node is Power)
            {
                visitPower(node);
            }
            else
            {
                throw StateError("You forgot something...");
            }
            return;
        }

        throw StateError("You forgot something...");
    }

    @override
    void visitOperator(OperatorKind kind)
    {}

    @override
    void visitEmptyExpression(EmptyExpression node)
    {}

    @override
    void visitAssignmentExpression(AssignmentExpression node)
    {
        visitExpression(node.valueExpression);
    }

    @override
    bool visitUnaryExpression(UnaryExpression node) => false;

    @override
    bool visitBinaryExpression(BinaryExpression node) => false;

    @override
    void visitParenExpression(ParenExpression node)
    {
        visitExpression(node.nestedExpression);
    }

    @override
    void visitLiteralExpr(LiteralExpression node)
    {}

    @override
    void visitAdd(Add node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }

    @override
    void visitSubtract(Subtract node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }

    @override
    void visitMultiply(Multiply node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }
    
    @override
    void visitDivide(Divide node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }
    
    @override
    void visitModulo(Modulo node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }
    
    @override
    void visitAnd(And node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }
    
    @override
    void visitOr(Or node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }

    @override
    void visitXor(Xor node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }

    @override
    void visitNegate(Compliment node)
    {
        visitOperator(node.operator);
        visitExpression(node.expression);
    }

    @override
    void visitNegative(Negate node)
    {
        visitOperator(node.operator);
        visitExpression(node.expression);
    }

    @override
    void visitLeftShift(LeftShift node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }

    @override
    void visitRightShift(RightShift node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }

    @override
    void visitPower(Power node)
    {
        visitExpression(node.lhs);
        visitOperator(node.operator);
        visitExpression(node.rhs);
    }
}

class ExpressionVisitor extends ExpressionVisitorBase
{
    void visit(Expression node) => visitExpression(node);
}

class PostfixExpressionVisitor extends ExpressionVisitor
{
    @override
    void visitAdd(Add node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }

    @override
    void visitSubtract(Subtract node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }

    @override
    void visitMultiply(Multiply node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }
    
    @override
    void visitDivide(Divide node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }
    
    @override
    void visitModulo(Modulo node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }
    
    @override
    void visitAnd(And node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }
    
    @override
    void visitOr(Or node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }

    @override
    void visitXor(Xor node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }

    @override
    void visitNegate(Compliment node)
    {
        visitExpression(node.expression);
        visitOperator(node.operator);
    }

    @override
    void visitNegative(Negate node)
    {
        visitExpression(node.expression);
        visitOperator(node.operator);
    }

    @override
    void visitLeftShift(LeftShift node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }

    @override
    void visitRightShift(RightShift node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }    

    @override
    void visitPower(Power node)
    {
        visitExpression(node.lhs);
        visitExpression(node.rhs);
        visitOperator(node.operator);
    }
}