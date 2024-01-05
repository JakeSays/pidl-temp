import 'ast.dart';

abstract class Thingerator<TThing>
{
    final Iterator<TThing?> _it;
    final List<TThing?> things;

    int get count => things.length;

    bool get done => !_haveMore;
    
    TThing get nullValue;

    TThing get current => (_it.current ?? nullValue);

    TThing? operator [](int index)
    {
        if (index < 0)
        {
            throw ArgumentError.value(index, "index");
        }

        if (index >= count)
        {
            return null;
        }

        return things[index];
    }

    TThing next()
    {
        if (!(_haveMore = _it.moveNext()))
        {
            return nullValue;
        }

        return current;
    }

    KeywordSyntax keyword() => takeAs<KeywordSyntax>();
    KeywordSyntax? keywordOpt() => takeIf<KeywordSyntax>();
    TokenSyntax token() => takeAs<TokenSyntax>();
    TokenSyntax? tokenOpt() => takeIf<TokenSyntax>();
    String string() => takeAs<String>();
    
    TThing take()
    {
        final node = current;
        _haveMore = _it.moveNext();
        return node;
    }

    TAs? at<TAs>(int index)
    {
        return this[index] as TAs?;
    }

    List<TAs> filterRestAs<TAs>()
    {
        if (!_haveMore)
        {
            return [];
        }

        final all = <TAs>[];
        if (_it.current is TAs)
        {
            all.add(_it.current as TAs);
        }
        while ((_haveMore = _it.moveNext()))
        {
            if (_it.current is TAs)
            {
                all.add(_it.current as TAs);
            }
        }
        return all;
    }

    List<TAs> takeAllAs<TAs>()
    {
        if (!_haveMore)
        {
            return [];
        }

        final all = <TAs>[];
        all.add(_it.current as TAs);
        while ((_haveMore = _it.moveNext()))
        {
            all.add(_it.current as TAs);
        }
        return all;
    }

    List<TAs> takeRestAs<TAs>() => takeAllAs<TAs>();

    TAs takeAs<TAs>({int? skipOver})
    {
        var count = skipOver ?? 0;
        while (count-- > 0)
        {
            if (!(_haveMore = _it.moveNext()))
            {
                break;
            }
        }

        final node = current;
        _haveMore = _it.moveNext();
        return node as TAs;
    }

    TNode? takeIf<TNode>()
    {
        if (done || current is! TNode)
        {
            return null;
        }

        final node = current as TNode;
        _haveMore = _it.moveNext();
        return node;
    }

    Thingerator(this.things)
        : _it = things.iterator
    {
        _haveMore = _it.moveNext();
    }

    late bool _haveMore;
}

class Noderator extends Thingerator<SyntaxNode>
{
    Noderator(super.nodes);

    @override
    SyntaxNode get nullValue => SyntaxNode.nil;
}

class Objecterator extends Thingerator<Object>
{
    Objecterator(super.nodes);

    @override
    Object get nullValue => Object();
}
