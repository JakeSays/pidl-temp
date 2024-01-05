
import 'dart:math';

import '../petit/petitparser.dart';
import '../petit/reflection.dart';
import '../petit/src/debug/trace.dart';
import '../petit/src/definition/internal/reference.dart';
import '../petit/src/parser/character/lookup.dart';
import '../petit/src/parser/character/not.dart';
import '../petit/src/parser/character/uppercase.dart';
import '../petit/src/parser/character/constant.dart';

import '../console.dart';
import 'dart:mirrors';
import '../stack.dart';

extension on Parser
{
    bool get hidden
    {
        if (this is FlattenParser ||
            this is TrimmingParser ||
            this is CastParser ||
            this is CastListParser ||
            this is TokenParser ||
            this is TrimmingParser<Token<String>> ||
            this is MapParser)
        {
            return true;
        }

        return false;
    }
}

abstract class _Trace
{
    int indentLevel;
    bool success = false;
    bool hidden = false;
    String prefix;

    String get value;

    _Trace({
        required this.indentLevel,
        required this.prefix
    });

    @override
    String toString() 
    {
        final indent = success ? prefix : " ";
        return "$indentLevel: ${indent * (indentLevel * 2)}$value";
    }
}

class _Message extends _Trace
{
    String text;

    @override
    String get value => text;

    _Message({
        required super.indentLevel,
        required this.text,
        String? prefix
    }) : super(prefix: prefix ?? " ")
    {
        success = true;
    }
}

class _TraceEvent extends _Trace
{
    TraceEvent open;
    TraceEvent? close;

    @override
    bool get hidden => parser.hidden;
    String name;

    @override
    String get value => name;

    Parser get parser => open.parser;
    Result? get result => close?.result;

    _TraceEvent({
        required super.indentLevel,
        required this.open,
        required this.name
    }) : super(prefix: "-");
}

class ParserTracer
{
    final List<_Trace> _traces = [];    
    final Stack<_TraceEvent> _stack = Stack();
    int _indentLevel = 0;

    static final _typeParser = RegExp(r"Instance of '([^']+)'");
    static final _msgParser = RegExp(r'[\["]([^\["]+)[\["] expected');

    static String _parseName(Object o)
    {
        final match = _typeParser.firstMatch(o.toString());
        return match?.group(1) ?? o.toString();
    }

    String? _parseMessage(String message)
    {
        final match = _msgParser.firstMatch(message);
        return match?.group(1);
    }

    void message(String text, {int? level, String? prefix})
    {
        _traces.add(_Message(indentLevel: level ?? _indentLevel, text: text, prefix: prefix));
    }

    void trace(TraceEvent evt)
    {
        if (evt.result != null)
        {
            close(evt);
            return;
        }

        open(evt);
    }

    void open(TraceEvent evt)
    {
        final name = parserName(evt.parser);
        final trace = _TraceEvent(
            indentLevel: evt.parser.hidden ? _indentLevel : _indentLevel++, 
            open: evt, 
            name: name);
        _traces.add(trace);
        _stack.push(trace);
    }

    void close(TraceEvent evt)
    {        
        final trace = _stack.pop();
        if (!trace.hidden)
        {
            _indentLevel -= 1;
        }
        trace.close = evt;
        trace.success = evt.result?.isSuccess ?? false;
    }

    void dump()
    {
        for(final trace in _traces.where((element) => !element.hidden))
        {
            print(trace.toString());
        }
    }

    // bool isHidden(Parser parser)
    // {
    //     if (parser is FlattenParser ||
    //         parser is TrimmingParser ||
    //         parser is CastParser ||
    //         parser is CastListParser)
    //     {
    //         return true;
    //     }

    //     return false;
    // }

    String _predicate(Object pred)
    {
        if (pred is Function)
        {
            return _functionName(pred);
        }
        if (pred is ConstantCharPredicate)
        {
            return pred.constant ? "TRUE" : "FALSE";
        }
        if (pred is WordCharPredicate)
        {
            return "word";
        }
        if (pred is WhitespaceCharPredicate)
        {
            return "whitespace";
        }
        if (pred is SingleCharPredicate)
        {
            return "char('${pred.toString()}')";
        }
        if (pred is DigitCharPredicate)
        {
            return "digit";
        }
        if (pred is LetterCharPredicate)
        {
            return "letter";
        }
        if (pred is LookupCharPredicate)
        {
            return formatRange(pred.start, pred.stop);
        }
        if (pred is LowercaseCharPredicate)
        {
            return "lowercase";
        }
        if (pred is UppercaseCharPredicate)
        {
            return "uppercase";
        }
        if (pred is NotCharacterPredicate)
        {
            return _predicate(pred.predicate);
        }        
        
        return _parseName(pred);
    }

    String formatRange(int min, int max) => "[$min..$max}]";

    String characterParser(CharacterParser p)
    {
        final pred = _predicate(p.predicate);
        final prefix = p.message.startsWith("none of")
            ? "noneof "
            : p.message.startsWith("any of")
                ? "anyof"
                : "";

        final suffix = _parseMessage(p.message);
        return "$prefix$pred $suffix";
    }

    String parserName(Parser p)
    {
        if (p.name != null)
        {
            return p.name!;
        }

        if (p is TokenParser)
        {
            return parserName(p.delegate);
        }

        if (p is FlattenParser)
        {
            return parserName(p.delegate);
        }        
        if (p is LabelParser)
        {
            return "${p.label}:: ${parserName(p.delegate)}";
        }
        if (p is EndOfInputParser)
        {
            return "END";            
        }
        if (p is EpsilonParser)
        {
            return "epsilon";
        }
        if (p is AndParser)
        {
            return "and ${parserName(p.delegate)}";
        }
        if (p is ContinuationParser)
        {
            return parserName(p.delegate);
        }
        if (p is MapParser)
        {
            return "map:";
        }
        if (p is NotParser)
        {
            final prefix = p.message.startsWith("Success not")
                ? "not"
                : "neg";

            return "$prefix ${parserName(p.delegate)}";
        }
        if (p is ChoiceParser)
        {
            return formatList(p.children, "|");
        }
        if (p is SequenceParser)
        {
            return formatList(p.children, "&");
        }        
        if (p is OptionalParser)
        {
            final target = parserName(p.delegate);
            return "$target?";
        }
        if (p is CharacterParser)
        {
            return characterParser(p);
        }
        if (p is PredicateParser)
        {
            return _parseMessage(p.message) ?? "<PredicateParser>";
        }
        if (p is PossessiveRepeatingParser)
        {
            if (p.min == 0 && p.max == unbounded)
            {
                return "star";
            }
            if (p.min == 1 && p.max == unbounded)
            {
                return "plus";
            }
            return "repeat ${formatRange(p.min, p.max)}";
        }
        
        return _parseName(p);
    }

    String formatList(List<Parser> parsers, String separator)
    {
        final names = parsers.map((p) => parserName(p))
            .join(" $separator ");
        return names;
    }

    String _formatParser(Parser parser)
    {
        final buffer = StringBuffer();

        return buffer.toString();
    }

    static String _functionName(Function function)
    {
        String name(InstanceMirror m)
        {
            Symbol? s;
            if (m is FunctionTypeMirror)
            {
                s = (m as FunctionTypeMirror).simpleName;
            }
            else if (m is ClosureMirror)
            {
                s = m.function.simpleName;
            }
            else if (m is MethodMirror)
            {
                s = (m as MethodMirror).simpleName;
            }

            return s != null
                ? MirrorSystem.getName(s)
                : "<unknown>";
        }

        final i = reflect(function);
        final n = name(i);
        return n;
    }
}