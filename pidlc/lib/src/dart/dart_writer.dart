import 'package:pidl/pidl.dart';
import '../code_writer.dart';

class DartCodeWriter extends CodeWriter
{
    DartCodeWriter({required super.config});

    @override
    String? get declBlockTerminator => null;

    @override
    String get forSeparator => "in";

    @override
    String get readOnlyConstruct => "final";

    @override
    String? get refVarConstruct => null;

    @override
    String get variableConstruct => "var";

    @override
    String get nullValue => "null";

    @override
    String formatTypeName(Type type) 
    {
        if (type.declKind == null &&
            type.definition == null &&
            type.reference == null &&
            type.enumerant == null)
        {
            throw ArgumentError("Invalid type to format", "type");
        }   

        if (type.enumerant != null)
        {
            return "${type.enumerant!.declarer.ident.name}.${type.enumerant!.ident.name}";
        }

        final declKind = type.declKind ?? 
            type.reference?.targetKind ?? 
            type.definition!.declKind;

        if (declKind.isbuiltin)
        {
            switch(type.declKind)
            {
                case DeclKind.boolean:
                    return "bool${type.nullable ? "?" : ""}";
                case DeclKind.string:
                    return "String${type.nullable ? "?" : ""}";
                case DeclKind.float32:
                case DeclKind.float64:
                    return "double${type.nullable ? "?" : ""}";
                case DeclKind.int8:
                case DeclKind.uint8:
                case DeclKind.int16:
                case DeclKind.uint16:
                case DeclKind.int32:
                case DeclKind.uint32:
                case DeclKind.int64:
                case DeclKind.uint64:
                    return "int${type.nullable ? "?" : ""}";
                case DeclKind.$void:
                    return "void${type.nullable ? "?" : ""}";
                
                default:
                    throw ArgumentError.value(type.declKind, "declKind");
            }            
        }

        final decl = type.reference?.target ?? type.definition!;
        String name;
        if (decl is ListDefinition)
        {
            name = _makeListName(decl);
        }
        else if (decl is MapDefinition)
        {
            final keyArg = formatTypeName(Type.ref(decl.keyType));
            final valueArg = formatTypeName(Type.ref(decl.valueType));
            name = "Map<$keyArg, $valueArg>";
        }
        else
        {
            name = _makeTypeName(decl);
        }
        
        return "$name${type.nullable ? "?" : ""}";
    }

    String _makeListName(ListDefinition list)
    {
        switch (list.elementType.declKind)
        {
            case DeclKind.float32:
                return "Float32List";
            case DeclKind.float64:
                return "Float64List";
            case DeclKind.int8:
                return "Int8List";
            case DeclKind.uint8:
                return "Uint8List";
            case DeclKind.int16:
                return "Int16List";
            case DeclKind.uint16:
                return "Uint16List";
            case DeclKind.int32:
                return "Int32List";
            case DeclKind.uint32:
                return "Uint32List";
            case DeclKind.int64:
                return "Int64List";
            case DeclKind.uint64:
                return "Uint64List";
            default:
                break;
        }

        final arg = formatTypeName(Type.ref(list.elementType));
        return "List<$arg>";
    }

    String _makeTypeName(NamedDefinition type)
    {
        if (type.ident.namespace == null)
        {
            return type.ident.name;
        }

        final builder = StringBuffer();

        var capNext = false;
        final name = type.ident.fullName;
        
        for (int index = 0; index < name.length; index++)        
        {
            if (index == 0)
            {
                builder.write(name[index].toUpperCase());
                continue;
            }

            if (name[index] == '.')
            {
                capNext = true;
                continue;
            }

            if (capNext)
            {
                capNext = false;
                builder.write(name[index].toUpperCase());
                continue;
            }

            builder.write(name[index]);
        }

        return builder.toString();
    }
}