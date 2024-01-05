import '../petit/petitparser.dart';
import '../source.dart';
import 'ast.dart';
import 'parser_context.dart';

extension TokenSyntaxParserExtesion<T> on Parser<T>
{
    Parser<TokenSyntax> asToken(ParserContext context, [String? message]) => TokenSyntaxParser(context, this, message);
}

class TokenSyntaxParser<T> extends DelegateParser<T, TokenSyntax> 
{
    TokenSyntaxParser(this.context, Parser<T> delegate, [this.message]) 
        : super(delegate);

    SourceFile get source => context.source;
    final ParserContext context;

    /// Error message to indicate parse failures with.
    final String? message;

    // int _myDepth = -1;
    
    // @override
    // int get depth => delegate.depth;
    // @override
    // set depth(int depth) => _myDepth = depth;

    @override
    Result<TokenSyntax> parseOn(Context context) 
    {
        // If we have a message we can switch to fast mode.
        if (message != null) 
        {
            final position = delegate.fastParseOn(context.buffer, context.position);
            if (position < 0) 
            {
//                this.context.notifyFailure(context.position, depth, message);
                return context.failure(message!);
            }

            final length = position - context.position;
            final location = SourceLocation(source: source, startOffset: context.position, length: length);
            final output = TokenSyntax(
                token: context.buffer.substring(context.position, position), 
                location: location);
            output.parseDepth = depth;
            this.context.lastSuccessfulNode = output;
            return context.success(output, position);
        } 

        final result = delegate.parseOn(context);
        if (result.isSuccess) 
        {
            int startPos;
            int length;
            String input;
            if (result.value is String)
            {
                startPos = context.position;
                input = result.value as String;
                length = input.length;
            }
            else
            {
                final sresult = (result as Success).value as Token;
                startPos = sresult.start;
                length = sresult.length;
                input = sresult.input;
            }
            final location = SourceLocation(source: source, startOffset: startPos, length: length);
            final output = TokenSyntax(
                token: input, 
                location: location);
            output.parseDepth = depth;
            return result.success(output);
        }
        
//        this.context.notifyFailure(context.position, depth, result.message);

        return result.failure(result.message);
    }

    @override
    int fastParseOn(String buffer, int position) =>
        delegate.fastParseOn(buffer, position);

    @override
    bool hasEqualProperties(TokenSyntaxParser<T> other) =>
        super.hasEqualProperties(other) &&
            source == other.source &&
            message == other.message;

    @override
    TokenSyntaxParser<T> copy() => TokenSyntaxParser<T>(context, delegate, message);
}
