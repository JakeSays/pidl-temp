//import '../generator_issue.dart';
import 'cxx_extensions.dart';
import 'package:pidl/pidl.dart';
import '../generator_options.dart';
import '../attributes.dart';

class CxxDefinitionPrepper extends TypeVisitor
{
    final Diagnostics diagnostics;
    final GeneratorOptions options;

    CxxDefinitionPrepper({
        required this.diagnostics,
        required this.options});

    void _makeCxxName(NamedDefinition node) =>
        node.cxxName = _formatName(node);

    String _formatName(NamedDefinition node)
    {        
        final nameOverride = NameOverrideAttribute.parse(node, diagnostics, "cxx");

        return nameOverride?.name ?? 
            (node.ident.name.length == 1
                ? node.ident.name.toUpperCase()
                : "${node.ident.name[0].toLowerCase()}${node.ident.name.substring(1)}");
    }

    void _makeFullName(NamedDefinition node) => node.cxxName = _makeTypeName(node);

    @override
    void visit(Definition node) 
    {
        if (node.cxxVisited)
        {
            return;
        }

        super.visit(node);

        node.cxxVisited = true;
    }

    @override
    void visitBaseInterface(TypeReference node) 
    {
        node.cxxReferenceName = _formatReferenceName(node);    
    }

    @override
    void visitInterface(Interface node) 
    {
        _makeFullName(node);        

        super.visitInterface(node);
    }

    @override
    void visitStruct(Struct node) 
    {
        _makeFullName(node);    
        node.cxxReferenceName = _formatReferenceName(node.base);
        super.visitStruct(node);
    }

    @override
    void visitEnum(Enum node) 
    {
        _makeFullName(node);

        super.visitEnum(node);
    }

    @override
    void visitEnumerant(Enumerant node) 
    {
        _makeCxxName(node);        
        node.cxxQualifiedName = "${node.declarer.cxxName}::${_formatName(node)}";
        super.visitEnumerant(node);
    }

    @override
    void visitFieldType(TypeReference node) 
    {
        node.cxxReferenceName = _formatReferenceName(node);    
        //node.dartCodecSuffix = _makeCodecSuffix(node);
    }

    @override
    void visitField(Field node) 
    {
        super.visitField(node);
        _makeCxxName(node);
    }

    @override
    void visitParameterType(TypeReference node) 
    {
        node.cxxReferenceName = _formatReferenceName(node);
    }

    @override
    void visitParameter(Parameter node) 
    {
        node.type.cxxReferenceName = _formatReferenceName(node.type);
        _makeCxxName(node);
        //node.type.dartCodecSuffix = _makeCodecSuffix(node.type);
    }

    @override
    void visitTypeAlias(Alias node)
    {
        _makeFullName(node);
        node.target.cxxReferenceName = _formatReferenceName(node.target);
    }

    @override
    void visitGenericTypeDefinition(GenericTypeDefinition node) 
    {
        _makeFullName(node);
    }

    @override
    void visitMethodReturnType(TypeReference node) 
    {
        node.cxxReferenceName = _formatReferenceName(node);
    }

    @override
    void visitMethod(Method node) 
    {
        _makeCxxName(node);

        super.visitMethod(node);

//        node.returnType.dartCodecSuffix = _makeCodecSuffix(node.returnType);
//        node.dartSignature = _makeMethodSignature(node);
    }

    @override
    void visitLiteral(Literal node) 
    {    
        _makeLiteral(node);
    }

    @override
    void visitConstant(Constant node) 
    {        
        _makeFullName(node);
        node.cxxReferenceName = _formatReferenceName(node.type);

        _makeLiteral(node.value!);
    }
   
    @override
    void visitTypeReference(TypeReference node) 
    {
        node.cxxReferenceName = _formatReferenceName(node);
    }

    String _makeClientMethodSignature(Method method)
    {
        final sig = StringBuffer();
        sig.write("bool ${method.cxxName}(");

        //sig.write("@<${method.returnType.cxxReferenceName}@> ${method.cxxName}(");
        var first = true;
        
        String mkparam(Parameter param)
        {
            String withDefault(String p)
            {
                if (param.defaultValue == null)
                {
                    return p;
                }

                return "$p = ${param.defaultValue!.cxxLiteralValue}";
            }

            if (param.type.declKind.isprimitive)
            {
                if (param.type.nullable)
                {
                    return withDefault("const ${param.type.cxxName}& ${param.cxxName}");
                }

                return withDefault("${param.type.cxxName} ${param.cxxName}");
            }

            if (param.type.declKind == DeclKind.string)
            {
                return withDefault("const ${param.type.cxxName}& ${param.cxxName}");
            }

            return "const RefPtr<${param.type.cxxName}>& ${param.cxxName}";
        }

        String mkretparam(TypeReference type)
        {
            if (type.declKind.isvoid)
            {
                return "ClientCallback&&";
            }

            if (type.declKind.isprimitive)
            {
                if (type.nullable)
                {
                    return "${type.cxxName}&";
                }

                return type.cxxName;
            }

            if (type.declKind == DeclKind.string)
            {
                return "const ${type.cxxName}&";
            }

            return "const RefPtr<${type.cxxName}>&";
        }

        if (method.parameters.isNotEmpty)
        {
            for(final param in method.parameters)
            {
                if (!first)
                {
                    sig.writeln(", ");
                }
                first = false;

                sig.write(mkparam(param));
            }
            sig.write(", ");
        }
        sig.write(")");

        return sig.toString();
    }

    String _makeCodecSuffix(Reference reference, [bool forceNull = false])
    {
        if (reference is ConstantReference)
        {
            return _makeCodecSuffix(reference.target.type);
        }

        final ref = reference as TypeReference;

        final nullstr = forceNull || ref.nullable
            ? "N"
            : "";
       
        String make(DeclKind kind)
        {
            switch(kind)
            {           
                case DeclKind.$void:
                    return "";                    
                case DeclKind.boolean:
                    return "${nullstr}Bool";
                case DeclKind.string:
                    return "${nullstr}String";
                case DeclKind.float32:
                    return "${nullstr}Float32";
                case DeclKind.float64:
                    return "${nullstr}Float64";
                case DeclKind.int8:
                    return "${nullstr}Int8";
                case DeclKind.uint8:
                    return "${nullstr}UInt8";
                case DeclKind.int16:
                    return "${nullstr}Int16";
                case DeclKind.uint16:
                    return "${nullstr}UInt16";
                case DeclKind.int32:
                    return "${nullstr}Int32";
                case DeclKind.uint32:
                    return "${nullstr}UInt32";
                case DeclKind.int64:
                    return "${nullstr}Int64";
                case DeclKind.uint64:
                    return "${nullstr}UInt64";
                case DeclKind.list:
                    return (ref.target as ListDefinition).declKind.istypedata
                        ? "${nullstr}TypedData<${_makeListName(ref.target as ListDefinition)}>"
                        : ref.cxxReferenceName;
                case DeclKind.map:
                    return "$nullstr${ref.cxxReferenceName}";
                case DeclKind.struct:
                    return "${nullstr}Object<${ref.cxxReferenceName}>";
                case DeclKind.alias:
                    return _makeCodecSuffix((ref.target as Alias).target, ref.nullable);
                case DeclKind.$enum:
                    return make((ref.target as Enum).dataType.targetKind);
                case DeclKind.constant:
                    return make((ref.target as Constant).valueKind);
                default:
                    throw ArgumentError();
            }
        }

        return make(reference.targetKind);
    }

    void _makeLiteral(Literal lit)
    {
        switch(lit.kind)
        {            
            case LiteralKind.nil:
                lit.cxxLiteralValue = "null";
                return;
            case LiteralKind.boolean:
                lit.cxxLiteralValue = (lit.value as bool) 
                    ? "true" 
                    : "false";
                return;
            case LiteralKind.number:
                lit.cxxLiteralValue = _formatNumber(lit.asNumber);
                return;
            case LiteralKind.string:
                lit.cxxLiteralValue = "\"${lit.value!.toString()}\"";
                return;
            case LiteralKind.constref:
                lit.cxxLiteralValue = lit.asConstRef.target.cxxName;
                return;
            case LiteralKind.enumerantref:
                lit.cxxLiteralValue = _formatReferenceName(lit.asEnum);
                return;
            case LiteralKind.error:
                lit.cxxLiteralValue = "<error>";
                return;
            default:
                throw ArgumentError();
        }
    }

    String _formatNumber(Number value)
    {
        if (value.kind.isreal)
        {
            return value.asreal.toString();
        }

        if (value.radix == IntRadix.binary)
        {
            var result = value.asint.toRadixString(2);
            if (result.length < value.kind.bitWidth)
            {
                final padding = value.kind.bitWidth - result.length;
                result = "${"0" * padding}$result";
            }
            return "0b$result";
        }

        if (value.radix == IntRadix.hex)
        {
            var result = value.asint.toRadixString(16);
            var width = value.kind.bitWidth ~/ 4;
            if (result.length < width)
            {
                final padding = width - result.length;
                result = "${"0" * padding}$result";
            }
            return "0x${result.toUpperCase()}";
        }

        if (value.radix == IntRadix.octal)
        {
            return "0${value.asint.toRadixString(8)}";
        }

        return value.asint.toString();
    }

    String _formatReferenceName(Reference? reference) 
    {
        if (reference == null)
        {
            return "";
        }

        if (reference is ConstantReference)
        {
            return reference.target.cxxName; 
        }

        NamedDefinition defn;
        Import? import;
        var nullable = false;

        if (reference is TypeReference)
        {
            defn = reference.target;
            nullable = reference.nullable;
            import = reference.import;
        }
        else
        {
            defn = (reference as EnumerantReference).target;
            import = reference.import;
        }

        var name = _formatTypeName(defn, nullable);

        if (import?.prefix != null)
        {
            name = "${import!.prefix!.fullName}::$name";
        }

        return name;
    }

    String _formatTypeName(NamedDefinition? type, [bool nullable = false]) 
    {
        if (type == null)
        {
            return "";
        }

        if (type.declKind == DeclKind.enumerant)
        {
            final erant = type as Enumerant;

            return "${erant.declarer.cxxName}::${erant.cxxName}";
        }

        final declKind = type.declKind;

        String nullize(String name)
        {
            return nullable
                ? "N$name"
                : name;
        }

        if (declKind.isbuiltin)
        {
            switch(type.declKind)
            {
                case DeclKind.boolean:
                    return nullize("bool");
                case DeclKind.string:
                    return nullize("String");
                case DeclKind.float32:
                    return nullize("Float32");
                case DeclKind.float64:
                    return nullize("Float64");
                case DeclKind.int8:
                    return nullize("Int8");
                case DeclKind.uint8:
                    return nullize("UInt8");
                case DeclKind.int16:
                    return nullize("Int16");
                case DeclKind.uint16:
                    return nullize("UInt16");
                case DeclKind.int32:
                    return nullize("Int32");
                case DeclKind.uint32:
                    return nullize("UInt32");
                case DeclKind.int64:
                    return nullize("Int64");
                case DeclKind.uint64:
                    return nullize("UInt64");
                case DeclKind.$void:
                    return "void";
                
                default:
                    throw ArgumentError.value(type.declKind, "declKind");
            }            
        }

        String name;
        if (type is ListDefinition)
        {
            name = _makeListName(type);
        }
        else if (type is MapDefinition)
        {
            final keyArg = _formatReferenceName(type.keyType);
            final valueArg = _formatReferenceName(type.valueType);
            name = "Map<$keyArg, $valueArg>";
        }
        else
        {
            name = _makeTypeName(type);
        }
        
        return nullize(name);
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
                return "UInt8List";
            case DeclKind.int16:
                return "Int16List";
            case DeclKind.uint16:
                return "UInt16List";
            case DeclKind.int32:
                return "Int32List";
            case DeclKind.uint32:
                return "UInt32List";
            case DeclKind.int64:
                return "Int64List";
            case DeclKind.uint64:
                return "UInt64List";
            default:
                break;
        }

        final arg = _formatReferenceName(list.elementType);
        return "List<$arg>";
    }

    String _makeTypeName(NamedDefinition type)
    {
        final nameOverride = type.findNameOverride("cxx");
        final typeName = nameOverride ?? type.ident.name;

        if (type.ident.namespace == null)
        {
            return typeName;
        }

        final name = "${type.ident.namespace}.$typeName".replaceAll(".", "::");
        return name;

        // final builder = StringBuffer();

        // var capNext = false;
        // final name = "${type.ident.namespace}.$typeName";
        
        // for (int index = 0; index < name.length; index++)        
        // {
        //     if (index == 0)
        //     {
        //         builder.write(name[index].toUpperCase());
        //         continue;
        //     }

        //     if (name[index] == '.')
        //     {
        //         capNext = true;
        //         continue;
        //     }

        //     if (capNext)
        //     {
        //         capNext = false;
        //         builder.write(name[index].toUpperCase());
        //         continue;
        //     }

        //     builder.write(name[index]);
        // }

        // return builder.toString();
    }
}