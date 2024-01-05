import 'package:pidl/pidl.dart';
import 'dart_file_generator.dart';
import '../code_writer.dart';
import 'dart_writer.dart';
import 'dart_extensions.dart';

class DartInterfaceGenerator extends DartFileGenerator
{
    _StubGenerator? _stub;
    _ProxyGenerator? _proxy;

    DartInterfaceGenerator({
        required super.options,
        required super.diagnostics,
        required WriterConfig config,
    }) : super(code: DartCodeWriter(config: config));

    @override
    OutputInfo get output => currentUnit.dartOutput.interfaces;

    @override
    void beginCompilationUnit()
    {
        writeHeader("interface proxies and services");
    
        writePidlImport();

        for(final import in currentUnit.imports)
        {
            writeImport(import, (paths) => paths.types);
        }
        for(final import in currentUnit.imports)
        {
            writeImport(import, (paths) => paths.codecs, "codecs_");
        }

        writeFileVersion();

        // for(final import in currentUnit.imports)
        // {
        //     if (import.importedUnit.interfaces.isNotEmpty)
        //     {
        //         code.writeln("import '${import.importedUnit.dartOutput.interfaces.path}';");
        //     }
        // }
    }

    @override
    void generateInterface(Interface interface) 
    {
        if (interface.kind == ImplementationKind.host)
        {
            addNl = true;
            (_proxy ??= _ProxyGenerator(code: code)).generateInterface(interface, currentUnit);
        }
        else if (interface.kind == ImplementationKind.application)
        {
            addNl = true;
            (_stub ??= _StubGenerator(code: code)).generateInterface(interface, currentUnit);
        }
    }
}

class _StubGenerator with DartHelpers
{
    final CodeWriter code;
    _StubGenerator({required this.code});

    void generateInterface(Interface interface, CompilationUnit unit) 
    {
        final init = "ServiceConfig(includeTypeTags, ${interface.channel}, \"${interface.dartName}\", _fileVersion)";

        final svcname = "${interface.dartName}Service";

        code.writeln("class $svcname extends PluginService")
            .open()
            .writeln("final ${interface.dartName} implementation;")
            .nl()
            .writeln("$svcname({required this.implementation, bool includeTypeTags = false})")
            .nest()
            .writeln(": super($init)")
            .unnest()
            .open();

        for(final method in interface.flatten())
        {
            code.writeln("registerMethod(_${method.dartName});");
        }
        code.close();

        for(final method in interface.flatten())
        {
            _generateMethod(method);
        }
        
        _generateMethodInfo(code, interface);

        code.close();
    }

    void _generateMethod(Method method)
    {
        code.nl();            

        code.writeln("Future<ByteData?> _${method.dartName}(BinaryReader? argData)")
            .open();

        var bang = "!";

        for(final param in method.parameters)
        {
            code.writeln("final ${param.dartName}Arg = argData$bang.read${param.type.dartCodecSuffix}(${codec(param.type, false)});");
            bang = "";
        }

        final invoke = "await implementation.${method.dartName}(";
        if (method.returnType.targetKind != DeclKind.$void)
        {
            code.write("final result = $invoke");
        }
        else
        {
            code.write(invoke);
        }

        var first = true;
        for(final param in method.parameters)
        {
            if (!first)
            {
                code.append(", ");
            }
            first = false;

            code.append("${param.dartName}Arg");
        }

        code.appendln(");");

        if (method.returnType.targetKind == DeclKind.$void)
        {
            code.writeln("return null;");
        }
        else
        {
            code.writeln("final output = BinaryWriter(includeTypeTags);");

            code.writeln("output.write${method.returnType.dartCodecSuffix}(result${codec(method.returnType, true)});");

            code.writeln("return output.done();");
        }

        code.close();
    }
}

class _ProxyGenerator with DartHelpers
{
    final CodeWriter code;
    _ProxyGenerator({required this.code});

    void generateInterface(Interface interface, CompilationUnit unit) 
    {
        final init = "ProxyConfig(includeTypeTags, ${interface.channel}, \"${interface.dartName}\", _fileVersion)";

        code.writeln("class ${interface.dartName}Proxy extends PluginProxy implements ${interface.dartName}")
            .open()
            .writeln("${interface.dartName}Proxy({bool includeTypeTags = false})")
            .nest()
            .writeln(": super($init);")
            .unnest();

        for(final method in interface.flatten())
        {
            _generateMethod(method);
        }

        _generateMethodInfo(code, interface);

        code.close();
    }

    String _makeInvoker(Method method, String info)
    {
        if (method.hasparams && method.hasreturn)
        {
            return "invokeMethodWithArgsAndReturn(output, resultReader)";
        }
        if (method.hasparams)
        {
            return "invokeMethodWithParams(output)";
        }
        if (method.hasreturn)
        {
            return "invokeMethodWithReturn($info, resultReader)";
        }

        return "invokeMethod($info)";
    }

    void _generateMethod(Method method)
    {
        code.nl();            

        code.writeln(method.dartSignature
                .replaceFirst("@<", "Future<")
                .replaceFirst("@>", ">"))
            .open();

        final info = "_${method.dartName}";

        final invoker = _makeInvoker(method, info);

        if (method.hasparams)
        {
            code.writeln("final output = BinaryWriter(includeTypeTags, method: $info);");
            
            for (final param in method.parameters)
            {
                code.writeln("output.write${param.type.dartCodecSuffix}(${param.dartName}${codec(param.type, true)});");
            }
        }

        if (!method.hasreturn)
        {
            code.writeln("if (!await $invoker)")
                .open();
        }
        else
        {
            code.writeln("final resultReader = BinaryReader(null);")
                .nl()
                .writeln("if (!await $invoker)")
                .open();
        }
        code.writeln("throw PlatformException(code: 'channel-error', message: 'Unable to send to channel \$channelName');")
            .close();

        if (method.hasreturn)
        {
            code.writeln("final result = resultReader.read${method.returnType.dartCodecSuffix}(${codec(method.returnType, false)});")
                .writeln("return result;");
        }

        code.close();
    }
}

void _generateMethodInfo(CodeWriter code, Interface interface)
{
    code.nl();

    for(final method in interface.flatten())
    {
        code.writeln("static const _${method.dartName} = pidl.MethodInfo(\"${method.ident.name}\", ${method.parentOrder});");
    }
}