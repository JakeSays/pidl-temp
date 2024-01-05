import 'kinds.dart';
import 'util.dart';
import 'types.dart';
import 'diagnostics.dart';
import 'parsing/ast.dart';

class VisibleDefinition
{
    final NamedDefinition definition;
    final Import? import;

    DeclKind get declKind => definition.declKind;

    VisibleDefinition({
        required this.definition,
        this.import
    });

    String get qualifiedName => _qualifiedName ??=
        import == null || import!.prefix == null
            ? definition.ident.fullName
            : "${import!.prefix!.fullName}.${definition.ident.fullName}";

    String? _qualifiedName;
}

enum LookupStatus
{
    error,
    found,
    notfound
}

class LookupResult<TType>
{
    LookupStatus status;
    VisibleDefinition? value;

    Import? get import => value?.import;

    TypeDefinition? get asType =>
        status == LookupStatus.found && value!.definition is TypeDefinition
            ? value!.definition as TypeDefinition
            : null;

    TType? get as =>
        status == LookupStatus.found && value!.definition is TType
            ? value!.definition as TType
            : null;

    LookupResult({
        required this.status,
        this.value
    });

    @override
    String toString() => status.name;
}

class ImportedScope
{
    final String? prefix;
    final TypeScope scope;
    final Import import;

    ImportedScope({
        required this.scope,
        required this.import
    }) : prefix = _makePrefix(import);

    List<NamedDefinition>? findInScope(String name)
    {
        if (prefix != null)
        {
            if (!name.startsWith(prefix!))
            {
                return null;
            }

            name = name.substring(prefix!.length);
        }

        return scope.findDefined(name);
    }

    static String? _makePrefix(Import import)
    {
        if (import.prefix == null)
        {
            return null;
        }

        return "${import.prefix!.fullName}.";
    }
}

class TypeScope
{
    final Map<String, List<NamedDefinition>> _definedItems = {};
    final List<ImportedScope> _importedScopes = [];
    final TypeScope? _builtins;
    final Diagnostics diagnostics;
    final CompilationUnit unit;
    final List<DeclarationScope> _containerStack = [];
    late DeclarationScope _activeContainer;

    TypeScope({
        required this.diagnostics,
        required this.unit,
        TypeScope? builtins
    }) : _builtins = builtins
    {
        _activeContainer = unit;
    }

    void pushContainer(DeclarationScope container)
    {
        _containerStack.add(_activeContainer);
        _activeContainer = container;
    }

    void popContainer()
    {
        _activeContainer = _containerStack.removeLast();
    }

    void addDefinedItem(NamedDefinition item)
    {
        item.declaringScope = this;
        unit.allDefinitions.add(item);

        _activeContainer.addMember(item);

        var items = _definedItems[item.ident.fullName];
        if (items == null)
        {
            items = [];
            _definedItems[item.ident.fullName] = items;
        }

        if (!items.contains(item))
        {
            items.add(item);
        }
    }

    void addImportedScope(TypeScope scope, Import import)
    {
        _importedScopes.add(ImportedScope(scope: scope, import: import));
    }

    List<NamedDefinition>? findDefined(String name) => _builtins?.findDefined(name) ?? _definedItems[name];

    List<VisibleDefinition>? findVisible(String name)
    {
        var items = findDefined(name);
        if (items != null)
        {
            return items.map((e) => VisibleDefinition(definition: e)).toList();
        }

        List<VisibleDefinition>? results;
        for (var scope in _importedScopes) 
        {
            items = scope.findInScope(name);
            if (items != null)
            {
                results ??= [];
                results.addAll(items.map((e) => 
                    VisibleDefinition(definition: e, import: scope.import)));
            }
        }

        return results;
    }

    BuiltinTypeDefinition? lookupBuiltin(String name)
    {
        final result = findDefined(name);
        if (result == null ||
            result.first is! BuiltinTypeDefinition)
        {
            return null;
        }

        return result.first as BuiltinTypeDefinition;
    }

    LookupResult<TType> lookupByName<TType>(String name, 
        SyntaxNode relatedNode, [String? errorMessage = "", LookupStatus notfoundStatus = LookupStatus.error])
    {
        final vdefn = findVisible(name);
        if (vdefn == null)
        {
            if (notfoundStatus == LookupStatus.error)
            {
                diagnostics.addIssue(SemanticIssue(
                    code: IssueCode.unknownType,
                    severity: IssueSeverity.error,
                    message: errorMessage != null
                        ? "Unknown type $errorMessage".trim()
                        : null, 
                    related: [relatedNode], 
                    target: relatedNode));
                return LookupResult<TType>(status: LookupStatus.error);
            }
            return LookupResult<TType>(status: LookupStatus.notfound);
        }

        if (vdefn.length > 1)
        {
            createAmbiguousTypesIssue(diagnostics, relatedNode, vdefn, errorMessage);
            return LookupResult<TType>(status: LookupStatus.error);
        }

        if (vdefn[0].definition is! TType)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.typeExpected,
                severity: IssueSeverity.error,
                message: errorMessage != null
                        ? "Expected type $errorMessage"
                        : null, 
                related: [relatedNode], 
                target: relatedNode));
            return LookupResult<TType>(status: LookupStatus.error);
        }

        return LookupResult<TType>(
            status: LookupStatus.found, 
            value: vdefn[0]);
    }

    LookupResult<TType> lookup<TType>(TypeReferenceSyntax node, [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.error])
    {
        final result = lookupByName<TType>(node.name.fullName,
            node, errorMessage, notfoundStatus);
        return result;
    }

    LookupResult<TypeDefinition> lookupType(TypeReferenceSyntax node, 
        [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.error])
    {
        if (node.builtinKind == TypeKind.list)
        {
            return _lookupList(node, errorMessage, notfoundStatus);
        }
        if (node.builtinKind == TypeKind.map)
        {
            return _lookupMap(node);
        }

        return lookup<TypeDefinition>(node, errorMessage, notfoundStatus);
    }

    LookupResult<NamedDefinition> lookupNamedDefinition(TypeReferenceSyntax node, 
        [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.error])
    {
        if (node.builtinKind == TypeKind.list)
        {
            return _lookupList(node, errorMessage, notfoundStatus);
        }
        if (node.builtinKind == TypeKind.map)
        {
            return _lookupMap(node);
        }

        return lookup<NamedDefinition>(node, errorMessage, notfoundStatus);
    }

    TypeReference? _lookupTypeParameter(TypeReferenceSyntax node, 
        [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.error])
    {
        final param = node;
        var argResult = lookup<TypeDefinition>(param, errorMessage, notfoundStatus);
        if (argResult.status != LookupStatus.found)
        {
            return null;
        }

        final argRef = TypeReference(
            target: argResult.as!, 
            import: argResult.import,
            location: param.location, 
            nullable: param.nullable);

        return argRef;
    }

    LookupResult<TypeDefinition> _lookupList(TypeReferenceSyntax node, 
        [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.error])
    {
        final paramRef = _lookupTypeParameter(node.typeParameters[0]);
        if (paramRef == null)
        {
            return LookupResult(status: notfoundStatus);
        }

        final fullName = "list<${paramRef.name.fullName}>";
        
        final result = lookupByName<TypeDefinition>(fullName, node, null, LookupStatus.notfound);
        if (result.status == LookupStatus.found)
        {
            return result;
        }

        final defn = ListDefinition(arg: paramRef, location: node.location, state: DefinitionState.complete);
        _definedItems[fullName] = [defn];

        return LookupResult(status: LookupStatus.found, value: VisibleDefinition(definition: defn));
    }

    LookupResult<TypeDefinition> _lookupMap(TypeReferenceSyntax node, 
        [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.error])
    {
        final keyRef = _lookupTypeParameter(node.typeParameters[0]);
        if (keyRef == null)
        {
            return LookupResult(status: notfoundStatus);
        }

        final valueRef = _lookupTypeParameter(node.typeParameters[1]);
        if (valueRef == null)
        {
            return LookupResult(status: notfoundStatus);
        }
        
        final fullName = "map<${keyRef.name.fullName},${valueRef.name.fullName}>";
        
        final result = lookupByName<TypeDefinition>(fullName, node, errorMessage, LookupStatus.notfound);
        if (result.status == LookupStatus.found)
        {
            return result;
        }

        final defn = MapDefinition(keyType: keyRef,
            valueType: valueRef,
            location: node.location, 
            state: DefinitionState.complete);
        _definedItems[fullName] = [defn];

        return LookupResult(status: LookupStatus.found, value: VisibleDefinition(definition: defn));
    }

    LookupResult<Enumerant> lookupEnumerantForLiteral(
        LiteralSyntax lit,
        TypeReferenceSyntax enumType, 
        [String? errorMessage, LookupStatus notfoundStatus = LookupStatus.notfound])
    {
        if (lit.kind != LiteralKindSyntax.identifier)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidValue,
                severity: IssueSeverity.error,
                message: "Literal value of type Enum expected${errorMessage != null ? " $errorMessage" : ""}", 
                related: [enumType], 
                target: lit));
            return LookupResult<Enumerant>(status: LookupStatus.error);
        }

        final lookupResult = lookup<Enum>(enumType, errorMessage, notfoundStatus);
        if (lookupResult.status != LookupStatus.found)
        {
            return LookupResult<Enumerant>(status: lookupResult.status);
        }

        final $enum = lookupResult.as!;

        final ident = lit.value as IdentifierSyntax;

        if (ident.namespace != lookupResult.value!.qualifiedName)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidName,
                severity: IssueSeverity.error,
                message: "Enumerant prefix must match fully qualified Enum type name", 
                related: [enumType], 
                target: ident));
            return LookupResult<Enumerant>(status: LookupStatus.error);
        }

        final enumerant = $enum.findEnumerant(ident.name);
        if (enumerant == null)
        {
            diagnostics.addIssue(SemanticIssue(
                code: IssueCode.unknownEnumerant,
                severity: IssueSeverity.error,
                related: [enumType], 
                target: ident));
            return LookupResult<Enumerant>(status: LookupStatus.error);
        }

        return LookupResult<Enumerant>(status: LookupStatus.found, 
            value: VisibleDefinition(definition: enumerant, import: lookupResult.value!.import));
    }
}
