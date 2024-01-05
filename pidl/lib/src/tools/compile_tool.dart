import '../diagnostics.dart';
import '../tools/idltool.dart';
import '../file_system_provider.dart';
import '../idl_compiler.dart';

class CompileTool extends IdlTool
{
    @override
    String get description => "Compile an idl file";

    @override
    String get name => "compile";

    static const _allowIncompleteFlag = "allow-incomplete";

    @override
    void initializeArgs()
    {
        argParser.addOption(_allowIncompleteFlag, 
            help: "Do not fail if semantically incomplete nodes are found",
            mandatory: false);        
    }

    CompileTool({required super.diagnostics});

    CompileResult? result;

    void compile()
    {
        try 
        {
            final allowIncomplete = args.flagExists(_allowIncompleteFlag);

            final idlPath = argResults!.arg("idl");
            final sourceProvider = FileSystemProvider(diagnostics: diagnostics);

            final compiler = IdlCompiler(diagnostics: diagnostics, 
                sourceProvider: sourceProvider);

            result = compiler.compileFile(idlPath, allowIncompleteDefinitions: allowIncomplete);

            if (diagnostics.hasErrors)
            {
                result = null;
            }
        }
        on SemanticIssue catch (issue)
        {
            diagnostics.addIssue(issue);
        }
        on Exception catch (e)
        {
            diagnostics.addIssue(ExceptionIssue(
                code: IssueCode.exception, 
                severity: IssueSeverity.error, 
                message: "EXCEPTION: $e",
                exception: e));
        }
    }

    @override
    void run() => compile();
}
