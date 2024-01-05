import '../parsing/parser.dart';
import 'idltool.dart';
import '../diagnostics.dart';
import '../source_code_provider.dart';

class DumpGrammar extends IdlTool
{
    @override
    String get description => "Display the parser grammar.";

    @override
    String get name => "grammar";

    @override
    void initializeArgs()
    {
    }

    DumpGrammar({required super.diagnostics});

    @override
    void run()
    {
        final diagnostics = Diagnostics();
        final parser = IdlParser(diagnostics: diagnostics, sourceProvider: NullCodeProvider());
        parser.dump();
    }
}

