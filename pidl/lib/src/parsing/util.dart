import 'token_syntax_parser.dart';
import '../petit/petitparser.dart';
import '../source.dart';
import 'ast.dart';
import 'reduction_parser.dart';

class ParserInfo
{
    final Parser parser;
    final int depth;

    ParserInfo({
        required this.parser,
        required this.depth
    });
}

class IdlParserIterable extends Iterable<ParserInfo>
{
    IdlParserIterable(this.root);

    final Parser root;

    @override
    Iterator<ParserInfo> get iterator => IdlParserIterator(root);
}

class IdlParserIterator implements Iterator<ParserInfo> 
{
    IdlParserIterator(Parser root)
        : todo = [ParserInfo(parser: _resolve(root), depth: 0)],
            seen = {root};

    final List<ParserInfo> todo;
    final Set<Parser> seen;

    @override
    late ParserInfo current;

    static Parser _resolve(Parser parser)
    {
        // if (parser is CastParser)
        // {
        //     return parser.children[0];
        // }
        return parser;
    }

    @override
    bool moveNext() 
    {
        if (todo.isEmpty) 
        {
            seen.clear();
            return false;
        }
        current = todo.removeLast();
        current.parser.depth = current.depth;
        var depth = current.depth;
        for (var parser in current.parser.children.reversed.map((e) => _resolve(e))) 
        {
            parser.depth = depth + 1;
            if (seen.add(parser)) 
            {
                todo.add(ParserInfo(parser: parser, depth: depth + 1));
            }
        }
        return true;
    }
}

SourceLocation? delete_joinNodeLocations(Iterable<SyntaxNode?> nodes)
{
    //wtf!
    const max = 999999999999999999;
    int start = max;
    int end = 0;

    SourceFile? source;

    for (final node in nodes.where((n) => n != null && n.location != null))
    {
        source ??= node!.location!.source;

        if (node!.location!.startOffset < start)
        {
            start = node.location!.startOffset;
        }

        if (node.location!.endOffset > end)
        {
            end = node.location!.endOffset;
        }
    }

    if (source == null)
    {
        return null;
    }

    return SourceLocation(source: source, startOffset: start, length: end - start);
}

// extension TokenExtension on Token
// {
//     SourceLocation location(SourceFile source) =>
//         SourceLocation(source: source, startOffset: start, length: length);
// }
