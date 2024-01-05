import 'dart:math' as Math;
import 'types.dart';
import 'expression_visitors.dart';
import 'diagnostics.dart';
import 'extensions.dart';
import 'stack.dart';

class ExpressionResult
{
    Literal? literal;
    ExprValue? value;

    ExpressionResult({
        this.literal,
        this.value
    });

    @override
    String toString() 
    {
        if (literal != null)
        {
            return literal.toString();
        }

        return value?.toString() ?? "<none>";
    }
}

class StackedResult
{
    ExprValue v;
    Expression node;

    NumberKind get kind => v.kind;

    StackedResult(this.v, this.node)
    {        
        if (node is LiteralExpression)
        {
            node.computedValue = v;
            return;
        }
        throw StateError("wtf!");
        // if (node.parent.isNotEmpty)
        // {
        //     node.parent.computedValue = v;
        // }
    }

    StackedResult.int(BigInt i, NumberKind k, Expression node)
        : v = ExprValue.int(i, k),
          node = node
    {        
        if (node.isNotEmpty)
        {
            node.computedValue = v;
        }
    }

    StackedResult.real(double r, NumberKind k, Expression node)
        : v = ExprValue.real(r, k),
          node = node
    {        
        if (node.isNotEmpty)
        {
            node.computedValue = v;
        }
    }

    BigInt get intValue => v.intValue;
    double get realValue => v.realValue;

    @override
    String toString() => "$v <= $node";
    
      
    ExprValue promote(NumberKind newKind) => v.promote(newKind);
}

class ExpressionEvaluator extends PostfixExpressionVisitor
{
    late Diagnostics diagnostics;
    final  _stack = Stack<StackedResult>();
    NumberKind _expressionKind = NumberKind.int8;
    bool _cancel = false;

    ExprValue? evaluate(Diagnostics diagnostics, Expression expression)
    {
        this.diagnostics = diagnostics;
        _stack.clear();
        _cancel = false;

        visit(expression);

        final result = _stack.pop();
        return result.v;
    }

    @override
    void visitAssignmentExpression(AssignmentExpression node) 
    {
        visitExpression(node.valueExpression);

        node.computedValue = node.valueExpression.computedValue;
    }

    StackedResult? _evaluateLiteralExpr(LiteralExpression node)
    {
        final lit = node.literal;

        if (lit.kind == LiteralKind.constref)
        {
            final $const = lit.asConstRef.target;
            return StackedResult($const.computedValue, node);
        }

        if (lit.kind == LiteralKind.enumerantref)
        {
            final value = lit.asEnum.target.value.asNumber;
            final evalue = ExprValue.int(value.asint, value.kind);
            return StackedResult(evalue, node);
        }

        if (lit.kind != LiteralKind.number ||
            lit.asNumber.kind == NumberKind.none)
        {
            return null;
        }

        final number = lit.asNumber;
        if (number.kind.isint)
        {
            final value = number.asint;
            return StackedResult(ExprValue.int(value, value.kind), node);
        } 
        
        final realValue = number.asreal;
        return StackedResult(ExprValue.real(realValue, realValue.kind), node);
    }

    @override 
    void visitParenExpression(ParenExpression node)
    {
        visit(node.nestedExpression);
        node.computedValue = node.nestedExpression.computedValue;
        _stack.top.node = node;
    }

    @override
    void visitLiteralExpr(LiteralExpression node) 
    {
        if (_cancel)
        {
            return;
        }

        final value = _evaluateLiteralExpr(node);
        if (value == null)
        {
            diagnostics.addIssue(
                EvaluateIssue(
                    code: IssueCode.invalidLiteralValue,
                    severity: IssueSeverity.error,
                    target: node));
            _cancel = true;
            return;
        }

        if (value.kind > _expressionKind)
        {
            _expressionKind = value.kind;
            for (var item in _stack.items)
            {
                item.promote(_expressionKind); 
            }
        }
        else
        {
            value.promote(_expressionKind);
        }

        _stack.push(value);
    }

    @override
    void visitOperator(OperatorKind kind) 
    {
        if (_cancel)
        {
            return;
        }

        if (!kind.isbinary)
        {            
            final value = _stack.pop();
            switch(kind)
            {
                case OperatorKind.negate:
                    if (value.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            -value.intValue,
                            value.kind, 
                            value.node));                       
                        break;
                    }
                    _stack.push(StackedResult.real(
                        -value.realValue,
                        value.kind, 
                        value.node));
                    break;
                
                case OperatorKind.compliment:
                    if (value.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            ~value.intValue, 
                            value.kind, value.node));
                        return;
                    }
                    throw StateError("Bitwise operations not supported for real number");

                default:
                    throw StateError("Bah!");
            }
        }
        else
        {
            final rhs = _stack.pop();
            final lhs = _stack.pop();

            switch(kind)
            {
                case OperatorKind.power:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(                            
                            lhs.intValue.pow(rhs.intValue.toInt()), 
                            lhs.kind, lhs.node.parent));                        
                        break;
                    }
                    _stack.push(StackedResult.real(
                        Math.pow(lhs.realValue, rhs.intValue.toInt()) as double,
                        lhs.kind, lhs.node.parent));
                    break;
                case OperatorKind.add:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue + rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        
                        break;
                    }
                    _stack.push(StackedResult.real(
                        lhs.realValue + rhs.realValue, 
                        lhs.kind, lhs.node.parent));
                    break;
                case OperatorKind.subtract:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue - rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    _stack.push(StackedResult.real(
                        lhs.realValue - rhs.realValue, 
                        lhs.kind, lhs.node.parent));
                    break;
                case OperatorKind.multiply:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue * rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    _stack.push(StackedResult.real(
                        lhs.realValue * rhs.realValue, 
                        lhs.kind, lhs.node.parent));
                    break;
                case OperatorKind.divide:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue ~/ rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    _stack.push(StackedResult.real(
                        lhs.realValue / rhs.realValue, 
                        lhs.kind, lhs.node.parent));
                    break;
                case OperatorKind.modulo:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue % rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    _stack.push(StackedResult.real(
                        lhs.realValue % rhs.realValue, 
                        lhs.kind, lhs.node.parent));
                    break;
                case OperatorKind.or:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue | rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    throw StateError("Bitwise operations not supported for real number");
                case OperatorKind.xor:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue ^ rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    throw StateError("Bitwise operations not supported for real number");
                case OperatorKind.and:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue & rhs.intValue, 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    throw StateError("Bitwise operations not supported for real number");
                case OperatorKind.leftShift:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue << rhs.intValue.toInt(), 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    throw StateError("Bitwise operations not supported for real number");
                case OperatorKind.rightShift:
                    if (lhs.kind.isint)
                    {
                        _stack.push(StackedResult.int(
                            lhs.intValue >> rhs.intValue.toInt(), 
                            lhs.kind, lhs.node.parent));
                        break;
                    }
                    throw StateError("Bitwise operations not supported for real number");
                default:
                    throw StateError("Invalid operation");
            }    
        }
    }
}
