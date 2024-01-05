import 'dart:mirrors';
import '../../core/parser.dart';

String makename(Parser parser, Function function)
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

    if (parser.name == null)
    {
        final i = reflect(function);
        final n = name(i);

        return n;
    }

    return parser.name!;
}