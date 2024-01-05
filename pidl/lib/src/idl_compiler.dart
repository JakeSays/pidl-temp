import 'diagnostics.dart';
import 'compile_result.dart';
import 'source_code_provider.dart';
import 'parsing/parser.dart';
import 'parsing/parser_configuration.dart';
import 'resolvers/semantic_resolver.dart';

export 'compile_result.dart';

class IdlCompiler
{
    final Diagnostics diagnostics;
    final SourceCodeProvider sourceProvider;
    final ParserConfiguration? parserConfiguration;

    IdlCompiler({
        required this.diagnostics,
        required this.sourceProvider,
        this.parserConfiguration
    });

    void validate()
    {
        final parser = IdlParser(
            sourceProvider: sourceProvider,
            diagnostics: diagnostics,
            config: parserConfiguration);
        parser.validate();
    }

    CompileResult? compileFile(String path, {bool allowIncompleteDefinitions = false})
    {
        try 
        {
            final parser = IdlParser(
                sourceProvider: sourceProvider,
                diagnostics: diagnostics,
                config: parserConfiguration);

            final results = parser.parseFile(path);
            if (results == null)
            {
                return null;
            }

            final resolver = SemanticResolver(diagnostics);
            final result = resolver.go(results.allUnits, results.mainUnit.source.path);          

            if (!diagnostics.hasErrors &&
                result.incompleteDefinitions.isNotEmpty &&
                !allowIncompleteDefinitions)
            {
                for(final node in result.incompleteDefinitions)
                {
                    diagnostics.addIssue(SemanticIssue(
                        code: IssueCode.incompleteDefinition, 
                        severity: IssueSeverity.error,
                        message: "Incomplete definition in file: ${node.declaringUnit.source.path}",
                        details: "  node: (${node.definition.declKind.name}) ${node.definition}",
                        target: node.definition
                    ));
                }
            }

            if (diagnostics.hasErrors)
            {
                return null;
            }

            return result;
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

        return null;
    }
}