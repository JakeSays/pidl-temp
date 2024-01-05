import '../petit/petitparser.dart';
//import '../petit/src/shared/types.dart';
// import '../petit/src/definition/internal/reference.dart';
import 'ast.dart';
// import 'util.dart';
import '../source.dart';
import 'thingerator.dart';
//import 'located_string.dart';
import 'location_builder.dart';

import 'parser_context.dart';

typedef Reducer<TReturn> = TReturn Function(SourceLocation location, Objecterator nodes);

extension ParserExtensions on Parser
{
    Parser reduce(ParserContext context, Reducer reducer, {String? message})
    {
        return ReductionParser(context, this, reducer, message);
    }

    Parser<TReturn> reduceAs<TReturn>(ParserContext context, Reducer<TReturn> reducer, {String? message})
    {
        return ReductionParser(context, this, reducer, message);
    }    

    Parser reduceKeyword(ParserContext context, Object Function(KeywordSyntax? keyword) callback, {String? message})
    {        
        return ReductionParser(context, this, (location, nodes) 
        {
            final keyword = nodes.takeIf<KeywordSyntax>();
            return callback(keyword);
        }, message);
    }

    Parser forward(ParserContext context)
    {
        return ReductionParser(context, this, null);
    }

    Parser error(ParserContext context, [String? text])
    {
        return ErrorParser(context, this, text);
    }
}

class ReductionParser<TIn, TReturn> extends DelegateParser<TIn, TReturn> 
{
    final ParserContext _context;
    final LocationBuilder _locationBuilder;

    ReductionParser(this._context, Parser<TIn> delegate, this.reducer, [this.message]) 
        : _locationBuilder = LocationBuilder(source: _context.source),
          super(delegate);

    final Reducer<TReturn>? reducer;
    final String? message;

    // int _myDepth = -1;

    // @override
    // int get depth => delegate.depth;
    // @override
    // set depth(int depth) => _myDepth = depth;

    @override
    Result<TReturn> parseOn(Context context) 
    {
        final result = delegate.parseOn(context);
        if (result.isSuccess) 
        {
            return _success(result);
        }
        else 
        {
//            _context.notifyFailure(context.position, depth, result.message);
            return result.failure(result.message);
        }
    }

    Result<TReturn> _success(Result<TIn> result)
    {
        if (reducer == null)
        {
            if (result.value is SyntaxNode)
            {
                (result.value as SyntaxNode).parseDepth = depth;
            }
            return result.success(result.value as TReturn);
        }

        _locationBuilder.reset();
        final values = _flatten(result.value);
        final location = _locationBuilder.build(values);
        final erator = Objecterator(values);

        final reducedResult = reducer!(location, erator);
        if (reducedResult is SyntaxNode)
        {
            reducedResult.parseDepth = depth;
            _context.lastSuccessfulNode = reducedResult;
        }

        return result.success(reducedResult);
    }

    @override
    bool hasEqualProperties(ReductionParser<TIn, TReturn> other) =>
        super.hasEqualProperties(other) && reducer == other.reducer;

    @override
    ReductionParser<TIn, TReturn> copy() => ReductionParser<TIn, TReturn>(_context, delegate, reducer);

    List<Object> _flatten(dynamic root)
    {
        Iterable<Object> flattenThing(dynamic thing) sync*
        {
            if (thing == null)
            {
                return;
            }

            if (thing is List)
            {
                for (final outer in thing)   
                {
                    if (outer is List)
                    {
                        yield* flattenThing(outer);
                        continue;
                    }
                    if (outer != null)
                    {
                        yield outer as Object;
                    }
                }
                return;
            }

            if (thing != null && thing is! List)
            {
                yield thing as Object;
            }
        }

        return flattenThing(root).toList();
    }
}

class ErrorParser extends DelegateParser
{
    final ParserContext _context;

    ErrorParser(this._context, Parser delegate, [this.message]) 
        : super(delegate);

    final String? message;

    @override
    Result parseOn(Context context) 
    {
        final result = delegate.parseOn(context);
        if (result.isSuccess) 
        {
            return result;
        }
        else 
        {
            _context.notifyFailure(context.position, depth, message ?? result.message);
            return result.failure(message ?? result.message);
        }
    }

    @override
    bool hasEqualProperties(ErrorParser other) =>
        super.hasEqualProperties(other);

    @override
    ErrorParser copy() => ErrorParser(_context, delegate);
}
