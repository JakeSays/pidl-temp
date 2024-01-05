import '../source.dart';
import 'ast.dart';
import '../petit/petitparser.dart';

class LocationBuilder
{
    static const max = 999999999999999999;

    int _start = max;
    int _end = 0;

    final SourceFile source;

    LocationBuilder({required this.source});

    SourceLocation done() => SourceLocation(source: source, startOffset: _start, length: _end - _start);

    void reset()
    {
        _start = max;
        _end = 0;
    }
    
    SourceLocation build(Object obj)
    {
        reset();
        add(obj);
        return done();
    }
    
    void addToken(Token token)
    {
        if (token.start < _start)
        {
            _start = token.start;
        }

        if (token.stop > _end)
        {
            _end = token.stop;
        }
    }

    void addLocation(SourceLocation loc)
    {
        if (loc.startOffset < _start)
        {
            _start = loc.startOffset;
        }

        if (loc.endOffset > _end)
        {
            _end = loc.endOffset;
        }
    }

    void addSyntax(SyntaxNode node) => addLocation(node.location ?? SourceLocation.invalid(source));
    
    void add(Object? thing)
    {
        if (thing == null)
        {
            return;            
        }

        if (thing is Token)
        {
            addToken(thing);
            return;
        }
        
        if (thing is LocationProvider && thing.location != null)
        {
            addLocation(thing.location!);
            return;
        }

        if (thing is List<Object?>)
        {
            addList(thing);
            return;
        }

        if (thing is List<SyntaxNode>)
        {
            addList(thing);
            return;
        }
    }

    void addList(List<Object?> things)
    {
        for(final thing in things)
        {
            add(thing);
        }
    }    
}

SourceLocation makeLocation(Object thing, SourceFile source)
{
    final loc = LocationBuilder(source: source);

    loc.add(thing);

    return loc.done();
}