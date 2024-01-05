import 'package:pidl/src/source.dart';
import 'package:pidl/src/types.dart';

import 'parsing/ast.dart';
import 'issue_code.dart';

enum IssueSeverity
{
    info,
    warning,
    error
}

abstract class Issue
{
    final IssueCode code;
    final IssueSeverity severity;
    final String message;
    final String? details;
    final String type;

    SourceLocation? location;

    Issue({
        required this.code,
        required this.severity,
        required this.type,
        String? message,
        this.details,
        this.location
    }) : message = message ?? code.message;
}

class EvaluateIssue extends Issue
{
    Expression target;
    List<Definition> related;

    EvaluateIssue({
        required super.code,
        required super.severity,
        required this.target,
        super.message,
        super.details,
        List<Definition>? related,
        super.location
    }) : related = related ?? [],
         super(type: "eval") 
    {
        location ??= target.location;
    }
}

class ExceptionIssue extends Issue
{
    final Exception exception;

    ExceptionIssue({
        required this.exception,
        super.severity = IssueSeverity.error,
        super.code = IssueCode.exception,
        super.message,
        super.details,
        super.location
    }) : super(type: "except");
}

class SemanticIssue extends Issue
{
    final List<SyntaxNode> related;
    final LocationProvider? target;

    SemanticIssue({
        required super.code,
        required super.severity,
        super.message,
        super.details,
        this.target,
        List<SyntaxNode>? related,
        super.location
    }) : related = related ?? [],
         super(type: "sema")
    {
        location ??= target?.location;
    }
}

class ParseIssue extends Issue
{
    SyntaxNode? lastSuccessfulNode;
    ParseFailure? deepestFailure;

    ParseIssue({
        required super.code,
        required super.severity,
        this.lastSuccessfulNode,
        this.deepestFailure,
        super.location,
        super.message,
        super.details
    }) : super(type: "parse");
}