import 'package:pidl/pidl.dart';
import 'package:path/path.dart' as Path;
import 'dart_codec_generator.dart';
import 'dart_type_generator.dart';
import 'dart_interface_generator.dart';
import 'dart_definition_prepper.dart';
import '../code_writer.dart';
import '../language_generator.dart';
import 'dart_extensions.dart';

class DartLanguageGenerator extends LanguageGenerator
{
    DartLanguageGenerator({
        required super.results,
        required super.diagnostics,
        required super.options
    });

    @override
    Outputs configureOutputs(CompilationUnit unit, String outputBasePath)
    {
        unit.dartOutput.codecs.path = Path.setExtension(outputBasePath, ".codecs.dart");
        unit.dartOutput.types.path = Path.setExtension(outputBasePath, ".types.dart");
        unit.dartOutput.interfaces.path = Path.setExtension(outputBasePath, ".interfaces.dart");

        return unit.dartOutput;
    }

    @override
    void generate()
    {
        final prepper = DartDefinitionPrepper(diagnostics: diagnostics, options: options);
        
        for (final cu in results.unitsInDependencyOrder)
        {
            for (final defn in cu.declarationOrder)
            {
                prepper.visit(defn);
            }
        }

        final config = WriterConfig(outputRoot: options.dartOutputRoot!);
        final typegen = DartTypeGenerator(config: config, options: options, diagnostics: diagnostics);
        final codecgen = DartCodecGenerator(config: config, options: options, diagnostics: diagnostics);
        final intergen = DartInterfaceGenerator(config: config, options: options, diagnostics: diagnostics);

        typegen.go(results);
        codecgen.go(results);
        intergen.go(results);
    }
}