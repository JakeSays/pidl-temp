import '../generator_issue.dart';
import 'dart_extensions.dart';
import 'package:pidl/pidl.dart';
import '../generator_options.dart';
import '../attributes.dart';

class DartDefinitionPrepper extends TypeVisitor
{
    final Diagnostics diagnostics;
    final GeneratorOptions options;

    DartDefinitionPrepper({
        required this.diagnostics,
        required this.options});

    void _makeDartName(NamedDefinition node) =>
        node.dartName = _formatDartName(node);

    String _formatDartName(NamedDefinition node)
    {        
        final nameOverride = NameOverrideAttribute.parse(node, diagnostics, "dart");

        return nameOverride?.name ?? 
            (node.ident.name.length == 1
                ? node.ident.name.toLowerCase()
                : "${node.ident.name[0].toLowerCase()}${node.ident.name.substring(1)}");
    }

    void _makeDartFullName(NamedDefinition node) => node.dartName = _makeDartTypeName(node);

    @override
    void visit(Definition node) 
    {
        if (node.dartVisited)
        {
            return;
        }

        super.visit(node);

        node.dartVisited = true;
    }

    @override
    void visitBaseInterface(TypeReference node) 
    {
        node.dartReferenceName = _formatDartReferenceName(node);    
    }

    @override
    void visitInterface(Interface node) 
    {
        _makeDartFullName(node);        

        super.visitInterface(node);
    }

    @override
    void visitStruct(Struct node) 
    {
        _makeDartFullName(node);    
        node.dartReferenceName = _formatDartReferenceName(node.base);
        super.visitStruct(node);
    }

    @override
    void visitEnum(Enum node) 
    {
        _makeDartFullName(node);

        super.visitEnum(node);
    }

    @override
    void visitEnumerant(Enumerant node) 
    {
        _makeDartName(node);        
        node.dartQualifiedName = "${node.declarer.dartName}.${_formatDartName(node)}";
        super.visitEnumerant(node);
    }

    @override
    void visitFieldType(TypeReference node) 
    {
        node.dartReferenceName = _formatDartReferenceName(node);    
        node.dartCodecSuffix = _makeCodecSuffix(node);
    }

    @override
    void visitField(Field node) 
    {
        super.visitField(node);
        _makeDartName(node);
    }

    @override
    void visitParameterType(TypeReference node) 
    {
        node.dartReferenceName = _formatDartReferenceName(node);
    }

    @override
    void visitParameter(Parameter node) 
    {
        node.type.dartReferenceName = _formatDartReferenceName(node.type);
        _makeDartName(node);
        node.type.dartCodecSuffix = _makeCodecSuffix(node.type);
    }

    @override
    void visitTypeAlias(Alias node)
    {
        _makeDartFullName(node);
        node.target.dartReferenceName = _formatDartReferenceName(node.target);
    }

    @override
    void visitGenericTypeDefinition(GenericTypeDefinition node) 
    {
        _makeDartFullName(node);
    }

    @override
    void visitMethodReturnType(TypeReference node) 
    {
        node.dartReferenceName = _formatDartReferenceName(node);
    }

    @override
    void visitMethod(Method node) 
    {
        _makeDartName(node);

        super.visitMethod(node);

        node.returnType.dartCodecSuffix = _makeCodecSuffix(node.returnType);
        node.dartSignature = _makeMethodSignature(node);
    }

    @override
    void visitLiteral(Literal node) 
    {    
        _makeDartLiteral(node);
    }

    @override
    void visitConstant(Constant node) 
    {        
        _makeDartFullName(node);
        node.dartReferenceName = _formatDartReferenceName(node.type);

        _makeDartLiteral(node.value!);
    }
   
    @override
    void visitTypeReference(TypeReference node) 
    {
        node.dartReferenceName = _formatDartReferenceName(node);
    }

    String _makeMethodSignature(Method method)
    {
        final sig = StringBuffer();
        sig.write("@<${method.returnType.dartReferenceName}@> ${method.dartName}(");
        var first = true;
        
        String mkparam(Parameter param)
        {
            if (!param.type.nullable &&
                param.defaultValue == null)
            {
                return "required ${param.type.dartReferenceName} ${param.dartName}";
            }

            if (param.type.nullable)
            {
                return "${param.type.dartReferenceName} ${param.dartName}";
            }

            return "${param.type.dartReferenceName} ${param.dartName} = ${param.defaultValue!.dartLiteralValue}";
        }

        if (method.parameters.isNotEmpty)
        {
            sig.write("{");
            for(final param in method.parameters)
            {
                if (!first)
                {
                    sig.writeln(",\n\t");
                }
                first = false;

                sig.write(mkparam(param));
            }
            sig.write("}");
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
            ? "Nullable"
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
                        ? "${nullstr}TypedData<${_makeDartListName(ref.target as ListDefinition)}>"
                        : ref.dartReferenceName;
                case DeclKind.map:
                    return "$nullstr${ref.dartReferenceName}";
                case DeclKind.struct:
                    return "${nullstr}Object<${ref.dartReferenceName}>";
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

    void _makeDartLiteral(Literal lit)
    {
        switch(lit.kind)
        {            
            case LiteralKind.none:
                lit.dartLiteralValue = "<none>";
                return;
            case LiteralKind.nil:
                lit.dartLiteralValue = "null";
                return;
            case LiteralKind.boolean:
                lit.dartLiteralValue = (lit.value as bool) 
                    ? "true" 
                    : "false";
                return;
            case LiteralKind.number:
                final number = lit.asNumber;
                if (number.kind.isint)
                {
                    if (number.radix == IntRadix.hex || number.radix == IntRadix.binary)
                    {
                        lit.dartLiteralValue = formatIntAsHex(lit.value as int, bitWidth: number.kind.bitWidth);
                        return;
                    }
                    lit.dartLiteralValue = (lit.value as int).toRadixString(number.radix.base);
                }
                else
                {
                    lit.dartLiteralValue = number.value.toString();    
                }
                return;
            case LiteralKind.string:
                lit.dartLiteralValue = "\"${lit.value!.toString()}\"";
                return;
            case LiteralKind.constref:
                lit.dartLiteralValue = lit.asConstRef.target.dartName;
                return;
            case LiteralKind.enumerantref:
                lit.dartLiteralValue = _formatDartReferenceName(lit.asEnum);
                return;
            case LiteralKind.error:
                lit.dartLiteralValue = "<error>";
        }
    }

    String _formatDartReferenceName(Reference? reference) 
    {
        if (reference == null)
        {
            return "";
        }

        if (reference is ConstantReference)
        {
            return reference.dartName;        
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

        var name = _formatDartTypeName(defn, nullable);

        if (import?.prefix != null)
        {
            name = "${import!.prefix!.fullName}.$name";
        }

        return name;
    }

    String _formatDartTypeName(NamedDefinition? type, [bool nullable = false]) 
    {
        if (type == null)
        {
            return "";
        }

        if (type.declKind == DeclKind.enumerant)
        {
            final erant = type as Enumerant;

            return "${erant.declarer.dartName}.${erant.dartName}";
        }

        final declKind = type.declKind;

        if (declKind.isbuiltin)
        {
            switch(type.declKind)
            {
                case DeclKind.boolean:
                    return "bool${nullable ? "?" : ""}";
                case DeclKind.string:
                    return "String${nullable ? "?" : ""}";
                case DeclKind.float32:
                case DeclKind.float64:
                    return "double${nullable ? "?" : ""}";
                case DeclKind.int8:
                case DeclKind.uint8:
                case DeclKind.int16:
                case DeclKind.uint16:
                case DeclKind.int32:
                case DeclKind.uint32:
                case DeclKind.int64:
                case DeclKind.uint64:
                    return "int${nullable ? "?" : ""}";
                case DeclKind.$void:
                    return "void${nullable ? "?" : ""}";
                
                default:
                    throw ArgumentError.value(type.declKind, "declKind");
            }            
        }

        String name;
        if (type is ListDefinition)
        {
            name = _makeDartListName(type);
        }
        else if (type is MapDefinition)
        {
            final keyArg = _formatDartReferenceName(type.keyType);
            final valueArg = _formatDartReferenceName(type.valueType);
            name = "Map<$keyArg, $valueArg>";
        }
        else
        {
            name = _makeDartTypeName(type);
        }
        
        return "$name${nullable ? "?" : ""}";
    }

    String _makeDartListName(ListDefinition list)
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

        final arg = _formatDartReferenceName(list.elementType);
        return "List<$arg>";
    }

    String _makeDartTypeName(NamedDefinition type)
    {
        final nameOverride = type.findNameOverride("dart");
        final typeName = nameOverride ?? type.ident.name;

        if (type.ident.namespace == null)
        {
            return typeName;
        }

        final builder = StringBuffer();

        var capNext = false;
        final name = "${type.ident.namespace}.$typeName";
        
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