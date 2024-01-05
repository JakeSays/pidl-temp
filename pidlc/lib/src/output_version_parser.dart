import 'dart:io';
import 'package:path/path.dart' as Path;
import 'package:pidl/pidl.dart';
import 'extensions.dart';

class OutputVersionParser
{
    final String _outputRoot;
    final _parser = RegExp(
        r"FileVersion\(0x([0-9a-fA-F]+),\s*0x([0-9a-fA-F]+),\s*0x([0-9a-fA-F]+),\s*0x([0-9a-fA-F]+)\)");

    OutputVersionParser({required String outputRoot})
        : _outputRoot = outputRoot;
    
    void parseVersions(Outputs outputs)
    {
        for (final output in outputs.items)
        {
            parseVersion(output);
        }
    }

    void parseVersion(OutputInfo info)
    {
        final fullPath = Path.canonicalize(
            Path.join(_outputRoot, info.path));
        
        final file = File(fullPath);
        if (file.existsSync())
        {
            final content = file.readAsStringSync();
            final match = _parser.firstMatch(content);
            if (match != null)
            {
                info.version = SemanticVersion(
                    int.parse(match[1]!, radix: 16),
                    int.parse(match[2]!, radix: 16),
                    int.parse(match[3]!, radix: 16),
                    int.parse(match[4]!, radix: 16)
                );
                return;
            }
        }

        info.version = SemanticVersion.unknown;
        return;
    }
}

