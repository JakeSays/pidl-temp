import '../code_writer.dart';
import 'dart_writer.dart';
import 'dart_extensions.dart';
import 'dart_file_generator.dart';

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

class DartTypeGenerator extends DartFileGenerator
{
    DartTypeGenerator({
        required super.options,
        required super.diagnostics,
        required WriterConfig config,        
    }) : super(code: DartCodeWriter(config: config));

    @override
    OutputInfo get output => currentUnit.dartOutput.types;

    @override
    void beginCompilationUnit()
    {        
        writeHeader("type information");

        writePidlImport();

        for(final import in currentUnit.imports)
        {
            writeImport(import, (paths) => paths.types);
        }

        writeFileVersion();
    }

    @override
    void generateConst(Constant node)
    {
        addNl = true;
        code.writeln("const ${node.dartReferenceName} ${node.dartName} = ${node.value!.dartLiteralValue};");
    }

    @override
    void generateEnum(Enum node)
    {
        addNl = true;
        if (node.kind == EnumKind.normal)
        {
            _generateStandardEnum(node);
            return;
        }
        _generateBitsEnum(node);
    }

    void _generateBitsEnum(Enum node)
    {
        final name = node.ident.name;

        code.writeln("class $name extends pidl.BitsEnum")
            .open();
        
        final traits = "BitTraits.bits${node.dataType.targetKind.toNumber().bitWidth}";

        code.writeln("static const traits = $traits")
            .nl()
            .writeln("@override")
            .writeln("final int value;")
            .nl()
            .writeln("const $name._(this.value);")
            .nl();

        for(final ent in node.enumerants)
        {
            final numvalue = ent.value.asNumber;
            final value = (node.kind == EnumKind.flags || numvalue.radix == IntRadix.binary || numvalue.radix == IntRadix.hex)
                ? formatIntAsHex(ent.value.value as int, bitWidth: numvalue.kind.bitWidth)
                : ent.value.dartLiteralValue;
            code.writeln("static const ${ent.dartName} = $name._($value);");
        }
        
        code.nl()
            .writeln("operator|($name other) => $name._((value | other.value) & bits.mask);")
            .writeln("operator&($name other) => $name._((value & other.value) & bits.mask);")
            .writeln("operator~() => $name._((~value) & bits.mask);")
            .close();
    }

    void _generateStandardEnum(Enum node)
    {
        final last = node.enumerants.last;

        code.writeln("enum ${node.ident.name}")
            .open();
        
        for(final ent in node.enumerants)
        {
            final numvalue = ent.value.asNumber;
            final value = (node.kind == EnumKind.flags || numvalue.radix == IntRadix.binary || numvalue.radix == IntRadix.hex)
                ? formatIntAsHex(ent.value.value as int, bitWidth: numvalue.kind.bitWidth)
                : ent.value.dartLiteralValue;
            code.writeln("${ent.dartName} (value: $value)${ent == last ? ";" : ","}");
        }

        code.nl()
            .writeln("final int value;")
            .nl()
            .writeln("const ${node.dartName}({required this.value});");        

        code.close();
    }

    @override
    void generateInterface(Interface interface) 
    {
        addNl = true;
        code.write("abstract class ${interface.dartName}");

        if (interface.bases.isNotEmpty)
        {
            final first = interface.bases.first;

            code.write(" implements ");
            for (final base in interface.bases)
            {
                if (base != first)
                {
                    code.write(", ");
                }
                code.write(base.dartReferenceName);
            }
            code.writeln();
        }

        code.open();

        for (final method in interface.methods)
        {
            code.writefmt("${method.dartSignature
                .replaceFirst("@<", "Future<")
                .replaceFirst("@>", ">")};\n");
        }
        code.close();
    }

    @override
    void generateStruct(Struct node)
    {
        addNl = true;
        code.write("class ${node.dartName}");
        if (node.base != null)
        {
            code.write(" extends ${node.base!.dartReferenceName}");
        }
        code.nl();
        code.open();

        for(final field in node.fields)
        {
            code.writeln("${field.type.dartReferenceName} ${field.dartName};");
        }

        code.nl()
            .writeln("${node.dartName}({")
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
        if (node.istyperef)
        {
            code.writeln("typedef ${node.dartName} = ${node.target.dartReferenceName};");
        }
        else
        {
            code.writeln("const ${node.dartName} = ${node.target.dartReferenceName};");
        }
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
                    fields.required.add("required ${isbase ? "super" : "this"}.${field.dartName}");
                }
                else
                {
                    var value = "${isbase ? "super" : "this"}.${field.dartName}";
                    if (!isbase && field.defaultValue != null)
                    {
                        value += " = ${field.defaultValue!.dartLiteralValue}";
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