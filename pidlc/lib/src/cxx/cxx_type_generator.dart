import '../code_writer.dart';
import 'cxx_writer.dart';
import 'cxx_extensions.dart';
import 'cxx_file_generator.dart';

import 'package:pidl/pidl.dart';

enum BitsWidth
{
    bits8 (width: 8, mask: 0xFF),
    bits16 (width: 16, mask: 0xFFFF),
    bits32 (width: 32, mask: 0xFFFFFFFF),
    bits64 (width: 64, mask: 0xFFFFFFFFFFFFFFFF);

    final int width;
    final int mask;

    const BitsWidth({required this.width, required this.mask});
}

extension _DeclKind on DeclKind
{
    String get mask
    {
        switch (this)
        {
            case DeclKind.int8:
            case DeclKind.uint8:
                return "0xFF";
            case DeclKind.int16:
            case DeclKind.uint16:
                return "0xFFFF";
            case DeclKind.int32:
            case DeclKind.uint32:
                return "0xFFFFFFFF";
            case DeclKind.int64:
            case DeclKind.uint64:
                return "0xFFFFFFFFFFFFFFFF";
            default:
                throw StateError("Cannot obtain bit width");
        }
    }
}

abstract class BitsEnum
{
    int get value;

    const BitsEnum();
}

mixin Bits16
{
    static const width = 16;
    static const mask = 0xFFFF;
}

class FooEnum extends BitsEnum
{
    static const bits = BitsWidth.bits64;

    @override
    final int value;

    const FooEnum._(this.value);
    
    static const FooEnum a = FooEnum._(10);

    operator|(FooEnum other) => FooEnum._((value | other.value) & bits.mask);
    operator&(FooEnum other) => FooEnum._((value & other.value) & bits.mask);
    operator~() => FooEnum._((~value) & bits.mask);
}

class CxxTypeGenerator extends CxxFileGenerator
{
    CxxTypeGenerator({
        required super.options,
        required super.diagnostics,
        required WriterConfig config,        
    }) : super(code: CxxCodeWriter(config: config));

    @override
    OutputInfo get output => currentUnit.cxxOutput.typesHeader;

    @override
    void beginCompilationUnit()
    {        
        writeHeader("type information");

        // writePidlImport();

        // for(final import in currentUnit.imports)
        // {
        //     writeImport(import, (paths) => paths.types);
        // }

        // writeFileVersion();
    }

    @override
    void generateConst(Constant node)
    {
        addNl = true;
        code.writeln("constexpr ${node.cxxReferenceName} ${node.cxxName} = ${node.value!.cxxLiteralValue};");
    }

    @override
    void generateEnum(Enum node)
    {
        addNl = true;
        final name = node.ident.name;
        final last = node.enumerants.last;
        final type = node.dataType.cxxName;

        code.writeln("enum class $name : $type")
            .open();
        
        for(final ent in node.enumerants)
        {
            code.writeln("${ent.cxxName} = ${ent.cxxLiteralValue}${ent == last ? "" : ","}");
        }
        
        code.close();
        code.writeln("using N$name = std::optional<$name>;");

        if (node.kind == EnumKind.normal)
        {
            return;
        }

        code.nl()
            .writeln("inline $name operator ~($name lhs) { return EnumOps::Not<$type>(lhs); }")
            .writeln("inline $name operator |($name lhs, $name rhs) { return EnumOps::Or<$type>(lhs, rhs); }")
            .writeln("inline $name operator |=($name lhs, $name rhs) { return EnumOps::Or<$type>(lhs, rhs); }")
            .writeln("inline $name operator &($name lhs, $name rhs) { return EnumOps::And<$type>(lhs, rhs); }")
            .writeln("inline $name operator &=($name lhs, $name rhs) { return EnumOps::And<$type>(lhs, rhs); }")
            .writeln("inline $name operator ^($name lhs, $name rhs) { return EnumOps::Xor<$type>(lhs, rhs); }")
            .writeln("inline $name operator ^=($name lhs, $name rhs) { return EnumOps::Xor<$type>(lhs, rhs); }")
            .writeln("inline $name operator <<($name lhs, UInt32 value) { return EnumOps::ShiftLeft<$type>(lhs, value); }")
            .writeln("inline $name operator <<=($name lhs, UInt32 value) { return EnumOps::ShiftLeft<$type>(lhs, value); }")
            .writeln("inline $name operator >>($name lhs, UInt32 value) { return EnumOps::ShiftRight<$type>(lhs, value); }")
            .writeln("inline $name operator >>=($name lhs, UInt32 value) { return EnumOps::ShiftRight<$type>(lhs, value); }");
    }

    @override
    void generateInterface(Interface interface) 
    {
        addNl = true;
        code.write("class ${interface.cxxName}");

        if (interface.bases.isNotEmpty)
        {
            final first = interface.bases.first;

            code.write(" : ");
            for (final base in interface.bases)
            {
                if (base != first)
                {
                    code.write(", ");
                }
                code.write("public ${base.cxxReferenceName}");
            }
            code.writeln();
        }

        code.open();

        // for (final method in interface.methods)
        // {
        //     code.writefmt("${method.cxxSignature
        //         .replaceFirst("@<", "Future<")
        //         .replaceFirst("@>", ">")};\n");
        // }
        code.close();
    }

    @override
    void generateStruct(Struct node)
    {
        addNl = true;
        code.write("class ${node.cxxName}");
        if (node.base != null)
        {
            code.write(" extends ${node.base!.cxxReferenceName}");
        }
        code.nl();
        code.open();

        for(final field in node.fields)
        {
            code.writeln("${field.type.cxxReferenceName} ${field.cxxName};");
        }

        code.nl()
            .writeln("${node.cxxName}({")
            .nest(1);
        
        final ctorFields = _getCtorFields(node);
        final last = ctorFields.lastField;

        for (final field in ctorFields.required)
        {
            code.writeln("$field${field != last ? "," : ""}");
        }

        for (final field in ctorFields.optional)
        {
            code.writeln("$field${field != last ? "," : ""}");
        }

        code.unnest(1)
            .writeln("});")
            .close();
    }

    @override
    void generateAlias(Alias node)
    {
        addNl = true;
        code.writeln("using ${node.cxxName} = ${node.target.cxxReferenceName};");
    }

    _StructFields _getCtorFields(Struct struct)
    {        
        final fields = _StructFields();

        void categorizeFields(Struct struct, bool isbase)
        {
            for(final field in struct.fields)
            {
                if (!field.type.nullable &&
                    field.defaultValue == null)
                {
                    fields.required.add("required ${isbase ? "super" : "this"}.${field.cxxName}");
                }
                else
                {
                    var value = "${isbase ? "super" : "this"}.${field.cxxName}";
                    if (!isbase && field.defaultValue != null)
                    {
                        value += " = ${field.defaultValue!.cxxLiteralValue}";
                    }

                    fields.optional.add(value);
                }
            }
        }

        if (struct.base != null)
        {
            categorizeFields(struct.base!.target as Struct, true);
        }

        categorizeFields(struct, false);

        return fields;
    }
}

class _StructFields
{
    final List<String> required = [];
    final List<String> optional = [];

    String get lastField => optional.isEmpty
        ? required.last
        : optional.last;
}