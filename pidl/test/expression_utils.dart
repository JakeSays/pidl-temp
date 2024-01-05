import 'dart:core' as d;
import 'package:pidl/pidl.dart' as p;
import 'package:test/test.dart';
import 'package:pidl/src/stack.dart' show Stack;

enum ExprKind
{
    lit,
    unary,
    binary,
    paren,
    result,
    empty
}

class Expr
{
    ExprKind kind;
    p.LiteralKind litKind;
    p.NumberKind numberKind;
    d.BigInt ivalue;
    d.double rvalue;
    d.String svalue;
    d.bool bvalue;
    Expr? evalue;
    p.IntRadix radix;
    Expr? lhs;
    Expr? rhs;
    p.OperatorKind op;
    
    Expr({
        required this.kind,
        p.LiteralKind? litKind,
        p.NumberKind? numberKind,
        d.BigInt? ivalue,
        d.double? rvalue,
        d.String? svalue,
        d.bool? bvalue,
        this.evalue,
        this.lhs,
        this.rhs,
        p.OperatorKind? op,
        p.IntRadix? radix
    }) : litKind = litKind ?? p.LiteralKind.none,
         numberKind = numberKind ?? p.NumberKind.none,
         ivalue = ivalue ?? d.BigInt.zero,
         rvalue = rvalue ?? 0,
         svalue = svalue ?? "",
         bvalue = bvalue ?? false,
         radix = radix ?? p.IntRadix.none,
         op = op ?? p.OperatorKind.none;

    Expr operator+(Expr other) => Binary(this, other, p.OperatorKind.add);
    Expr operator-(Expr other) => Binary(this, other, p.OperatorKind.subtract);
    Expr operator*(Expr other) => Binary(this, other, p.OperatorKind.multiply);
    Expr operator/(Expr other) => Binary(this, other, p.OperatorKind.divide);
    Expr operator%(Expr other) => Binary(this, other, p.OperatorKind.modulo);
    Expr operator^(Expr other) => Binary(this, other, p.OperatorKind.xor);
    Expr operator|(Expr other) => Binary(this, other, p.OperatorKind.or);
    Expr operator&(Expr other) => Binary(this, other, p.OperatorKind.and);
    Expr operator~() => Unary(p.OperatorKind.compliment, this);
    Expr operator-() => Unary(p.OperatorKind.negate, this);
    Expr operator<<(Expr other) => Binary(this, other, p.OperatorKind.leftShift);
    Expr operator>>(Expr other) => Binary(this, other, p.OperatorKind.rightShift);
    Expr operator>>>(Expr other) => Binary(this, other, p.OperatorKind.power);

    Expr.empty()
        : kind = ExprKind.empty,
          litKind = p.LiteralKind.none,
          numberKind = p.NumberKind.none,
          ivalue = d.BigInt.zero,
          rvalue = 0,
          svalue = "",
          bvalue = false,
          radix = p.IntRadix.none,
          op = p.OperatorKind.none;

    Expr clone()
    {
        final copy = Expr(kind: kind);
        
        copy.litKind = litKind;
        copy.numberKind = numberKind;
        copy.ivalue = ivalue;
        copy.rvalue = rvalue;
        copy.svalue = svalue;
        copy.bvalue = bvalue;
        copy.evalue = evalue;
        copy.radix = radix;
        copy.lhs = lhs;
        copy.rhs = rhs;
        copy.op = op;

        return copy;
    }
}

class ResultExpr extends Expr
{
    Expr target;

    ResultExpr({
        required this.target,
        super.ivalue,
        super.rvalue
    }) : super(kind: ExprKind.result);
}

class LiteralExpr extends Expr
{
    LiteralExpr({
        required super.litKind,
        super.numberKind,
        super.ivalue,
        super.rvalue,
        super.svalue,
        super.bvalue,
        super.radix,
        super.evalue
    }) : super(kind: ExprKind.lit);
}

class UnaryExpr extends Expr
{
    UnaryExpr({
        required super.op,
        required super.rhs
    }) : super(kind: ExprKind.unary);
}

class BinaryExpr extends Expr
{
    BinaryExpr({
        required super.lhs,
        required super.op,
        required super.rhs
    }) : super(kind: ExprKind.binary);
}

Expr True() => LiteralExpr(litKind: p.LiteralKind.boolean, bvalue: true);
Expr False() => LiteralExpr(litKind: p.LiteralKind.boolean, bvalue: true);

Expr $tring(d.String value) => LiteralExpr(litKind: p.LiteralKind.string, svalue: value);
Expr Nil() => LiteralExpr(litKind: p.LiteralKind.nil);
Expr xEnum<TType extends d.Enum>(TType value) => LiteralExpr(litKind: p.LiteralKind.enumerantref, ivalue: d.BigInt.from(value.index), svalue: value.name);
Expr ERef(d.String name, d.int value, [Expr? initializer]) => LiteralExpr(litKind: p.LiteralKind.enumerantref, ivalue: d.BigInt.from(value), svalue: name, evalue: initializer);
Expr CRef(d.String name, Expr value) => Expr(kind: ExprKind.lit, litKind: p.LiteralKind.constref, svalue: name, evalue: value, numberKind: value.numberKind);
//Expr ConstRef(d.String name, Expr value) => Expr(kind: ExprKind.lit, litKind: p.LiteralKind.constref, svalue: name, evalue: value);

Expr Int8(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.int8);
Expr UInt8(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.uint8);
Expr Int16(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.int16);
Expr UInt16(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.uint16);
Expr Int32(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.int32);
Expr UInt32(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.uint32);
Expr Int64(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.int64);
Expr UInt64(d.int value) => LiteralExpr(litKind: p.LiteralKind.number, ivalue: d.BigInt.from(value), numberKind: p.NumberKind.uint64);

Expr Float32(d.double value) => LiteralExpr(litKind: p.LiteralKind.number, rvalue: value, numberKind: p.NumberKind.float32);
Expr Float64(d.double value) => LiteralExpr(litKind: p.LiteralKind.number, rvalue: value, numberKind: p.NumberKind.float64);

Expr Binary(Expr lhs, Expr rhs, p.OperatorKind op) => BinaryExpr(lhs: lhs, op: op, rhs: rhs);
Expr Unary(p.OperatorKind op, Expr rhs) => UnaryExpr(op: op, rhs: rhs);

Expr P(Expr expr) 
{
    final pexpr = expr.clone();
    pexpr.kind = ExprKind.paren;
    pexpr.op = p.OperatorKind.none;
    pexpr.lhs = expr;
    pexpr.rhs = null;
    return pexpr;
}

Expr I(d.int value, Expr expr)
{
    expr.ivalue = d.BigInt.from(value);
    return expr;
}

Expr R(d.double value, Expr expr)
{
    expr.rvalue = value;
    return expr;
}

void match(p.Expression actual, Expr expected)
{
    ExpressionMatcher().match(actual, expected);
}

extension on p.ExprValue
{
    void iexpect(d.BigInt expected) => expect(intValue, expected);
    void rexpect(d.double expected) => expect(realValue, expected);
}

class ExpressionMatcher extends p.PostfixExpressionVisitor
{
    // final Stack<p.Expression> _actual = Stack<p.Expression>();
    // final Stack<Expr> _expected = Stack<Expr>();

    late Expr _currentExpr;

    void match(p.Expression actual, Expr expected)
    {
        if (expected.kind == ExprKind.empty)
        {
            expect(actual.isempty, isTrue);
            return;
        }

        _currentExpr = expected;
        visit(actual);
    }

    @d.override
    void visitParenExpression(p.ParenExpression node)
    {
        final current = _currentExpr;
        _currentExpr = _currentExpr.lhs!;

        super.visitParenExpression(node);

        _currentExpr = current;
    }

    @d.override
    d.bool visitBinaryExpression(p.BinaryExpression node) 
    {
        final current = _currentExpr;

        _currentExpr = current.lhs!;
        visit(node.lhs);
        _currentExpr = current.rhs!;
        visit(node.rhs);

        _currentExpr = current;
        expect(true, node.operator == current.op);

        if (current.numberKind.isint)
        {
            node.computedValue!.iexpect(current.ivalue);
        }
        else
        {
            node.computedValue!.rexpect(current.rvalue);
        }

        return true;
    }

    @d.override
    d.bool visitUnaryExpression(p.UnaryExpression node) 
    {
        final current = _currentExpr;

        _currentExpr = current.rhs!;
        visit(node.expression);
        _currentExpr = current;

        expect(true, node.operator == current.op);

        if (current.numberKind.isint)
        {
            node.computedValue!.iexpect(current.ivalue);
        }
        else
        {
            node.computedValue!.rexpect(current.rvalue);
        }

        return true;
    }

    @d.override
    void visitLiteralExpr(p.LiteralExpression node) 
    {
        expect(node.kind, _currentExpr.litKind);
        switch (node.literal.kind)
        {            
            case p.LiteralKind.none:
                break;
            case p.LiteralKind.nil:
                expect(null, node.computedValue);
                break;
            case p.LiteralKind.boolean:
                expect(node.literal.value as d.bool, _currentExpr.bvalue);
                break;
            case p.LiteralKind.number:
                expect(node.literal.asNumber.kind, _currentExpr.numberKind);
                expect(node.computedValue != null, true);
                if (_currentExpr.numberKind.isint)
                {
                    expect(node.computedValue!.intValue, _currentExpr.ivalue);
                }
                else
                {
                    expect(node.computedValue!.realValue, _currentExpr.rvalue);
                }
                break;
            case p.LiteralKind.string:
                expect(node.literal.value as d.String, _currentExpr.svalue);
                break;
            case p.LiteralKind.constref:
                final target = node.literal.asConstRef.target;
                expect(target.ident.fullName, _currentExpr.svalue);
                if (_currentExpr.evalue!.numberKind.isint)
                {
                    expect(target.computedValue.intValue, _currentExpr.evalue!.ivalue);
                }
                else
                {
                    expect(target.computedValue.realValue, _currentExpr.evalue!.rvalue);
                }
                break;
            case p.LiteralKind.enumerantref:
                final target = node.literal.asEnum.target;
                expect(target.enumQualifiedName, _currentExpr.svalue);
                expect(target.computedValue.intValue, _currentExpr.ivalue);
                break;
            case p.LiteralKind.error:
                break;
        }    
    }
}