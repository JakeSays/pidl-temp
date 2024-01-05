import '../issue_code.dart';
import '../issues.dart';
import '../parsing/ast.dart';
import '../diagnostics.dart';
import '../types.dart';
import '../type_scope.dart';

abstract class ResolverBase
{
    final Diagnostics diagnostics;
    final TypeScope builtins;

    ResolverBase({
        required this.diagnostics,
        required this.builtins
    });

    void resolve(CompilationUnitSyntax cu)
    {
    }   
}
