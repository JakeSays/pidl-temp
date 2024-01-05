import '../code_writer.dart';
import 'dart_writer.dart';
import 'dart_extensions.dart';
import 'package:pidl/pidl.dart';
import 'dart_file_generator.dart';

class DartCodecGenerator extends DartFileGenerator
    with DartHelpers
{
    DartCodecGenerator({
        required super.options,
        required super.diagnostics,
        required WriterConfig config,        
    }) : super(code: DartCodeWriter(config: config));
        
    @override
    OutputInfo get output => currentUnit.dartOutput.codecs;

    @override
    void beginCompilationUnit()
    {
        writeHeader("encoders and decoders");

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
    }

    @override
    void generateStruct(Struct node) 
    {
        code.writeln("void encode${node.dartName}(${node.dartName} value, BinaryWriter output)")
            .open();

        for(final field in node.fields)
        {
            code.writeln("output.write${field.type.dartCodecSuffix}(value.${field.dartName}${codec(field.type, true)});");
        }

        code.close()
            .nl();
        
        code.writeln("${node.dartName} decode${node.dartName}(BinaryReader input)")
            .open();

        var first = true;
        code.writeln("final result = ${node.dartName}({")
            .nest();

        for(final field in node.fields)
        {
            if (!first)
            {
                code.append(",")
                    .nl();
            }
            first = false;
            code.write("${field.dartName}: input.read${field.type.dartCodecSuffix}(${codec(field.type, false)})");
        }

        code.nl()
            .unnest()
            .writeln(");")
            .writeln("return result;")
            .close();
    }
}

