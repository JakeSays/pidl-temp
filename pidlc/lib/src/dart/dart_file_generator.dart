import '../file_generator.dart';
import 'dart_extensions.dart';

import 'package:pidl/pidl.dart';

abstract class DartFileGenerator extends FileGenerator
{
    DartFileGenerator({
        required super.code,
        required super.options,
        required super.diagnostics
    });

    void writePidlImport() => 
        code.writeln("import 'package:pidlrt/pidlrt.dart' as pidl;")
            .nl();

    void writeFileVersion() => 
        code.nl()
            .writeln("const _fileVersion = pidl.FileVersion(${currentUnit.version.format(", ")});")
            .nl();        

    void writeImport(Import import, OutputInfo Function(DartOutputPaths paths) selector, [String extra_prefix = ""])
    {
        final suffix = import.prefix != null
            ? " as $extra_prefix${import.prefix!.fullName}"
            : "";
        
        code.writeln("import '${selector(import.importedUnit.dartOutput).path}'$suffix;");
    }
}

mixin DartHelpers
{
    String resolveAliasCodecType(TypeReference ref)
    {
        var defn = (ref.target as Alias).resolved;

        TypeDefinition resolveArgType(TypeReference arg)
        {
            if (arg.target is ListDefinition)
            {
                return resolveArgType((arg.target as ListDefinition).elementType);
            }
            if (arg.target is MapDefinition)
            {
                return resolveArgType((arg.target as MapDefinition).valueType);
            }

            return arg.target as TypeDefinition;
        }

        if (defn is ListDefinition)
        {
            defn = resolveArgType(defn.elementType);
        }
        else if (defn is MapDefinition)
        {
            defn = resolveArgType(defn.valueType);
        }

        return defn.dartName;
    }

    String codec(TypeReference ref, bool encode)
    {
        if (ref.targetKind == DeclKind.struct ||
            ref.targetKind == DeclKind.alias)
        {
            var prefix = ref.import?.prefix != null
                ? "codecs_${ref.import!.prefix!.name}."
                : "";
            prefix = encode
                ? ", ${prefix}encode"
                : "${prefix}decode";

            if (ref.targetKind == DeclKind.alias)
            {
                return "$prefix${resolveAliasCodecType(ref)}";
            }
            return "$prefix${ref.target.dartName}";
        }

        return "";
    }
}