import '../petit/petitparser.dart';
import '../petit/reflection.dart';
import '../petit/src/debug/trace.dart';
import '../petit/src/definition/internal/reference.dart';
import '../petit/src/parser/character/lookup.dart';
import '../petit/src/parser/character/not.dart';
//import 'package:petitparser/src/parser/character/uppercase.dart';
import '../petit/src/parser/character/constant.dart';
import 'dart:mirrors';

extension ParserNameExt on Parser
{
    String makeName() => ParserName.makeParserName(this);
}

class ParserName
{
    static final _typeParser = RegExp(r"Instance of '([^']+)'");
    static final _msgParser = RegExp(r'[\["]([^\["]+)[\["] expected');

    static String makeParserName(Parser parser) => _parserName(parser);

    static String _parseName(Object o)
    {
        final match = _typeParser.firstMatch(o.toString());
        return match?.group(1) ?? o.toString();
    }

    static String? _parseMessage(String message)
    {
        final match = _msgParser.firstMatch(message);
        return match?.group(1);
    }


    static String _predicate(Object pred)
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

    static String formatRange(int min, int max) => "[$min..$max}]";

    static String characterParser(CharacterParser p)
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

    static String _parserName(Parser p)
    {
        if (p.name != null)
        {
            return p.name!;
        }

        if (p is TokenParser)
        {
            return _parserName(p.delegate);
        }

        if (p is FlattenParser)
        {
            return _parserName(p.delegate);
        }        
        if (p is LabelParser)
        {
            return "${p.label}:: ${_parserName(p.delegate)}";
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
            return "and ${_parserName(p.delegate)}";
        }
        if (p is ContinuationParser)
        {
            return _parserName(p.delegate);
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

            return "$prefix ${_parserName(p.delegate)}";
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
            final target = _parserName(p.delegate);
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

    static String formatList(List<Parser> parsers, String separator)
    {
        final names = parsers.map((p) => _parserName(p))
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