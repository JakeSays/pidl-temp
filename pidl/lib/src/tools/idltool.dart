import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:pidl/pidl.dart';
import '../console.dart';

extension ResultExtensions on ArgResults
{
    String arg(String name, [String? message])
    {
        if (!wasParsed(name))
        {
            redln(message ?? 'Argument $name is required.');
            exit(1);
        }

        final value = this[name];
        return value;
    }

    String? argOpt(String name, String? defaultValue) =>
        wasParsed(name) ? this[name] : defaultValue;

    bool flagExists(String name) => wasParsed(name);

    File? fileArg(String name, [bool required = false, bool mustExist = true, String? message])
    {
        if (!wasParsed(name))
        {
            if (!required)
            {
                return null;
            }

            redln(message ?? 'Argument $name is required.');
            exit(1);
        }

        final filePath = path.absolute(this[name]);
        final file = File(filePath);
        if (mustExist && !file.existsSync())
        {
            redln(message ?? "File '$filePath' doesn't exist.");
            exit(1);
        }

        return file;
    }
}

abstract class IdlTool extends Command
{
    void initializeArgs();

    final Diagnostics diagnostics;

    ArgResults get args => argResults!;
    
    IdlTool({required this.diagnostics})
    {
        argParser.addOption("idl", 
            help: "Path to the idl file to $name.",
            mandatory: false);

        initializeArgs();
    }
}
