import 'package:meta/meta.dart';
import 'package:path/path.dart' as Path;
import 'package:pidl/pidl.dart';
import 'source.dart';
import 'kinds.dart';
import 'type_scope.dart';
import 'type_visitor.dart';
import 'semantic_version.dart';
import 'extensions.dart';
import 'numeric_limits.dart';
export 'kinds.dart';
export 'semantic_version.dart';

enum DefinitionState
{
    unknown,
    error,
    complete
}

class Definition extends LocationProvider
{
    final List<Attribute> attributes;
    Definition? declaringNode;
    DeclKind declKind;
    DefinitionState state;

    //declaration order in the parent
    int parentOrder = -1;

    bool get iscomplete => state == DefinitionState.complete;
    
    List<Reference> references = [];

    //Used by pidl consumers to store node
    //  specific information.
    Object? userData;

    Definition({
        required this.declKind,
        this.state = DefinitionState.unknown,
        super.location,
        this.declaringNode,
        List<Attribute>? attributes
    }) : attributes = attributes ?? [];

    void accept(TypeVisitorInterface visitor)
    {
        visitor.visit(this);
    }

    void addAttribute(Attribute attr)
    {
        attr.parentOrder = attributes.length;
        attributes.add(attr);
    }

    Attribute? findAttribute(bool Function(Attribute attr) predicate)
    {
        for(final attr in attributes)
        {
            if (predicate(attr))
            {
                return attr;
            }
        }

        return null;
    }

    List<Attribute> findAttributes(bool Function(Attribute attr) predicate)
    {
        return attributes.where((element) => predicate(element)).toList();
    }

    Attribute? findAttributeByName(String name) =>
        findAttribute((attr) => attr.name == name);

    List<Attribute> findAttributesByCategory(String category) =>
        attributes.where((attr) => attr.category?.fullName == category).toList();

    void enclose(Definition? child, [bool keepExisting = true]) 
    {
        if (child == null)
        {
            return;
        }

        if (child.declaringNode == null || !keepExisting)
        {
            child.declaringNode = this;
        }
    }

    @protected
    void encloseAll(Iterable<Definition>? children, [bool keepExisting = true]) 
    {
        children?.forEach((node) => enclose(node, keepExisting));
    }
}

mixin Declarer<TType> on Definition
{
    TType get declarer => declaringNode as TType;
}

class AttributeArg extends Definition
    with Declarer<Attribute>
{
    Identifier? _name;
    Literal? _value;

    AttributeArg({Identifier? name, Literal? value, DefinitionState? state})
        : _name = name,
          _value = value,
          super(declKind: DeclKind.attributeArg, state: state ?? DefinitionState.complete);

    Identifier? get name => _name;
    set name(Identifier? name) 
    {
        name?.declaringNode = this;
        _name = name;
    }

    Literal? get value => _value;
    set value(Literal? value) 
    {
        value?.declaringNode = value;
        _value = value;
    }

    static final AttributeArg none = AttributeArg(state: DefinitionState.error);
}

class Attribute extends NamedDefinition
{
    Identifier? category;    
    List<AttributeArg> args;

    late final String name;

    void addArgument(AttributeArg arg)
    {
        arg.parentOrder = args.length;

        enclose(arg);
        args.add(arg);
    }

    AttributeArg? findNamedArgument(String argName)
    {
        for(final arg in args)
        {
            if (arg.name?.fullName == argName)
            {
                return arg;
            }
        }

        return null;
    }

    Attribute({
        required super.ident,
        required this.args,
        this.category,
        DefinitionState? state,
        super.location
    }) : super(declKind: DeclKind.attribute, state: state ?? DefinitionState.complete)
    {
        name = category != null
            ? "$category:${ident.fullName}"
            : ident.fullName;

        args.indexOver((index, element) => element.parentOrder = index);

        encloseAll(args);
    }

    void reparent(Definition newParent)
    {
        declaringNode = newParent;
    }
}

class Identifier extends Definition
{
    String? namespace;
    String name;

    String fullName;

    static final Identifier none = Identifier(name: "<>", state: DefinitionState.error, location: SourceLocation.unknown);

    static const String _unknownTag = r"$$unknown";
    static final Identifier unknown = Identifier(name: _unknownTag, state: DefinitionState.error, location: SourceLocation.unknown);

    bool get isunknown => name == _unknownTag;

    bool get isvalid => state == DefinitionState.complete;

    String format(String separator) => namespace != null
        ? "${namespace!.replaceAll(".", separator)}$separator$name"
        : name;

    Identifier({        
        required this.name,
        this.namespace,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : fullName = namespace != null
        ? '$namespace.$name'
        : name,
        super(declKind: DeclKind.identifier, state: state ?? DefinitionState.complete);

    void updateNamespace(String newns)
    {
        namespace = newns;

        fullName = namespace!.isNotEmpty
            ? '$namespace.$name'
            : name;
    }

    factory Identifier.parse(String fullName, 
        [SourceLocation? location, List<Attribute>? attributes])
    {
        var namePart = '';
        String? namespacePart;

        final parts = fullName.split('.');
        if (parts.length > 1)
        {
            namePart = parts.last;
            namespacePart = parts.getRange(0, parts.length - 1).join('.');            
        }
        else
        {
            namePart = fullName;
        }

        return Identifier(            
            name: namePart, 
            namespace: namespacePart, 
            location: location,
            attributes: attributes,
            state: DefinitionState.complete);
    }

    Identifier.nameOnly(this.fullName, 
        [SourceLocation? location, List<Attribute>? attributes])
        : name = fullName,
            super(location: location, attributes: attributes, declKind: DeclKind.identifier, state: DefinitionState.complete);
            
    @override
    String toString() => fullName;
}

class Number extends Definition
{
    NumberKind kind;
    IntRadix radix;
    NumberScale scale;
    TypeReference type;
    Object value;
    
    double get asreal => value as double;
    BigInt get asint => (value as BigInt) * scale.value;

    Number({
        required this.value,
        required this.kind,
        required this.radix,
        required this.scale,
        required this.type,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: kind.toDecl(), state: state ?? DefinitionState.complete)
    {
        enclose(type);
    }

    Number negate()
    {
        if (kind.isint)
        {
            value = -(value as BigInt);
            return this;
        }
        if (kind.isreal)
        {
            value = -(value as double);
            return this;
        }
        return this;
    }

    @override
    String toString() 
    {
        return "${radix.prefix}$value${scale.n}";
    }
}

class Literal extends Definition
{
    LiteralKind kind;
    Object? value;

    EnumerantReference get asEnum => value as EnumerantReference;
    ConstantReference get asConstRef => value as ConstantReference;
    Number get asNumber => value as Number;

    TypeReference dataType;
    bool synthesized = false;

    Literal({
        required this.kind,
        TypeReference? dataType,
        this.value,
        super.state = DefinitionState.complete,
        super.location,
        super.attributes
    }) : dataType = dataType ?? TypeReference.none(location),
         super(declKind: DeclKind.literal)
    {
        if (value is Reference)
        {
            enclose(value as Reference);
        }
        else if (value is Number)
        {
            enclose(value as Number);
        }
    }

    Literal.enumerantref(Enumerant enumerant, this.dataType, [SourceLocation? location, List<Attribute>? attributes])
        : value = EnumerantReference(target: enumerant, location: location, import: dataType.import),
          kind = LiteralKind.enumerantref,
          super(attributes: attributes, location: location, declKind: DeclKind.literal)
        {
            state = asEnum.state;
        }

    Literal.number(Number value, this.dataType, [SourceLocation? location, List<Attribute>? attributes])
        : kind = LiteralKind.number,
          value = value,
          super(attributes: attributes, location: location, declKind: DeclKind.literal, state: DefinitionState.complete);

    Literal.boolean(bool value, this.dataType, [SourceLocation? location, List<Attribute>? attributes])
        : kind = LiteralKind.boolean,
          value = value,
          super(attributes: attributes, location: location, declKind: DeclKind.literal, state: DefinitionState.complete);
        
    Literal.string(String value, this.dataType, [SourceLocation? location, List<Attribute>? attributes])
        : kind = LiteralKind.string,
          value = value,
          super(attributes: attributes, location: location, declKind: DeclKind.literal, state: DefinitionState.complete);
        
    Literal.nil(this.dataType, [SourceLocation? location, List<Attribute>? attributes])
        : kind = LiteralKind.nil,
          super(attributes: attributes, location: location, declKind: DeclKind.literal, state: DefinitionState.complete);

    Literal.constref(Constant $const, Import? import, this.dataType, [SourceLocation? location, List<Attribute>? attributes])
        : value = ConstantReference(target: $const, import: import, location: location),
          kind = LiteralKind.constref,
          super(attributes: attributes, location: location, declKind: DeclKind.literal)
        {
            state = asConstRef.state;
        }

    Literal.error([SourceLocation? location])
        : kind = LiteralKind.error,
          dataType = TypeReference.unknown(location),
          super(location: location, declKind: DeclKind.literal, state: DefinitionState.error);

    @override
    String toString() 
    {
        return "${kind.name} ${kind == LiteralKind.nil ? "null" : value?.toString() ?? "<invalid>"}";
    }
}

class NamedDefinition extends Definition
{
    Identifier ident;
    TypeScope? declaringScope;

    NamedDefinition({        
        required this.ident,
        required super.declKind,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        enclose(ident);
    }
}

class Reference extends Definition
{
    Definition referenced;
    Import? import;

    Reference({
        required this.referenced,
        this.import,
        super.state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.reference)
    {
        referenced.references.add(this);
    }
}

class TypeReference extends Reference
{
    bool nullable;
    TypeDefinition target;

    DeclKind get targetKind => target.declKind;
    Identifier get name => target.ident;

    TypeReference({
        required this.target,        
        this.nullable = false,
        DefinitionState? state,
        super.import,
        super.location,
        super.attributes
    }) : super(referenced: target, state: state ?? target.state);
    
    factory TypeReference.to(TypeDefinition target, {bool nullable = false, SourceLocation? location}) =>
        TypeReference(target: target, nullable: nullable, location: location, state: target.state);

    factory TypeReference.unknown(SourceLocation? location) =>
        TypeReference(target: TypeDefinition.unknown, location: location, state: DefinitionState.error);

    factory TypeReference.none(SourceLocation? location) =>
        TypeReference(target: TypeDefinition.none, location: location, state: DefinitionState.complete);

    @override
    String toString() => "${target.ident.fullName}${nullable ? "?" : ""}";    
}

class UnknownReference extends Reference
{
    UnknownReference({
        super.location,
        super.attributes
    }) : super(referenced: Definition(declKind: DeclKind.none),
           state: DefinitionState.error);
}

class ConstantReference extends Reference
{
    Constant target;
    TypeReference get type => target.type;

    DeclKind get valueKind => target.valueKind;
    Expression? get initializer => target.initializer;
    Literal? get value => target.value;

    ConstantReference({
        required this.target,
        required super.import,
        super.location,
        super.attributes
    }) : super(referenced: target, state: target.state);

    @override
    String toString() => '@ $target';
}

class EnumerantReference extends Reference
{
    Enumerant target;

    EnumerantReference({
        required this.target,
        required super.import,
        super.location,
        super.attributes
    }) : super(referenced: target, state: target.state);

    @override
    String toString() => '@ $target';
}

class InitializedDefinition extends NamedDefinition
{
    Expression initializer;
    ExprValue computedValue;

    InitializedDefinition({
        required super.ident, 
        required super.declKind,
        required this.computedValue,
        Expression? initializer,
        super.state,
        super.location,
        super.attributes        
    }) : initializer = initializer ?? EmptyExpression()
    {
        enclose(initializer);
    }
}

class TypedDefinition extends InitializedDefinition
{
    TypeReference type;

    TypedDefinition({
        required super.ident, 
        required super.declKind,
        required super.computedValue,
        required this.type,
        super.initializer,
        super.state,
        super.location,
        super.attributes        
    })
    {
        enclose(type);
    }
}

class TypeDefinition extends NamedDefinition 
{
    final bool isBuiltin;
   
    TypeDefinition({
        required super.ident,
        required super.declKind,
        super.state,
        super.location,
        super.attributes,
        this.isBuiltin = false
    });

    bool get isunknown => ident.isunknown;
    bool get isnone => declKind == DeclKind.none &&
        state == DefinitionState.complete;

    static final TypeDefinition unknown =
        TypeDefinition(
            ident: Identifier.unknown, 
            declKind: DeclKind.none,
            location: SourceLocation.unknown,
            state: DefinitionState.error);

    static final TypeDefinition none =
        TypeDefinition(
            ident: Identifier.unknown, 
            declKind: DeclKind.none,
            location: SourceLocation.unknown,
            state: DefinitionState.complete);

    static TypeDefinition error([Identifier? name, SourceLocation? location]) =>
            TypeDefinition(
            ident: name ?? Identifier.unknown, 
            declKind: DeclKind.none,
            location: location ?? SourceLocation.unknown,
            state: DefinitionState.error);
}

class GenericTypeDefinition extends TypeDefinition
{
    List<TypeReference> typeParameters;

    GenericTypeDefinition({
        required super.ident,
        required this.typeParameters,
        required super.declKind,
        super.state,
        super.location
    })
    {
        typeParameters.indexOver((index, element) => element.parentOrder = index);
    }
}

class ListDefinition extends GenericTypeDefinition
{
    TypeReference get elementType => typeParameters[0];

    ListDefinition({
        required TypeReference arg,
        DefinitionState? state,
        super.location
    }) : super(declKind: DeclKind.list, 
            typeParameters: [arg],
            ident: _makeName(arg),
            state: state ?? (arg.state == DefinitionState.error
                ? DefinitionState.error
                : DefinitionState.complete));

    @override
    String toString() => "list<$elementType>";

    static Identifier _makeName(TypeReference arg) =>
        Identifier.nameOnly("list<${arg.name.fullName}>");
}

class MapDefinition extends GenericTypeDefinition
{
    TypeReference get keyType => typeParameters[0];
    TypeReference get valueType => typeParameters[1];

    MapDefinition({
        required TypeReference keyType,
        required TypeReference valueType,        
        DefinitionState? state,
        super.location
    }) : super(declKind: DeclKind.map, 
            typeParameters: [keyType, valueType],
            ident: _makeName(keyType, valueType),
            state: state ?? (keyType.state == DefinitionState.error || valueType.state == DefinitionState.error
                ? DefinitionState.error
                : DefinitionState.complete));

    @override
    String toString() => "$ident ${state.name}";

    static Identifier _makeName(TypeReference keyType, TypeReference valueType) =>
        Identifier.nameOnly("map<${keyType.name.fullName}, ${valueType.name.fullName}>");
}

class BuiltinTypeDefinition extends TypeDefinition
{
    NumberKind numberKind;
    
    BuiltinTypeDefinition({required DeclKind declKind, NumberKind? numberKind})
        : numberKind = numberKind ?? NumberKind.none,
          super(
            declKind: declKind, 
            isBuiltin: true,
            state: DefinitionState.complete,
            ident: _makeNumberName(numberKind) ?? _makeDeclName(declKind));

    TypeReference reference({bool nullable = false, SourceLocation? location}) =>
        TypeReference(target: this, nullable: nullable, location: location);

    static Identifier? _makeNumberName(NumberKind? kind)
    {
        if (kind == null)
        {
            return null;
        }

        return Identifier.nameOnly(kind.name);
    }

    static Identifier _makeDeclName(DeclKind kind) =>
        Identifier.nameOnly(kind.name.replaceAll(r"$", ""));

    @override
    String toString() => ident.toString();
}

class Constant extends TypedDefinition 
{
    DeclKind valueKind;

    Literal? value;

    Constant({
        required super.ident,
        required super.type,         
        required super.initializer,
        required super.computedValue,
        required this.valueKind,
        this.value,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.constant)
    {
        if (state != null)
        {
            super.state = state;
            return;
        }
        super.state = type.state;
        if (super.state != DefinitionState.error)
        {
            if (valueKind == DeclKind.none)
            {
                super.state = DefinitionState.error;
            }
            else if (!type.nullable && value == null)
            {
                super.state = DefinitionState.error;
            }
            else if (initializer.state != DefinitionState.complete)
            {
                super.state = initializer.state;
            }
            else 
            {
                super.state = DefinitionState.complete;
            }
        }
    }

    @override
    String toString() => "$ident ${valueKind.name} $value ${state.name}";
}

class Parameter extends TypedDefinition
    with Declarer<Method>
    implements InitializedDefinition
{
    Literal? defaultValue;

    Parameter({
        required super.ident,         
        required super.type,
        required super.computedValue,
        required super.initializer,
        this.defaultValue,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.parameter)
    {
        super.state = state ?? type.state;
        enclose(defaultValue);
    }

    @override
    String toString() => "enum $ident ${state.name}";
}

class Method extends NamedDefinition 
    with Declarer<Interface>
{
    TypeReference returnType;
    List<Parameter> parameters;

    bool get hasreturn => returnType.targetKind != DeclKind.$void;
    bool get hasparams => parameters.isNotEmpty;

    Method({        
        required super.ident,         
        required this.returnType,
        required this.parameters,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.method)
    {
        enclose(returnType);
        encloseAll(parameters);

        parameters.indexOver((index, element) => element.parentOrder = index);

        if (state != null)
        {
            super.state = state;
            return;
        }

        super.state = returnType.state;
        if (super.state != DefinitionState.error)
        {
            super.state = parameters.any((e) => e.state == DefinitionState.error)
                ? DefinitionState.error
                : DefinitionState.complete;
        }
    }

    @override
    String toString() => "$ident ${state.name}";
}

class Interface extends TypeDefinition
{
    List<TypeReference> bases;
    List<Method> methods;

    Interface({        
        required super.ident, 
        required this.methods,
        List<TypeReference>? bases,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : bases = bases ?? [],
         super(declKind: DeclKind.interface)    
    {
        encloseAll(bases);
        encloseAll(methods);
        
        this.bases.indexOver((index, element) => element.parentOrder = index);
        methods.indexOver((index, element) => element.parentOrder = index);

        super.state = state ?? (this.bases.any((e) => e.state == DefinitionState.error) ||
                methods.any((e) => e.state == DefinitionState.error)
                    ? DefinitionState.error
                    : DefinitionState.complete);
    }

    Iterable<Method> flatten() sync*
    {
        for(final method in methods)
        {
            yield method;
        }

        for (var base in bases)
        {
            for(final method in (base.target as Interface).methods)
            {
                yield method;
            }
        }
    }

    @override
    String toString() => "interface $ident ${state.name}";
}

abstract class DeclarationScope extends NamedDefinition
{
    int _nextParentOrderCounter = 0;

    final List<Namespace> namespaces;
    List<Enum> enumerations;
    List<Interface> interfaces;
    List<Struct> structs;
    List<Alias> typeAliases;
    List<Constant> constants;
    
    List<Definition> declarationOrder = [];

    int get _nextParentOrder => _nextParentOrderCounter++;

    DeclarationScope({        
        required super.ident, 
        required super.declKind,
        List<Namespace>? namespaces,
        List<Enum>? enumerations,
        List<Interface>? interfaces,
        List<Struct>? structs,
        List<Alias>? typeAliases,
        List<Constant>? constants,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : namespaces = namespaces ?? [],
         enumerations = enumerations ?? [],
         interfaces = interfaces ?? [],
         structs = structs ?? [],
         typeAliases = typeAliases ?? [],
         constants = constants ?? []
    {
        super.state = state ?? (this.namespaces.arecomplete &&
            this.enumerations.arecomplete &&
            this.interfaces.arecomplete &&
            this.structs.arecomplete &&
            this.typeAliases.arecomplete &&
            this.constants.arecomplete
            ? DefinitionState.complete
            : DefinitionState.error);

        encloseAll(namespaces);
        encloseAll(enumerations);
        encloseAll(interfaces);
        encloseAll(structs);
        encloseAll(typeAliases);
        encloseAll(constants);
    }

    void addMember(NamedDefinition member)
    {
        member.parentOrder = _nextParentOrder;

        enclose(member);

        switch (member.declKind)
        {
            case DeclKind.struct:
                structs.add(member as Struct);
                break;
            case DeclKind.alias:
                typeAliases.add(member as Alias);
                break;
            case DeclKind.interface:
                interfaces.add(member as Interface);
                break;
            case DeclKind.$enum:
                enumerations.add(member as Enum);
                break;
            case DeclKind.constant:
                constants.add(member as Constant);
                break;
            case DeclKind.namespace:
                namespaces.add(member as Namespace);
                break;
            default:
                if (member is BuiltinTypeDefinition)
                {
                    return;
                }
                throw ArgumentError("Invalid member", "member");
        }

        declarationOrder.add(member);

        if (member.state != DefinitionState.complete)
        {
            state = member.state;
        }
    }
}

class Namespace extends DeclarationScope
{
    Namespace({        
        required super.ident,
        super.namespaces, 
        super.enumerations,
        super.interfaces,
        super.structs,
        super.typeAliases,
        super.constants,
        super.state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.namespace);

    factory Namespace.fromNodes(
        Identifier name, 
        List<Definition> types,
        SourceLocation location,
        List<Attribute>? attributes)
    {
        types.indexOver((index, element) => element.parentOrder = index);

        return Namespace(            
            ident: name,
            namespaces: types.ofType<Namespace>(),
            enumerations: types.ofType<Enum>(),
            interfaces: types.ofType<Interface>(),
            structs: types.ofType<Struct>(),
            typeAliases: types.ofType<Alias>(),
            constants: types.ofType<Constant>(),
            location: location,
            attributes: attributes);            
    }

    factory Namespace.empty({
        required Identifier name, 
        SourceLocation? location,
        List<Attribute>? attributes})
    {
        return Namespace(            
            ident: name,
            state: DefinitionState.complete,
            location: location,
            attributes: attributes);            
    }

    @override
    String toString() => "namespace $ident ${state.name}";
}

class Import extends Definition
    with Declarer<CompilationUnit>
{
    String path;
    Identifier? prefix;
    CompilationUnit importedUnit;

    Import({
        required this.path,
        required this.importedUnit,
        this.prefix,
        super.state,
        super.location,
        super.attributes,
    }) : super(declKind: DeclKind.import);

    @override
    String toString() => Path.basename(path);
}

class CompilationUnit extends DeclarationScope
{
    SourceFile source;
    late TypeScope fileScope;
    List<Import> imports = [];

    late SemanticVersion version;

    final List<NamedDefinition> allDefinitions = [];

    final List<NamedDefinition> allDefinitionsInDependencyOrder = [];

    CompilationUnit({
        required super.ident, 
        required this.source,
        super.namespaces,
        super.enumerations,
        super.interfaces,
        super.structs,
        super.typeAliases,
        super.constants,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.compilation, state: DefinitionState.complete);
    
    factory CompilationUnit.fromNodes(SourceFile source, List<Definition> types)
    {
        types.indexOver((index, element) => element.parentOrder = index);

        return CompilationUnit(
            source: source, 
            ident: Identifier.nameOnly(source.path),
            namespaces: types.ofType<Namespace>(),
            enumerations: types.ofType<Enum>(),
            interfaces: types.ofType<Interface>(),
            structs: types.ofType<Struct>(),
            typeAliases: types.ofType<Alias>(),
            constants: types.ofType<Constant>());
    }

    void addImport(Import import)
    {
        import.parentOrder = _nextParentOrder;

        enclose(import);        
        imports.add(import);

        if (import.state != DefinitionState.complete)
        {
            state = import.state;
        }
    }

    factory CompilationUnit.empty(
        SourceFile source, 
        SourceLocation location,
        List<Attribute>? attributes)
    {
        return CompilationUnit(            
            source: source,
            ident: Identifier.nameOnly(source.path),
            location: location,
            attributes: attributes);            
    }    

    @override
    String toString() => "${state.name} ${Path.basename(ident.name)}";
}

class Enumerant extends InitializedDefinition
    with Declarer<Enum>
{
    Literal value;
    
    Enumerant({
        required super.ident, 
        required this.value,
        required super.computedValue,
        super.initializer,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.enumerant, state: state ?? initializer?.state ?? DefinitionState.complete);

    String get enumQualifiedName => "${declarer.ident.name}.${ident.name}";

    @override
    String toString() => "$ident = $computedValue ${state.name}";
}

class Enum extends TypeDefinition 
{
    List<Enumerant> enumerants;
    TypeReference dataType;
   
    Enum({
        required super.ident, 
        required this.dataType,
        required this.enumerants,
        DefinitionState? state,        
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.$enum)
    {       
        enumerants.indexOver((index, element) => element.parentOrder = index);

        super.state = state ?? (enumerants.arecomplete
            ? DefinitionState.complete
            : DefinitionState.error);
        
        encloseAll(enumerants);
    }

    Enumerant? findEnumerant(String name)
    {
        for (final enumerant in enumerants)
        {
            if (enumerant.ident.name == name)
            {
                return enumerant;
            }
        }

        return null;
    }
   
    @override
    String toString() => "enum $ident ${state.name}";
}

class Field extends TypedDefinition 
    with Declarer<Struct>
    implements InitializedDefinition
{
    Literal? defaultValue;

    Field({
        required super.ident, 
        required super.type,
        required super.computedValue,
        required super.initializer,
        this.defaultValue,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.field)
    {
        super.state = state ?? type.state;
        enclose(defaultValue);
    }
   
    @override
    String toString() => "$type $ident ${defaultValue != null ? defaultValue.toString() : ""} ${state.name}";
}

class Struct extends TypeDefinition 
{
    TypeReference? base;
    List<Field> fields;

    Struct({
        required super.ident, 
        required this.fields,
        this.base,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.struct)
    {
        super.state = state ?? (fields.arecomplete
            ? (base?.state ?? DefinitionState.complete)
            : DefinitionState.error);

        fields.indexOver((index, element) => element.parentOrder = index);
        enclose(base);
        encloseAll(fields);
    }

    @override
    String toString() => "struct $ident ${state.name}";
}

class Alias extends TypeDefinition 
{
    Reference target;
    late Definition resolved;

    bool get istyperef => target is TypeReference;
    bool get isconstref => target is ConstantReference;

    TypeReference get typeref => target as TypeReference;
    ConstantReference get constref => target as ConstantReference;

    Alias({
        required super.ident, 
        required this.target,
        DefinitionState? state,
        super.location,
        super.attributes
    }) : super(declKind: DeclKind.alias)
    {
        super.state = state ?? target.state;
        enclose(target);
    }

    @override
    String toString() => "alias $ident ${state.name}";
}

class Add extends BinaryExpression
{
    Add({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.add);
}

class Power extends BinaryExpression
{
    Power({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.power);
}

class Subtract extends BinaryExpression
{
    Subtract({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.subtract);
}

class Multiply extends BinaryExpression
{
    Multiply({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.multiply);
}

class Divide extends BinaryExpression
{
    Divide({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.divide);
}

class Modulo extends BinaryExpression
{
    Modulo({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.modulo);
}

class Or extends BinaryExpression
{
    Or({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.or);
}

class Xor extends BinaryExpression
{
    Xor({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.xor);
}

class And extends BinaryExpression
{
    And({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.and);
}

class LeftShift extends BinaryExpression
{
    LeftShift({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.leftShift);
}

class RightShift extends BinaryExpression
{
    RightShift({
        required super.lhs,
        required super.rhs,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.rightShift);
}

class Compliment extends UnaryExpression
{
    Compliment({
        required super.expression,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.compliment);
}

class Negate extends UnaryExpression
{
    Negate({
        required super.expression,
        super.state,
        super.location,
        super.attributes,
        super.declaringNode
    }) : super(operator: OperatorKind.negate);
}

enum ValueKind
{
    none,
    int,
    real
}

class ExprValue
{
    NumberKind kind;
    BigInt intValue;
    double realValue;

    bool get hasvalue => kind != NumberKind.none;
    bool get isint => kind.isint;
    bool get isreal => kind.isreal;

    ExprValue({
        required this.kind,
        required this.intValue,
        required this.realValue
    });

    ExprValue.int(this.intValue, this.kind)
        : realValue = 0;
    ExprValue.real(this.realValue, this.kind)
        : intValue = BigInt.zero;
    ExprValue.none()
        : kind = NumberKind.none,
          intValue = BigInt.zero,
          realValue = 0;

    @override
    String toString() 
    {
        return kind == NumberKind.none
            ? "none"
            : kind.isint
                ? "${intValue}d"
                : "${realValue}r";
    }
      
    ExprValue promote(NumberKind newKind)
    {
        if (kind == newKind)
        {
            return this;
        }

        if (newKind.isreal && !kind.isreal)
        {
            realValue = intValue.toDouble();
            kind = NumericLimits.checkReal(realValue, NumberKind.float32)
                ? NumberKind.float32
                : NumberKind.float64;
            
            realValue = intValue as double;
        }

        if (kind.compareTo(newKind) < 0)
        {
            kind = newKind;
        }

        return this;
    }

    bool areEqual(ExprValue other)
    {
        if (kind != other.kind)
        {
            return false;
        }
        if (!hasvalue)
        {
            return true;
        }

        if (kind == ValueKind.int)
        {
            return intValue == other.intValue;
        }

        return realValue == other.realValue;
    }
}

abstract class Expression extends Definition
{
    late TypeReference type;
    bool get isempty => false;
    bool get isNotEmpty => true;
    ExprValue? computedValue;

    Expression get parent => declaringNode is Expression
        ? declaringNode as Expression
        : EmptyExpression.me;

    Expression({
        super.state = DefinitionState.unknown,
        super.location,
        super.declaringNode,
        super.attributes
    }) : super(declKind: DeclKind.expression);
}

class EmptyExpression extends Expression
{
    @override
    bool get isempty => true;
    @override
    bool get isNotEmpty => false;

    EmptyExpression({
        super.state = DefinitionState.unknown,
        super.location,
        super.declaringNode,
        super.attributes
    })
    {
        type = TypeReference.none(location);
    }

    static EmptyExpression get me => _me;
    static final EmptyExpression _me = EmptyExpression(state: DefinitionState.complete);
}

class AssignmentExpression extends Expression
{
    Expression valueExpression;

    AssignmentExpression({
        required this.valueExpression,
        DefinitionState? state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        enclose(valueExpression);
        super.type = valueExpression.type;
        super.state = state ?? valueExpression.state;
    }

    @override
    String toString() => "= $valueExpression";
}

class UnaryExpression extends Expression
{
    OperatorKind operator;
    Expression expression;

    UnaryExpression({
        required this.operator,
        required this.expression,
        DefinitionState? state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        enclose(expression);
        super.type = expression.type;
        super.state = state ?? expression.state;
    }
    
    @override
    String toString() => "$operator$expression";
}

class BinaryExpression extends Expression
{
    OperatorKind operator;
    Expression lhs;
    Expression rhs;

    BinaryExpression({
        required this.operator,
        required this.lhs,
        required this.rhs,
        DefinitionState? state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        enclose(lhs);
        enclose(rhs);
        super.type = lhs.type;
        super.state = state ?? _worstOf(lhs, rhs);
    }
    
    @override
    String toString() => "$lhs ${operator.op} $rhs";

    DefinitionState _worstOf(Expression lhs, Expression rhs)
    {
        if (lhs.state == rhs.state)
        {
            return lhs.state;
        }

        if (lhs.state == DefinitionState.error ||
            rhs.state == DefinitionState.error)
        {
            return DefinitionState.error;
        }

        if (lhs.state == DefinitionState.unknown ||
            rhs.state == DefinitionState.unknown)
        {
            return DefinitionState.unknown;
        }

        return DefinitionState.complete;
    }
}

class ParenExpression extends Expression
{
    Expression nestedExpression;

    ParenExpression({
        required this.nestedExpression,        
        DefinitionState? state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        enclose(nestedExpression);
        super.type = nestedExpression.type;
        super.state = state ?? nestedExpression.state;
    }

    @override
    String toString() => "($nestedExpression)";
}

class LiteralExpression extends Expression
{
    Literal literal;

    LiteralKind get kind => literal.kind;

    LiteralExpression({
        required this.literal,
        DefinitionState? state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        enclose(literal);
        super.type = literal.dataType;
        super.state = state ?? literal.state;
    }

    @override
    String toString() => literal.toString();
}

class ConstantExpression extends Expression
{
    ConstantReference constRef;

    ConstantExpression({
        required this.constRef,
        DefinitionState? state,
        super.location,
        super.attributes,
        super.declaringNode
    })
    {
        super.type = constRef.type;
        super.state = state ?? constRef.state;
    }

    @override
    String toString() => constRef.target.toString();
}

extension _DefinitionListExtension on List<Definition>
{
    List<TElement> ofType<TElement>()
    {
        List<TElement> result = [];

        for (final element in this)
        {
            if (element is TElement)
            {
                result.add(element as TElement);
            }
        }

        return result;
    }

    bool get arecomplete => !any((e) => e.state != DefinitionState.complete);
}
