import '../petit/petitparser.dart';
import 'located_string.dart';
import '../source.dart';
import 'ast.dart';
import 'parser_context.dart';

extension SmashParserExtension<T> on Parser<T> {
    /// Returns a parser that discards the result of the receiver and answers
    /// the sub-string its delegate consumes.
    ///
    /// If a [message] is provided, the flatten parser can switch to a fast mode
    /// where error tracking within the receiver is suppressed and in case of a
    /// problem [message] is reported instead.
    ///
    /// For example, the parser `letter().plus().flatten()` returns `'abc'`
    /// for the input `'abc'`. In contrast, the parser `letter().plus()` would
    /// return `['a', 'b', 'c']` for the same input instead.
    Parser<LocatedString> smash2(ParserContext context, [String? message]) => SmashParser<T>(context, this, message);

}

class SmashParser<T> extends DelegateParser<T, LocatedString> 
{
    SmashParser(this._context, Parser<T> delegate, [this.message]) 
        : super(delegate);

    final ParserContext _context;

    /// Error message to indicate parse failures with.
    final String? message;

    @override
    Result<LocatedString> parseOn(Context context) 
    {
        // If we have a message we can switch to fast mode.
        if (message != null) 
        {
            final position = delegate.fastParseOn(context.buffer, context.position);
            if (position < 0) 
            {
                _context.notifyFailure(context.position, depth, message);

                return context.failure(message!);
            }

            final length = position - context.position;
            final location = SourceLocation(source: _context.source, startOffset: context.position, length: length);
            final output = LocatedString(
                string: context.buffer.substring(context.position, position), 
                location: location);
            
            return context.success(output, position);
        } 

        final result = delegate.parseOn(context);
        if (result.isSuccess) 
        {
            final length = result.position - context.position;
            final location = SourceLocation(source: _context.source, startOffset: context.position, length: length);
            final output = LocatedString(
                string: context.buffer.substring(context.position, result.position), 
                location: location);
            return result.success(output);
        }

        _context.notifyFailure(context.position, depth, message);
        return result.failure(result.message);
    }

    @override
    int fastParseOn(String buffer, int position) =>
        delegate.fastParseOn(buffer, position);

    @override
    bool hasEqualProperties(SmashParser<T> other) =>
        super.hasEqualProperties(other) &&
            message == other.message;

    @override
    SmashParser<T> copy() => SmashParser<T>(_context, delegate, message);
}
