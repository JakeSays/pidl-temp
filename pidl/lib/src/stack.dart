class Stack<TElement>
{
    final _storage = <TElement>[];

    void push(TElement value) => _storage.add(value);
    
    TElement pop()
    {
        final value = _storage.last;
        _storage.removeLast();
        return value;
    }

    TElement get top => _storage.last;
    TElement peek() => _storage.last;

    void clear() => _storage.clear();
    
    int get count => _storage.length;

    bool get isEmpty => _storage.isEmpty;
    bool get isNotEmpty => _storage.isNotEmpty;

    Iterable<TElement> get items => _storage;

    @override
    String toString() => count.toString();
}
