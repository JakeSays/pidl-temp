import 'package:pidl/pidl.dart';
import '../code_writer.dart';
export '../code_writer.dart';

class CxxCodeWriter extends CodeWriter
{
    CxxCodeWriter({required super.config});

    @override
    String? get declBlockTerminator => ";";

    @override
    String get forSeparator => ":";

    @override
    String get readOnlyConstruct => "const";

    @override
    String? get refVarConstruct => null;

    @override
    String get variableConstruct => "auto";

    @override
    String get nullValue => "nullptr";

    @override
    String formatLiteral(Literal? lit)
    {
        return "<invalid literal>";
    }

    @override
    String formatTypeName(Type type) 
    {
        return "<invalid>";
    }
}