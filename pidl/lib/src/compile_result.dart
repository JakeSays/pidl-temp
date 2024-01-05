import 'types.dart';

class IncompleteDefinition
{
    Definition definition;
    CompilationUnit declaringUnit;

    IncompleteDefinition({
        required this.definition,
        required this.declaringUnit
    });
}

class CompileResult
{
    final CompilationUnit mainFile;
    final List<CompilationUnit> unitsInDependencyOrder;
    final List<IncompleteDefinition> incompleteDefinitions;

    CompileResult({
        required this.mainFile,
        required this.unitsInDependencyOrder,
        required this.incompleteDefinitions
    });
}