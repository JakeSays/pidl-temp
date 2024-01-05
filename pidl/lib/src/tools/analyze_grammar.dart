import '../parsing/parser.dart';
import '../diagnostics.dart';
import 'idltool.dart';
import '../source_code_provider.dart';

class AnalyzeGrammar extends IdlTool
{
    @override
    String get description => "Analize the parser grammar.";

    @override
    String get name => "analyze";

    @override
    void initializeArgs()
    {
    }

    AnalyzeGrammar({required super.diagnostics});
    
    @override
    void run()
    {
        final diagnostics = Diagnostics();
        final parser = IdlParser(diagnostics: diagnostics, sourceProvider: NullCodeProvider());
        parser.validate();
    }
}
