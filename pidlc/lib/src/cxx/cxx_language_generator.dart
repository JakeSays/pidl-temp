import 'package:pidl/pidl.dart';
import 'package:path/path.dart' as Path;
import 'cxx_writer.dart';
import '../language_generator.dart';
import 'cxx_extensions.dart';
import 'cxx_definition_prepper.dart';
import 'cxx_type_generator.dart';

class CxxLanguageGenerator extends LanguageGenerator
{
    CxxLanguageGenerator({
        required super.results,
        required super.diagnostics,
        required super.options
    });

    @override
    Outputs configureOutputs(CompilationUnit unit, String outputBasePath)
    {
        unit.cxxOutput.codecsHeader.path = Path.setExtension(outputBasePath, ".codecs.h");
        unit.cxxOutput.codecsImpl.path = Path.setExtension(outputBasePath, ".codecs.cpp");
        unit.cxxOutput.typesHeader.path = Path.setExtension(outputBasePath, ".types.h");
        unit.cxxOutput.typesImpl.path = Path.setExtension(outputBasePath, ".types.cpp");
        unit.cxxOutput.interfacesHeader.path = Path.setExtension(outputBasePath, ".interfaces.h");
        unit.cxxOutput.interfacesImpl.path = Path.setExtension(outputBasePath, ".interfaces.cpp");

        return unit.cxxOutput;
    }

    @override
    void generate()
    {
        final prepper = CxxDefinitionPrepper(diagnostics: diagnostics, options: options);
        
        for (final cu in results.unitsInDependencyOrder)
        {
            for (final defn in cu.declarationOrder)
            {
                prepper.visit(defn);
            }
        }

        final config = WriterConfig(outputRoot: options.cxxOutputRoot!);
        final typegen = CxxTypeGenerator(config: config, options: options, diagnostics: diagnostics);
        // final codecgen = DartCodecGenerator(config: config, options: options, diagnostics: diagnostics);
        // final intergen = DartInterfaceGenerator(config: config, options: options, diagnostics: diagnostics);

        // typegen.go(results);
        // codecgen.go(results);
        // intergen.go(results);
    }
}