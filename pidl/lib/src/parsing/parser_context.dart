import '../source.dart';
import 'ast.dart';

abstract class ParserContext
{
    SourceFile get source;
    SyntaxNode? lastSuccessfulNode;
    ParseFailure? get deepestFailure;

    void notifyFailure(int position, int depth, [String? message]);
}
