import 'package:args/command_runner.dart';
import 'dart:io';
import 'package:pidl/pidl.dart';
import 'src/generator_tool.dart';

int _terminalWidth()
{
    return 80;
    // try 
    // {
    //     return stdout.terminalColumns;
    // } 
    // catch (e)
    // {
    //     return 80;
    // }    
}

Future toolmain(List<String> arguments) async
{
    final runner = CommandRunner("idlc", "Plugin idl compiler!", usageLineLength: _terminalWidth());
    // runner.argParser.addFlag("help", 
    //     abbr: "h", 
    //     negatable: false,
    //     help: "Not sure what this flag does..",
    //     callback: (showHelp)
    //     {
    //         print(runner.usage);
    //     });

    final diagnostics = Diagnostics(detailed: true);

    runner.addCommand(GeneratorTool(diagnostics: diagnostics));
    runner.addCommand(CompileTool(diagnostics: diagnostics));
    runner.addCommand(AnalyzeGrammar(diagnostics: diagnostics));
    runner.addCommand(DumpGrammar(diagnostics: diagnostics));    
    
    await runner.run(arguments);

    diagnostics.displayIssues();

    if (diagnostics.errorCount > 0)
    {
        exit(1);
    }
}