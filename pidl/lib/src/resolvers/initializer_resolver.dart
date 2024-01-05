import '../parsing/ast.dart';
import '../types.dart';
import 'expression_builder.dart';
import '../expression_evaluator.dart';
import '../diagnostics.dart';
import '../type_scope.dart';

class InitializerValue
{
    Expression expression;
    ExprValue computedValue;
    Literal? literal;

    InitializerValue({
        required this.expression
    }) : computedValue = ExprValue.none();
}


class InitializerResolver
{
    final Diagnostics diagnostics;
    final TypeScope scope;
    final ExpressionBuilder _builder;
    final ExpressionEvaluator _evaluator;
    late TypeReference _expressionTypeReference;
    late TypeDefinition _expressionType;

    InitializerResolver({
        required this.diagnostics,
        required this.scope
    }) : _builder = ExpressionBuilder(diagnostics: diagnostics, scope: scope),
         _evaluator = ExpressionEvaluator();

    InitializerValue? build(
        InitializedSyntax node,
        TypeReference expressionType,
        TypeReferenceSyntax expressionTypeSyntax,
        [Enumerant? Function(IdentifierSyntax ident)? enumerantResolver])
    {
        if (node.initializer.value.isEmpty)
        {
            return null;
        }

        if (expressionType.target is! BuiltinTypeDefinition &&
            expressionType.target is! Enum &&
            expressionType.target is! Constant)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidInitializer,
                severity: IssueSeverity.error,
                related: [node], 
                target: node.initializer));
            return null;
        }
        _expressionType = expressionType.target;
        _expressionTypeReference = expressionType;

        final expr = _builder.build(node.initializer, expressionType, expressionTypeSyntax, enumerantResolver);

        final result = InitializerValue(expression: expr);
        final literal = _getNonEvalLiteral(expr);
        if (literal != null)
        {
            result.literal = literal;
            return result;
        }

        final value = _evaluator.evaluate(diagnostics, expr);
        if (value == null)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidInitializer,
                severity: IssueSeverity.error,
                related: [node], 
                target: node.initializer));
            return result;
        }

        result.computedValue = value;
        result.literal = _makeLiteral(expr, value);
        return result;
    }

    Literal? _getNonEvalLiteral(Expression expr)
    {
        if (expr is LiteralExpression)
        {
            final lit = expr.literal;
            if (lit.kind == LiteralKind.boolean ||
                lit.kind == LiteralKind.enumerantref ||
                lit.kind == LiteralKind.nil ||
                lit.kind == LiteralKind.nil)
            {
                return lit;
            }
        }

        return null;
    }

    Literal _makeLiteral(Expression expr, ExprValue value)
    {
        if (expr is AssignmentExpression)
        {
            expr = expr.valueExpression;
        }
        
        if (expr is LiteralExpression) 
        {
            final lit = (expr).literal;
            if (lit.kind == LiteralKind.constref ||
                lit.kind == LiteralKind.enumerantref)
            {
                return lit;
            }
        }

        final type = _expressionType as BuiltinTypeDefinition;

        final loc = expr.location;
        if (value.isreal)
        {
            final number = Number(
                value: value.realValue, 
                kind: type.numberKind, 
                radix: IntRadix.none, 
                scale: NumberScale.none, 
                type: _expressionTypeReference);

            return Literal.number(number, _expressionTypeReference, loc);
        }

        final radix = IntRadix.decimal;

        final number = Number(
            value: value.intValue, 
            kind: type.numberKind, 
            radix: radix, 
            scale: NumberScale.none, 
            type: _expressionTypeReference);

        return Literal.number(number, _expressionTypeReference, loc);
    }
}