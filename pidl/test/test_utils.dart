import 'dart:math';

import 'package:pidl/pidl.dart';
import 'package:pidl/src/ansiconsole.dart';
import 'package:pidl/src/console.dart';
import 'package:pidl/src/parsing/parser_configuration.dart';
import 'package:test/test.dart';
import 'expression_utils.dart';
import 'package:darq/darq.dart';

class Failure extends Error
{
    int testId;
    final String reason;
    final Definition node;

    Failure({
        required this.node, 
        required this.reason,
        this.testId = -1
    });
}

typedef Selector<TValue> = TValue Function(Object item);

abstract class TypedMatcher<TValue> extends CustomMatcher
{
    final Selector? selector;

    TypedMatcher(String name, String description, Object? matcherOrValue, [Selector? selector])
        : selector = selector,
          super(description, name, matcherOrValue);

    @override
    Object? featureValueOf(actual) 
    {
        if (actual is! Object)
        {
            fail("'actual' must be a real thing");
        }

        if (selector != null)
        {
            return selector!(actual);
        }
        return actual;
    }
}

class IdentIs extends CustomMatcher
{
    final Selector<Identifier> selector;

    IdentIs(Object? matcherOrValue, Selector<Identifier> selector, [String? name])
        : selector = selector,
          super("Matches an identifier", name ?? "IdentIs", matcherOrValue);

    @override
    Object? featureValueOf(actual) 
    {
        if (actual is! Object)
        {
            fail("'actual' must be a real thing");
        }

        return selector(actual).fullName;
    }
}

class DefnIdentIs extends IdentIs
{
    DefnIdentIs(String expected)
        : super(expected, (o) => (o as NamedDefinition).ident, "DefnIdentIs");
}

class TypeIs extends CustomMatcher
{
    TypeIs(String? type)
        : super("Matches a type", "TypeIs", type);

    static String? _getName(Object? type)
    {
        if (type == null)
        {
            return null;
        }
        if (type is Enum)
        {
            return type.dataType.toString();
        }
        if (type is Parameter)
        {
            return type.type.toString();
        }
        if (type is Method)
        {
            return type.returnType.name.toString();
        }
        if (type is TypeReference)
        {
            return type.toString();
        }
        if (type is TypeDefinition)
        {
            return type.ident.fullName;
        }
        if (type is String)
        {
            return type;
        }
        return "<unknown type name>";
    }

    @override
    Object? featureValueOf(actual) 
    {
        return _getName(actual);
    }
}

class MultipleSourceProvider implements SourceCodeProvider
{
    final Map<String, SourceFile> sources = {};

    MultipleSourceProvider({
        required Map<String, String> files
    })
    {
        for(final file in files.entries)
        {
            final path = file.key;
            final content = file.value;

            sources[path] = SourceFile(path: path, content: content);
        }
    }

    @override
    SourceFile? loadImport(String path) => sources[path];

    @override
    SourceFile? loadMainFile(String path) => sources[path];

    @override
    String normalizePath(String path) => path;
}

class SingleSourceProvider implements SourceCodeProvider
{
    final SourceFile file;

    SingleSourceProvider({
        required String content
    }) : file = SourceFile(path: "main.idl", content: content);

    @override
    SourceFile? loadMainFile(String path) => file;

    @override
    SourceFile? loadImport(String path) => throw UnimplementedError();

    @override
    String normalizePath(String path) => path;
}

CompileResult compile(String source, [bool traceParse = false, bool displayIssues = false])
{
    try
    {    
        final parseConfig = ParserConfiguration();
        parseConfig.enableTracingParser = traceParse;

        final diag = Diagnostics();
        final comp = IdlCompiler(
            diagnostics: diag, 
            sourceProvider: SingleSourceProvider(content: source),
            parserConfiguration: parseConfig);

        final result = comp.compileFile("main.idl");
        if (displayIssues && (result == null || diag.hasIssues))
        {
            diag.displayIssues();
        }

        expect(diag.hasErrors, isFalse);
        expect(result, isNotNull);

        return result!;
    }
    finally
    {
        writeln();
    }
}

void frob()
{
    
    redln("main.idl:1:8: ERROR: (parse) { expected");
    blueln("enum E a}");
    blueln("       ^");
    redln("main.idl:1:1: ERROR: (parse) end of input expected");
    blueln("enum E a}");
    blueln("^");
    yellowln("Closest to:");
    blueln("enum E a}");
    blueln("     ^");  
// print("""\x1B[38;5;1mmain.idl:1:8: \x1B[38;5;1mERROR: (parse) { expected
// \x1B[38;5;4menum E a}
// \x1B[38;5;4m       ^
// \x1B[38;5;1mmain.idl:1:1: \x1B[38;5;1mERROR: (parse) end of input expected
// \x1B[38;5;4menum E a}
// \x1B[38;5;4m^
// \x1B[38;5;3mClosest to:
// \x1B[38;5;4menum E a}
// \x1B[38;5;4m     ^""");
//     expect(true, true);
}

void compileFail(String source, [List<Issue>? issues, bool traceParse = false, bool displayIssues = false])
{
    try 
    {
        final parseConfig = ParserConfiguration();
        parseConfig.enableTracingParser = traceParse;

        final diag = Diagnostics();
        final comp = IdlCompiler(
            diagnostics: diag, 
            sourceProvider: SingleSourceProvider(content: source),
            parserConfiguration: parseConfig);

        final result = comp.compileFile("main.idl");
        expect(diag.hasErrors, isTrue);
        expect(result, isNull);

        if (displayIssues)
        {
            diag.displayIssues();
        }

        if (issues == null)
        {
            return;
        }

        for (final expected in issues)
        {
            var found = false;
            for (final actual in diag.issues)
            {
                if (actual.code == expected.code &&
                    actual.severity == expected.severity)
                {
                    if (expected.message.isNotEmpty && expected.message == actual.message)
                    {
                        found = true;
                        break;
                    }
                }
            }

            if (!found)
            {
                fail("Expected issue '${expected.code.name}', ${expected.severity.name}, '${expected.message}'");
            }
        }      
    }
    finally
    {
        writeln();
    }
}

void evaluateExpr(List<String> sources, NumberKind type, Expr expected)
{
    final content = StringBuffer();
    var constIdx = 0;
    for (final source in sources)
    {
        content.writeln("const ${type.name} c${++constIdx} = $source;");
    }

    final targetConst = "c$constIdx";

    final result = compile(content.toString());
    
    final actual = result.mainFile.constants.where((c) => c.ident.name == targetConst).first.initializer;
    
    match(actual, expected);
}

class FieldT
{
    String name;
    String type;
    Expr initializer;

    FieldT(this.name, this.type, [Expr? initializer])
        : initializer = initializer ?? Expr.empty();
}

class StructT
{
    String name;
    String? baseType;

    List<FieldT> fields;

    StructT(this.name, [List<FieldT>? fields, this.baseType])
        : fields = fields ?? [];
}

class ParamT
{
    String name;
    String type;
    Expr initializer;

    ParamT(this.name, this.type, [Expr? initializer])
        : initializer = initializer ?? Expr.empty();
}

class MethodT
{
    String name;
    String type;

    List<ParamT> params;

    MethodT(this.name, this.type, [List<ParamT>? params])
        : params = params ?? [];
}

class InterfaceT
{
    String name;
    List<String> baseTypes;
    List<MethodT> methods;

    InterfaceT(this.name, [List<String>? baseTypes, List<MethodT>? methods])
        : baseTypes = baseTypes ?? [],
          methods = methods ?? [];
}

class EnumerantT
{
    String name;
    BigInt value;
    Expr initializer;

    EnumerantT(this.name, int value, [Expr? initializer])
        : value = BigInt.from(value),
          initializer = initializer ?? Expr.empty();
}

class EnumT
{
    String name;
    String? baseType;

    List<EnumerantT> enumerants;

    EnumT(this.name, [List<EnumerantT>? enumerants, String? baseType])
        : enumerants = enumerants ?? [],
          baseType = baseType ?? "int32";
}

StructT struct(String name, [List<FieldT>? fields, String? baseType])
{
    return StructT(name, fields, baseType);
}

FieldT field(String name, String type, [Expr? initializer])
{
    return FieldT(name, type, initializer);
}

ParamT param(String name, String type, [Expr? initializer])
{
    return ParamT(name, type, initializer);
}

MethodT method(String name, String type, [List<ParamT>? params])
{
    return MethodT(name, type, params);
}

InterfaceT interface(String name, [List<MethodT>? methods, List<String>? baseTypes])
{
    return InterfaceT(name, baseTypes, methods);
}

EnumerantT rant(String name, int value, [Expr? initializer])
{
    return EnumerantT(name, value, initializer);
}

EnumT mune(String name, [List<EnumerantT>? enumerants, String? baseType])
{
    return EnumT(name, enumerants, baseType);
}

void evaluateField(FieldT expected, Field actual)
{
    expect(actual, DefnIdentIs(expected.name));
    expect(actual.type, TypeIs(expected.type));
    match(actual.initializer, expected.initializer);
}

void evaluateStruct(String source, StructT expected, [bool enableTrace = false])
{
    final result = compile(source, enableTrace);

    final actual = result.mainFile.structs.where((s) => s.ident.name == expected.name).firstOrDefault();
    expect(actual, isNotNull);
    expect(actual, DefnIdentIs(expected.name));
    expect(actual!.base, TypeIs(expected.baseType));
    expect(actual.fields.length, equals(expected.fields.length));

    for (var fieldIdx = 0; fieldIdx < expected.fields.length; fieldIdx++)
    {
        evaluateField(expected.fields[fieldIdx], actual.fields[fieldIdx]);
    }
}

void evaluateParam(ParamT expected, Parameter actual)
{
    expect(actual, DefnIdentIs(expected.name));
    expect(actual, TypeIs(expected.type));
    match(actual.initializer, expected.initializer);
}

void evaluateMethod(MethodT expected, Method actual)
{
    expect(actual, DefnIdentIs(expected.name));
    expect(actual, TypeIs(expected.type));

    for (var paramIdx = 0; paramIdx < expected.params.length; paramIdx++)
    {
        evaluateParam(expected.params[paramIdx], actual.parameters[paramIdx]);
    }
}

void evaluateInterface(String source, InterfaceT expected, [bool enableTrace = false])
{
    final result = compile(source, enableTrace);

    final actual = result.mainFile.interfaces.where((s) => s.ident.name == expected.name).firstOrDefault();
    expect(actual, isNotNull);
    expect(actual, DefnIdentIs(expected.name));

    expect(actual!.bases.length, equals(expected.baseTypes.length));

    for (var baseIdx = 0; baseIdx < expected.baseTypes.length; baseIdx++)
    {
        expect(actual.bases[baseIdx], TypeIs(expected.baseTypes[baseIdx]));
    }

    expect(actual.methods.length, equals(expected.methods.length));

    for (var methodIdx = 0; methodIdx < expected.methods.length; methodIdx++)
    {
        evaluateMethod(expected.methods[methodIdx], actual.methods[methodIdx]);
    }
}

void evaluateEnumerant(EnumerantT expected, Enumerant actual)
{
    expect(actual, DefnIdentIs(expected.name));
    expect(expected.value, actual.computedValue.intValue);    
    match(actual.initializer, expected.initializer);
}

void evaluateEnum(String source, EnumT expected, [bool enableTrace = false])
{
    final result = compile(source, enableTrace);
    final actual = result.mainFile.enumerations.where((s) => s.ident.name == expected.name).firstOrDefault();
    expect(actual, isNotNull);
    
    expect(actual, DefnIdentIs(expected.name));
    expect(actual, TypeIs(expected.baseType));
    expect(actual!.enumerants.length, equals(expected.enumerants.length));
    
    for(var index = 0; index < expected.enumerants.length; index++)
    {
        evaluateEnumerant(expected.enumerants[index], actual.enumerants[index]);
    }
}