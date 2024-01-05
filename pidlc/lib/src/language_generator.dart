import 'package:pidl/pidl.dart';
import 'package:path/path.dart' as Path;

import 'generator_options.dart';
import 'output_version_parser.dart';
import 'extensions.dart';

abstract class LanguageGenerator
{
    final CompileResult results;
    final Diagnostics diagnostics;
    final GeneratorOptions options;

    LanguageGenerator({
        required this.results,
        required this.diagnostics,
        required this.options
    });

    void go()
    {
        _configureOutputs();
        generate();
    }

    Outputs configureOutputs(CompilationUnit unit, String outputBasePath);
    void generate();

    void _configureOutputs()
    {
        final mainPath = results.mainFile.source.path;
        final baseSourceDir = Path.dirname(mainPath);
        final versionParser = OutputVersionParser(outputRoot: options.dartOutputRoot!);

        for (final cu in results.unitsInDependencyOrder)
        {
            final cuPath = cu.source.path;
            String cuBasePath;
            if (Path.isWithin(baseSourceDir, cuPath))
            {
                cuBasePath = Path.relative(cuPath, from: baseSourceDir);
            }
            else
            {
                final pieces = Path.split(cuPath);
                cuBasePath = pieces.length == 1 
                    ? cuPath 
                    : Path.join(pieces[pieces.length - 2], pieces[pieces.length - 1]);

            }

            final outputs = configureOutputs(cu, cuBasePath);

            versionParser.parseVersions(outputs);
        }
    }
}