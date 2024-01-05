import 'package:path/path.dart' as Path;
import 'package:pidl/pidl.dart';
import 'extensions.dart';
import 'dart/dart_language_generator.dart';
import 'generator_options.dart';
import 'definition_prepper.dart';
import 'cxx/cxx_language_generator.dart';

class GeneratorTool extends CompileTool
{
    GeneratorTool({required super.diagnostics});

    @override
    String get name => "generate";

    String? _dartOutputDir;
    String? _cxxOutputDir;

    static const _dartOutdirArg = "dart-outdir";
    static const _cxxOutdirArg = "cxx-outdir";
    static const _forceArg = "force";

    @override
    void initializeArgs() 
    {
        super.initializeArgs();

        argParser.addOption(_dartOutdirArg, 
            help: "Destination directory for generated dart files.",
            mandatory: false);

        argParser.addOption(_cxxOutdirArg, 
            help: "Destination directory for generated C++ files.",
            mandatory: false);

        argParser.addFlag(_forceArg, 
            help: "Force code generation regardless of file version.");
    }

    @override
    void run()
    {
        compile();

        if (result == null)
        {
            return;
        }

        if (args.wasParsed(_dartOutdirArg))
        {
            _dartOutputDir = Path.canonicalize(args.arg(_dartOutdirArg));
        }
        if (args.wasParsed(_cxxOutdirArg))
        {
            _cxxOutputDir = Path.canonicalize(args.arg(_cxxOutdirArg));
        }

        final options = GeneratorOptions(
            dartOutputRoot: _dartOutputDir,
            cxxOutputRoot: _cxxOutputDir,
            forceGeneration: args.flagExists(_forceArg));
        
        DefinitionPrepper.go(result!, diagnostics, options);
        
        if (_dartOutputDir != null)
        {
            final dartGenerator = DartLanguageGenerator(
                results: result!,
                diagnostics: diagnostics,
                options: options
            );
            dartGenerator.go();
        }

        if (_cxxOutputDir != null)
        {
            final cxxGenerator = CxxLanguageGenerator(
                results: result!, 
                diagnostics: diagnostics, 
                options: options);
            cxxGenerator.go();
        }
    }
}
