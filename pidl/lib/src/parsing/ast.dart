import 'package:meta/meta.dart';
import 'package:path/path.dart' as Path;
import '../source.dart';
import 'ast_visitor.dart';
import '../type_scope.dart';
import '../kinds.dart';

class ParseFailure
{
    SourceLocation location;
    int depth;
    String? message;

    ParseFailure({
        required this.location,
        required this.depth,
        this.message
    });
}

enum OperatorKindSyntax
{
    negate(op: "-"),
    subtract(op: "-"),
    add(op: "+"),
    multiply(op: "*"),
    divide(op: "/"),
    modulo(op: "%"),
    or(op: "|"),
    xor(op: "^"),
    and(op: "&"),
    leftShift(op: "<<"),
    rightShift(op: ">>"),
    compliment(op: "~"),
    power(op: "^^");

    final String op;

    const OperatorKindSyntax({required this.op});
}

enum LiteralKindSyntax
{
    nil,
    boolean,
    int,
    real,
    string,
    identifier,
    error
}

enum TypeKind
{
    none,
    boolean,
    string,
    float32,
    float64,
    int8,
    uint8,
    int16,
    uint16,
    int32,
    uint32,
    int64,
    uint64,
    list,
    map,
    struct,
    alias,
    interface,
    $enum,
    $void;

    bool get isint => 
        index == int8.index ||
        index == uint8.index ||
        index == int16.index ||
        index == uint16.index ||
        index == int32.index ||
        index == uint32.index ||
        index == int64.index ||
        index == uint64.index;

    bool get isreal => 
        index == float32.index || 
        index == float64.index;

    bool get isconstant =>
        isint || isreal ||
        index == $enum.index ||
        index == string.index ||
        index == boolean.index; 
}

class SyntaxNode extends LocationProvider
{
    bool _isvalid = true;

    AttributesSyntax? attributes;
    SyntaxNode? declaringNode;
    CommentsSyntax? attachedComments;
    int parseDepth = -1;
    
    bool get isvalid => _isvalid;

    //used in semantic analysis
    bool attributesChecked = false;

    SyntaxNode({
        super.location,
        this.attributes,
        this.declaringNode,
        this.attachedComments
    })
    {
        encloseAll(attributes?.list);
        encloseAll(attachedComments?.list);
    }

    SyntaxNode._makeinvalid() {_isvalid = false;}

    static final SyntaxNode nil = SyntaxNode._makeinvalid();

    AttributeSyntax? findAttribute(String name)
    {
        if (attributes == null)
        {
            return null;
        }

        for(final attr in attributes!.list)
        {
            if (attr.name.fullName == name)
            {
                return attr;
            }
        }

        return null;
    }

    void enclose(SyntaxNode? child, [bool keepExisting = true]) 
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
    void encloseAll(Iterable<SyntaxNode>? children, [bool keepExisting = true]) 
    {
        children?.forEach((node) => enclose(node, keepExisting));
    }

    void accept(AstVisitor visitor)
    {
        visitor.visit(this);
    }
}

class KeywordSyntax extends SyntaxNode
{
    String keyword;

    KeywordSyntax({
        required this.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });

    KeywordSyntax.none({
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    }) : keyword = "";

    @override
    String toString() => keyword;

    TokenSyntax toToken() => TokenSyntax(token: keyword, location: location);
}

class TokenSyntax extends SyntaxNode
{
    String token;

    TokenSyntax({
        required this.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });

    TokenSyntax.none({
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    }) : token = "";

    @override
    String toString() => token;
}

class NamespaceKeywordSyntax extends KeywordSyntax
{
    NamespaceKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ImportKeywordSyntax extends KeywordSyntax
{
    ImportKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class StructKeywordSyntax extends KeywordSyntax
{
    StructKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class InterfaceKeywordSyntax extends KeywordSyntax
{
    InterfaceKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class AliasKeywordSyntax extends KeywordSyntax
{
    AliasKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class AsKeywordSyntax extends KeywordSyntax
{
    AsKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class BaseSeparatorKeywordSyntax extends KeywordSyntax
{
    BaseSeparatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class NullKeywordSyntax extends KeywordSyntax
{
    NullKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class BooleanKeywordSyntax extends KeywordSyntax
{
    BooleanKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class StringKeywordSyntax extends KeywordSyntax
{
    StringKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class Float32KeywordSyntax extends KeywordSyntax
{
    Float32KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class Float64KeywordSyntax extends KeywordSyntax
{
    Float64KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class Int8KeywordSyntax extends KeywordSyntax
{
    Int8KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class UInt8KeywordSyntax extends KeywordSyntax
{
    UInt8KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class Int16KeywordSyntax extends KeywordSyntax
{
    Int16KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class UInt16KeywordSyntax extends KeywordSyntax
{
    UInt16KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class Int32KeywordSyntax extends KeywordSyntax
{
    Int32KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class UInt32KeywordSyntax extends KeywordSyntax
{
    UInt32KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class Int64KeywordSyntax extends KeywordSyntax
{
    Int64KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class UInt64KeywordSyntax extends KeywordSyntax
{
    UInt64KeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ListKeywordSyntax extends KeywordSyntax
{
    ListKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class MapKeywordSyntax extends KeywordSyntax
{
    MapKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class EnumKeywordSyntax extends KeywordSyntax
{
    EnumKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class VoidKeywordSyntax extends KeywordSyntax
{
    VoidKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class NegativeOperatorKeywordSyntax extends KeywordSyntax
{
    NegativeOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class SubtractOperatorKeywordSyntax extends KeywordSyntax
{
    SubtractOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class AddOperatorKeywordSyntax extends KeywordSyntax
{
    AddOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class MultiplyOperatorKeywordSyntax extends KeywordSyntax
{
    MultiplyOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class DivideOperatorKeywordSyntax extends KeywordSyntax
{
    DivideOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ModuloOperatorKeywordSyntax extends KeywordSyntax
{
    ModuloOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class OrOperatorKeywordSyntax extends KeywordSyntax
{
    OrOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class XorOperatorKeywordSyntax extends KeywordSyntax
{
    XorOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class AndOperatorKeywordSyntax extends KeywordSyntax
{
    AndOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class LeftShiftOperatorKeywordSyntax extends KeywordSyntax
{
    LeftShiftOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class RightShiftOperatorKeywordSyntax extends KeywordSyntax
{
    RightShiftOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class NegateOperatorKeywordSyntax extends KeywordSyntax
{
    NegateOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class PowerOperatorKeywordSyntax extends KeywordSyntax
{
    PowerOperatorKeywordSyntax({
        required super.keyword,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class StringDelimiterTokenSyntax extends TokenSyntax
{
    StringDelimiterTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ParenOpenTokenSyntax extends TokenSyntax
{
    ParenOpenTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ParenCloseTokenSyntax extends TokenSyntax
{
    ParenCloseTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class DocCommentTokenSyntax extends TokenSyntax
{
    DocCommentTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class SingleLineCommentTokenSyntax extends TokenSyntax
{
    SingleLineCommentTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class MultiLineCommentOpenTokenSyntax extends TokenSyntax
{
    MultiLineCommentOpenTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class MultiLineCommentCloseTokenSyntax extends TokenSyntax
{
    MultiLineCommentCloseTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class AttributeOpenTokenSyntax extends TokenSyntax
{
    AttributeOpenTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class AttributeCloseTokenSyntax extends TokenSyntax
{
    AttributeCloseTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ScopeOpenTokenSyntax extends TokenSyntax
{
    ScopeOpenTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class ScopeCloseTokenSyntax extends TokenSyntax
{
    ScopeCloseTokenSyntax({
        required super.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class NumberScaleSyntax extends SyntaxNode
{
    NumberScale value;

    bool get hasValue => value != NumberScale.none;

    NumberScaleSyntax({
        required this.value,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });

    NumberScaleSyntax.none({
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    }) : value = NumberScale.none;

    @override
    String toString() => hasValue ? value.n : "n";
}

class RadixSyntax extends TokenSyntax
{
    IntRadix radix;

    bool get hasRadix => radix != IntRadix.none;

    RadixSyntax({
        required super.token,
        required this.radix,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });

    RadixSyntax.none({
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments})
        : radix = IntRadix.none,
          super(token: "");
    
    @override
    String toString() => radix.prefix;
}

mixin Declarer<TType> on SyntaxNode
{
    TType get declarer => declaringNode as TType;
}

class ListSyntax<TNode> extends SyntaxNode
{
    List<TNode> list;

    ListSyntax({
        List<TNode>? list,
        super.location,
        super.attachedComments
    }) : list = list ?? [];

    @override
    String toString() => "${list.length}";
}

class ImportSyntax extends SyntaxNode
    with Declarer<CompilationUnitSyntax>
{
    KeywordSyntax importKeyword;
    LiteralSyntax importPath;
    KeywordSyntax? asKeyword;
    IdentifierSyntax? scope;
    CompilationUnitSyntax? unit;
    TokenSyntax semicolon;

    String get path => importPath.value as String;

    ImportSyntax({
        required this.importKeyword,
        required this.importPath,
        required this.semicolon,
        this.asKeyword,
        this.scope,
        super.location,
        super.attributes,
    })
    {
        enclose(importPath);
        enclose(scope);
    }

    @override
    String toString() => Path.basename(path);
}

class ScopeSyntax extends SyntaxNode
{
    ScopeSyntax({        
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
}

class CommentSyntax extends SyntaxNode
{
    CommentKind kind;
    String text;

    CommentSyntax({
        required this.kind,
        required this.text,
        super.location
    });
}

class CommentsSyntax extends ListSyntax<CommentSyntax>
{
    void addComment(CommentSyntax comment) => list.add(comment);

    CommentsSyntax({
        super.list,
        super.location
    });
}

class AttributeArgSyntax extends NamedSyntax
    with Declarer<AttributeSyntax>
{
    LiteralSyntax? value;

    AttributeArgSyntax({
        required super.name,
        this.value,
        super.location,
        super.attachedComments
    })
    {
        enclose(name);
        enclose(value);
    }

    static final AttributeArgSyntax noarg = AttributeArgSyntax(name: IdentifierSyntax.unnamed);

    @override
    String toString() 
    {           
        return value != null
            ? "$name = $value"
            : "$name";
    }
}

class AttributeArgsSyntax extends ListSyntax<AttributeArgSyntax>
{
    AttributeArgsSyntax({
        
        super.list,
        super.location
    });

    static final AttributeArgsSyntax none = AttributeArgsSyntax(list: []);
}

class AttributeSyntax extends NamedSyntax
{
    IdentifierSyntax? category;
    AttributeArgsSyntax? args;

    AttributeSyntax({
        required super.name,
        this.category,
        this.args,
        super.location,
        super.attachedComments
    })
    {
        enclose(category);
        encloseAll(args?.list);
    }

    @override
    String toString() 
    {
        final name = category != null
            ? "$category:${super.name}"
            : super.name;
        return "$name (${args?.list.length ?? 0})";
    }
}

class AttributesSyntax extends ListSyntax<AttributeSyntax>
{
    AttributesSyntax({
        super.list,
        super.location
    });

    static final AttributesSyntax none = AttributesSyntax(list: []);
}

class IdentNamespaceSyntax extends SyntaxNode
{
    TokenSyntax namespaceToken;
    TokenSyntax separator;
    IdentNamespaceSyntax? get next => _next;

    String text;
    String textdot;

    IdentNamespaceSyntax({        
        required this.namespaceToken,
        required this.separator,
        super.location,
        super.attributes,
        super.attachedComments
    }) : text = namespaceToken.token,
         textdot = "${namespaceToken.token}${separator.token}";

    IdentNamespaceSyntax? _next;

    void setNext(IdentNamespaceSyntax ns)
    {
        _next = ns;
        text = "$textdot${ns.text}";
        textdot = "$textdot${ns.textdot}";
    }

    @override
    String toString() => text;
}

class IdentifierSyntax extends SyntaxNode implements Comparable<IdentifierSyntax>
{
    IdentNamespaceSyntax? originalNamesapce;
    TokenSyntax? separator;
    IdentNamespaceSyntax? namespacePart;
    TokenSyntax nameToken;
    
    String? get namespace => namespacePart?.text;
    String get name => nameToken.token;

    String fullName;

    bool get namespaceOverridden => originalNamesapce != null;

    @override
    bool operator==(Object other) 
    {
        return other is IdentifierSyntax &&
            runtimeType == other.runtimeType &&
            fullName == other.fullName;
    }

    @override
    int get hashCode => fullName.hashCode;
    
    IdentifierSyntax({        
        required this.nameToken,
        this.separator,
        this.namespacePart,
        super.location,
        super.attributes,
        super.attachedComments
    }) : fullName = namespacePart != null
        ? '${namespacePart.textdot}${nameToken.token}'
        : nameToken.token;

    static const String _nonameTag = r"$$unnamed";

    static final IdentifierSyntax unnamed = IdentifierSyntax(nameToken: 
        TokenSyntax(token: _nonameTag, location: SourceLocation.unknown), location: SourceLocation.unknown);

    bool get isunnamed => name == _nonameTag;
    
    void updateNamespace(IdentifierSyntax newns)
    {
        originalNamesapce = namespacePart;
        namespacePart = IdentNamespaceSyntax(
            namespaceToken: newns.nameToken, 
            separator: TokenSyntax(token: "."),
            location: newns.location);

        fullName = namespacePart != null
            ? '${namespacePart!.textdot}$name'
            : name;
    }
/*
    factory IdentifierSyntax.parse(String fullName, 
        [SourceLocation? location, AttributesSyntax? attributes])
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

        return IdentifierSyntax(            
            name: namePart, 
            namespace: namespacePart, 
            location: location,
            attributes: attributes);
    }

    IdentifierSyntax.nameOnly(this.fullName, 
        [SourceLocation? location, AttributesSyntax? attributes])
        : name = fullName,
            super(location: location, attributes: attributes);
*/            
    @override
    String toString() => fullName;
    
    @override
    int compareTo(IdentifierSyntax other) => fullName.compareTo(other.fullName);
}

class StringSyntax extends SyntaxNode
{
    TokenSyntax startDelim;
    TokenSyntax endDelim;
    TokenSyntax value;

    String get string => value.token;

    StringSyntax({
        required this.value,
        required this.startDelim,
        required this.endDelim,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });

    @override
    String toString() => "$startDelim$string$endDelim";
}

class LiteralSyntax extends SyntaxNode
{
    LiteralKindSyntax kind;
    LiteralParseStatus status;
    RadixSyntax? radix;
    NumberScaleSyntax scale;
    int separatorSpacing;
    KeywordSyntax? keyword;
    TokenSyntax? valueSyntax;
    Object? value;

    LiteralSyntax({        
        required this.kind,
        required this.status,
        required this.radix,
        required this.valueSyntax,
        required NumberScaleSyntax? scale,
        this.value,
        this.separatorSpacing = 0,
        super.location,
        super.attributes,
        super.attachedComments
    }) : scale = scale ?? NumberScaleSyntax.none()
    {
        enclose(scale);
    }

    LiteralSyntax.int(this.value, this.valueSyntax, this.radix, this.scale, this.separatorSpacing, [SourceLocation? location, AttributesSyntax? attributes])
        : kind = LiteralKindSyntax.int,
          status = LiteralParseStatus.success,
          super(attributes: attributes, location: location);

    LiteralSyntax.boolean(this.value, this.keyword, [SourceLocation? location, AttributesSyntax? attributes])
        : kind = LiteralKindSyntax.boolean,
          status = LiteralParseStatus.success,
          separatorSpacing = 0,
          scale = NumberScaleSyntax.none(location: location),
          super(attributes: attributes, location: location);

    LiteralSyntax.real(this.value, this.valueSyntax, [SourceLocation? location, AttributesSyntax? attributes])
        : kind = LiteralKindSyntax.real,
          status = LiteralParseStatus.success,
          separatorSpacing = 0,
          scale = NumberScaleSyntax.none(location: location),
          super(attributes: attributes, location: location);
        
    LiteralSyntax.string(StringSyntax value, [SourceLocation? location, AttributesSyntax? attributes])
        : value = value,
          kind = LiteralKindSyntax.string,
          status = LiteralParseStatus.success,
          separatorSpacing = 0,
          scale = NumberScaleSyntax.none(location: location),
          super(attributes: attributes, location: location);
        
    LiteralSyntax.nil(this.value, this.keyword, [SourceLocation? location, AttributesSyntax? attributes])
        : kind = LiteralKindSyntax.nil,
          status = LiteralParseStatus.success,
          separatorSpacing = 0,
          scale = NumberScaleSyntax.none(location: location),
          super(attributes: attributes, location: location);

    LiteralSyntax.ident(this.value, [SourceLocation? location, AttributesSyntax? attributes])
        : kind = LiteralKindSyntax.identifier,
          status = LiteralParseStatus.success,
          separatorSpacing = 0,
          scale = NumberScaleSyntax.none(location: location),
          super(attributes: attributes, location: location);

    LiteralSyntax.error(this.value, this.kind, [SourceLocation? location, AttributesSyntax? attributes])
        : status = LiteralParseStatus.formatError,
          separatorSpacing = 0,
          scale = NumberScaleSyntax.none(location: location),
          super(attributes: attributes, location: location);

    LiteralSyntax negate()
    {
        if (kind == LiteralKindSyntax.int)
        {
            value = -(value! as int);
            return this;
        }
        if (kind == LiteralKindSyntax.real)
        {
            value = -(value! as double);
            return this;
        }
        return this;
    }    

    @override
    String toString() 
    {
        switch(kind)
        {            
            case LiteralKindSyntax.nil:
                return "nil";
            case LiteralKindSyntax.boolean:
                return (value as bool) ? "true" : "false";
            case LiteralKindSyntax.int:
                return "${value}i";
            case LiteralKindSyntax.real:
                return "${value}r";
            case LiteralKindSyntax.string:
                return value.toString();
            case LiteralKindSyntax.identifier:
                return value.toString();
            case LiteralKindSyntax.error:
                return "<err>";
        }
    }
}

class NamedSyntax extends ScopeSyntax
{
    IdentifierSyntax name;

    NamedSyntax({
        
        required this.name,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(name);
    }
}

typedef ReferenceCreator<TReference extends TypeReferenceSyntax> = TReference Function({
        required IdentifierSyntax name, 
        required KeywordSyntax keyword,
        bool? nullable,
        List<SyntaxNode>? typeParameters,
        SourceLocation? location,
        AttributesSyntax? attributes,
        CommentsSyntax? attachedComments,
        TypeKind? builtinKind});

TypeReferenceSyntax CreateTypeReference({
        required IdentifierSyntax name, 
        required KeywordSyntax keyword,
        bool? nullable,
        List<SyntaxNode>? typeParameters,                
        SourceLocation? location,
        AttributesSyntax? attributes,
        CommentsSyntax? attachedComments,
        TypeKind? builtinKind})
{
    List<TypeReferenceSyntax>? params;
    TokenSyntax? leftAngle;
    TokenSyntax? rightAngle;

    if (typeParameters != null)
    {
        leftAngle = typeParameters[0] as TokenSyntax;
        rightAngle = typeParameters[1] as TokenSyntax;
        params = typeParameters.whereType<TypeReferenceSyntax>().toList();
    }
    final ref = TypeReferenceSyntax(
        name: name,
        keyword: keyword,
        nullable: nullable ?? false,
        typeParameters: params,
        location: location,
        attributes: attributes,
        attachedComments: attachedComments,
        builtinKind: builtinKind ?? TypeKind.none);

    ref.leftAngleToken = leftAngle;
    ref.rightAngleToken = rightAngle;

    return ref;
}

class TypeReferenceSyntax extends NamedSyntax
{
    KeywordSyntax keyword;
    TokenSyntax? leftAngleToken;
    TokenSyntax? rightAngleToken;
    final List<TypeReferenceSyntax> typeParameters;

    bool nullable;
    TypeKind builtinKind;

    TypeReferenceSyntax({
        required super.name, 
        required this.keyword,
        this.leftAngleToken,
        this.rightAngleToken,
        this.nullable = false,
        List<TypeReferenceSyntax>? typeParameters,
        super.location,
        super.attributes,
        super.attachedComments,
        this.builtinKind = TypeKind.none
    }) : typeParameters = typeParameters ?? []
    {
        encloseAll(typeParameters);
    }
        
    @override
    String toString() 
    {
        if (_text == null)
        {
            final sb = StringBuffer();
            sb.write(name);
            if (typeParameters.isNotEmpty)
            {
                sb.write("<");
                final last = typeParameters.last;
                for (final param in typeParameters)
                {
                    sb.write(param);
                    if (param != last)
                    {
                        sb.write(", ");
                    }
                }
                sb.write(">");
            }

            if (nullable)
            {
                sb.write("?");
            }

            _text = sb.toString();
        }
        return _text!;
    }

    String? _text;
}

class InitializedSyntax extends NamedSyntax
{
    AssignmentExpressionSyntax initializer;

    InitializedSyntax({        
        required super.name,
        AssignmentExpressionSyntax? initializer,
        super.location,
        super.attributes,
        super.attachedComments
    }) : initializer = initializer ?? AssignmentExpressionSyntax.empty(location)
    {
        enclose(initializer);
    }
}

class TypedSyntax extends InitializedSyntax
{
    TypeReferenceSyntax type;

    TypedSyntax({        
        required super.name, 
        required this.type,
        super.initializer,
        super.location,
        super.attributes,
        super.attachedComments
    })
    {
        enclose(type);
    }
}

class TypeDefinitionSyntax extends NamedSyntax 
{    
    final bool isBuiltin;
    bool isNullable;
    List<TypeReferenceSyntax> typeArguments;
    TypeKind typeKind;
    KeywordSyntax keyword;
    TokenSyntax openScopeToken;
    TokenSyntax closeScopeToken;
    
    TypeDefinitionSyntax({
        required super.name,
        required this.keyword,
        required this.openScopeToken,
        required this.closeScopeToken,
        List<TypeReferenceSyntax>? typeArguments,
        this.isNullable = false,
        this.typeKind = TypeKind.none,
        super.location,
        super.attributes,
        super.attachedComments,
        this.isBuiltin = false
    }) : typeArguments = typeArguments ?? []
    {
        encloseAll(typeArguments);
    }
}

class ConstantSyntax extends TypedSyntax 
{
    KeywordSyntax keyword;
    AssignmentExpressionSyntax value;
    TokenSyntax semicolon;
    
    @override
    AssignmentExpressionSyntax get initializer => value;

    ConstantSyntax({        
        required super.name,         
        required super.type,
        required this.value,
        required this.keyword,
        required this.semicolon,
        super.location,
        super.attributes,
        super.attachedComments
    })
    {
        enclose(value);
    }

    @override
    String toString() => "$name $type$value";
}

class ParameterSyntax extends TypedSyntax
    with Declarer<MethodSyntax>
{
    AssignmentExpressionSyntax? get defaultValue => initializer;
    TokenSyntax? separator;

    ParameterSyntax({        
        required super.name,         
        required super.type,
        super.initializer,
        this.separator,
        super.location,
        super.attributes,
        super.attachedComments
    });

    @override
    String toString() 
    {
        return "$type $name";
    }
}

class ParametersSyntax extends ListSyntax<ParameterSyntax>
{
    ParametersSyntax({        
        super.list,
        super.location
    });
}

class MethodSyntax extends TypedSyntax 
    with Declarer<InterfaceSyntax>
{
    ParametersSyntax parameters;
    TokenSyntax openParen;
    TokenSyntax closeParen;
    TokenSyntax semicolon;

    MethodSyntax({        
        required super.name,         
        required super.type,
        required this.parameters,
        required this.semicolon,
        required this.openParen,
        required this.closeParen,
        super.location,
        super.attributes,
        super.attachedComments
    })
    {
        enclose(type);
        encloseAll(parameters.list);
    }

    @override
    String toString() 
    {
        return "$type $name ${parameters.list.length}";
    }
}

class MethodsSyntax extends SyntaxNode
{
    List<MethodSyntax> list;

    MethodsSyntax({        
        required this.list,
        super.location
    });
}

enum BaseKind
{
    interface,
    $enum,
    struct    
}

class BaseTypeSyntax extends TypeReferenceSyntax
{
    KeywordSyntax? extendsKeyword;    
    TokenSyntax? separator;
    BaseKind kind;

    BaseTypeSyntax({        
        required super.name,
        required super.keyword,
        required this.kind,
        this.extendsKeyword,
        this.separator,
        super.nullable = false,
        super.typeParameters,
        super.location,
        super.attributes,
        super.attachedComments,
        super.builtinKind = TypeKind.none        
    });

    static BaseTypeSyntax create({
        required IdentifierSyntax name,
        required BaseKind kind,
        TokenSyntax? separator,
        KeywordSyntax? extendsKeyword,
        bool nullable = false,
        List<SyntaxNode>? typeParameters,
        SourceLocation? location,
        AttributesSyntax? attributes,
        CommentsSyntax? attachedComments,
        TypeKind builtinKind = TypeKind.none,
        KeywordSyntax? keyword
    }) => BaseTypeSyntax(
        name: name,
        kind : kind,
        keyword: keyword ?? KeywordSyntax(keyword: name.fullName, location: name.location),
        extendsKeyword: extendsKeyword,
        separator: separator,
        typeParameters: typeParameters?.whereType<TypeReferenceSyntax>().toList(),
        location: location,
        attributes: attributes,
        attachedComments: attachedComments,
        builtinKind: builtinKind);
}

typedef BaseTypeCreator<TReference extends BaseTypeSyntax> = TReference Function({
        required IdentifierSyntax name,
        required BaseKind kind,
        TokenSyntax? separator,
        KeywordSyntax? extendsKeyword,
        bool nullable,
        List<SyntaxNode>? typeParameters,
        SourceLocation? location,
        AttributesSyntax? attributes,
        CommentsSyntax? attachedComments,
        TypeKind builtinKind,
        KeywordSyntax? keyword});

class BaseInterfacesSyntax extends ListSyntax<BaseTypeSyntax>
{
    BaseInterfacesSyntax({
        super.list,
        super.location
    });
}

class InterfaceSyntax extends TypeDefinitionSyntax
{
    BaseInterfacesSyntax? bases;
    MethodsSyntax? methods;

    InterfaceSyntax({
        required super.name, 
        required this.methods,
        required super.keyword,
        required super.openScopeToken,
        required super.closeScopeToken,
        this.bases,
        super.location,
        super.attributes,
        super.attachedComments
    }) : super(typeKind: TypeKind.interface)
    {
        encloseAll(bases?.list);
        encloseAll(methods?.list);
    }

    @override
    String toString() 
    {
        return "$name";
    }
}

abstract class DeclarationScopeSyntax extends NamedSyntax
{
    final List<NamespaceSyntax> namespaces;
    List<EnumSyntax> enumerations;
    List<InterfaceSyntax> interfaces;
    List<StructSyntax> structs;
    List<TypeAliasSyntax> typeAliases;
    List<ConstantSyntax> constants;
    List<CommentsSyntax> scopeComments;

    DeclarationScopeSyntax({        
        required super.name, 
        List<NamespaceSyntax>? namespaces,
        List<EnumSyntax>? enumerations,
        List<InterfaceSyntax>? interfaces,
        List<StructSyntax>? structs,
        List<TypeAliasSyntax>? typeAliases,
        List<ConstantSyntax>? constants,
        List<CommentsSyntax>? scopeComments,
        super.location,
        super.attachedComments,
        super.attributes
    }) : namespaces = namespaces ?? [],
         enumerations = enumerations ?? [],
         interfaces = interfaces ?? [],
         structs = structs ?? [],
         typeAliases = typeAliases ?? [],
         constants = constants ?? [],
         scopeComments = scopeComments ?? []
    {
        encloseAll(namespaces);
        encloseAll(enumerations);
        encloseAll(interfaces);
        encloseAll(structs);
        encloseAll(typeAliases);
        encloseAll(constants);
        encloseAll(scopeComments);
    }
}

class NamespaceSyntax extends DeclarationScopeSyntax
{
    KeywordSyntax namespaceKeyword;
    TokenSyntax openScopeToken;
    TokenSyntax closeScopeToken;

    NamespaceSyntax({        
        required this.namespaceKeyword,
        required super.name,
        required this.openScopeToken,
        required this.closeScopeToken,
        super.namespaces, 
        super.enumerations,
        super.interfaces,
        super.structs,
        super.typeAliases,
        super.constants,
        super.scopeComments,
        super.location,
        super.attributes,
        super.attachedComments
    });

    factory NamespaceSyntax.fromNodes(
        KeywordSyntax namespaceKw,
        TokenSyntax openScopeToken,
        TokenSyntax closeScopeToken,
        IdentifierSyntax name, 
        List<SyntaxNode> types,
        SourceLocation location,
        AttributesSyntax? attributes,
        CommentsSyntax? attachedComments)
    {
        return NamespaceSyntax(
            namespaceKeyword: namespaceKw,
            openScopeToken: openScopeToken,
            closeScopeToken: closeScopeToken,
            name: name,
            namespaces: types.ofType<NamespaceSyntax>(),
            enumerations: types.ofType<EnumSyntax>(),
            interfaces: types.ofType<InterfaceSyntax>(),
            structs: types.ofType<StructSyntax>(),
            typeAliases: types.ofType<TypeAliasSyntax>(),
            constants: types.ofType<ConstantSyntax>(),
            scopeComments: types.ofType<CommentsSyntax>(),
            location: location,
            attachedComments: attachedComments,
            attributes: attributes);
    }
}

class CompilationUnitSyntax extends DeclarationScopeSyntax
{
    SourceFile source;
    List<ImportSyntax> imports;

    late TypeScope fileScope;

    CompilationUnitSyntax({
        required super.name, 
        required this.source,
        required this.imports,
        super.namespaces,
        super.enumerations,
        super.interfaces,
        super.structs,
        super.typeAliases,
        super.constants,
        super.scopeComments,
        super.location,
        super.attributes
    })
    {
        encloseAll(imports);
    }

    factory CompilationUnitSyntax.fromNodes(SourceFile source, List<SyntaxNode> types)
    {
        return CompilationUnitSyntax(
            source: source, 
            name: IdentifierSyntax(nameToken: TokenSyntax(token: source.path)),
            imports: types.ofType<ImportSyntax>(),
            namespaces: types.ofType<NamespaceSyntax>(),
            enumerations: types.ofType<EnumSyntax>(),
            interfaces: types.ofType<InterfaceSyntax>(),
            structs: types.ofType<StructSyntax>(),
            typeAliases: types.ofType<TypeAliasSyntax>(),
            constants: types.ofType<ConstantSyntax>(),
            scopeComments: types.ofType<CommentsSyntax>());
    }
    
    @override
    String toString() => Path.basename(name.name);
}

extension _NodeFilter on List<SyntaxNode>
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
}

class EnumerantSyntax extends InitializedSyntax
    with Declarer<EnumSyntax>
{  
    TokenSyntax? separator;

    EnumerantSyntax({
        required super.name, 
        super.initializer,
        this.separator,
        super.location,
        super.attributes,
        super.attachedComments
    })
    {
        enclose(initializer);
    }

    @override
    String toString() 
    {
        return initializer.isNotEmpty 
            ? "$name = $initializer" 
            : name.fullName;
    }
}

class EnumerantsSyntax extends ListSyntax<EnumerantSyntax>
{    
    EnumerantsSyntax({
        super.list,
        super.location
    });
}

class EnumSyntax extends TypeDefinitionSyntax 
{
    EnumerantsSyntax? enumerants;
    late BaseTypeSyntax type;

    TypeKind get dataType => type.builtinKind;

    EnumSyntax({
        required super.name,
        required super.keyword, 
        required super.openScopeToken,
        required super.closeScopeToken,
        required this.type,
        this.enumerants,        
        super.location,
        super.attributes,
        super.attachedComments,
    }) : super(typeKind: TypeKind.$enum)
    {
        enclose(type);
        encloseAll(enumerants?.list);
    }

    @override
    String toString() 
    {
        return "$name ${dataType.name}";
    }
}

class FieldSyntax extends TypedSyntax
    with Declarer<StructSyntax>
{
    ExpressionSyntax? get defaultValue => initializer;
    TokenSyntax semicolon;

    FieldSyntax({
        required super.name, 
        required super.type,
        required this.semicolon,
        super.initializer,
        super.location,
        super.attributes,
        super.attachedComments
    });
   
    @override
    String toString() 
    {
        var text = "$type $name";
        if (initializer.isNotEmpty)
        {
            text = "$text = $initializer";
        }
        return text;
    }
}

class FieldsSyntax extends ListSyntax<FieldSyntax>
{
    FieldsSyntax({
        super.list,
        super.location,
        super.attachedComments
    });

    @override
    String toString() => "${list.length}";
}

class StructSyntax extends TypeDefinitionSyntax 
{    
    BaseTypeSyntax? base;
    FieldsSyntax fields;

    StructSyntax({
        required super.name, 
        required super.keyword,
        required super.openScopeToken,
        required super.closeScopeToken,
        required this.fields,
        this.base,
        super.location,
        super.attributes,
        super.attachedComments
    }) : super(typeKind: TypeKind.struct)
    {
        enclose(base);
        encloseAll(fields.list);
    }

    @override
    String toString() => "struct $name ($fields)";
}

class TypeAliasSyntax extends TypeDefinitionSyntax 
{
    TokenSyntax assignmentToken;
    TokenSyntax semicolon;
    TypeReferenceSyntax aliasedType;

    TypeAliasSyntax({
        required super.name, 
        required this.aliasedType,
        required this.assignmentToken,
        required this.semicolon,
        required super.keyword,
        super.typeArguments,
        super.location,
        super.attributes,
        super.attachedComments
    }) : super(typeKind: TypeKind.alias, 
            openScopeToken: TokenSyntax.none(),
            closeScopeToken: TokenSyntax.none())
    {
        enclose(aliasedType);
    }

    @override
    String toString() => "alias $name $assignmentToken $aliasedType";
}

class OperatorSyntax extends SyntaxNode
{
    OperatorKindSyntax kind;
    TokenSyntax token;

    OperatorSyntax({
        required this.kind,
        required this.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(token);
    }

    @override
    String toString() => kind.op;
}

class ExpressionSyntax extends SyntaxNode
{
    bool get isEmpty => _isempty;
    bool get isNotEmpty => !_isempty;

    ExpressionSyntax({
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    }) : _isempty = false;

    ExpressionSyntax.empty(SourceLocation? location)
        : _isempty = true,
          super(location: location);
    
    final bool _isempty;

    @override
    String toString() => _isempty ? "empty" : "expression";  
}

class AssignmentExpressionSyntax extends ExpressionSyntax
{
    TokenSyntax assignmentToken;
    ExpressionSyntax value;

    AssignmentExpressionSyntax({
        required this.assignmentToken,
        required this.value,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    });
    
    AssignmentExpressionSyntax.empty(SourceLocation? location)
        : assignmentToken = TokenSyntax.none(location: location),
          value = ExpressionSyntax.empty(location);

    @override
    String toString() => value.toString();
}

class UnaryExpressionSyntax extends ExpressionSyntax
{
    OperatorSyntax operator;
    ExpressionSyntax expression;

    UnaryExpressionSyntax({
        required this.operator,
        required this.expression,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(operator);
        enclose(expression);
    }
    
    @override
    String toString() => "$operator$expression";
}

class BinaryExpressionSyntax extends ExpressionSyntax
{
    OperatorSyntax operator;
    ExpressionSyntax lhs;
    ExpressionSyntax rhs;

    BinaryExpressionSyntax({
        required this.operator,
        required this.lhs,
        required this.rhs,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(lhs);
        enclose(operator);
        enclose(rhs);
    }
    
    @override
    String toString() => "$lhs $operator $rhs";
}

class ParenExpressionSyntax extends ExpressionSyntax
{
    TokenExpressionSyntax leftParen;
    ExpressionSyntax nestedExpression;
    TokenExpressionSyntax rightParen;

    ParenExpressionSyntax({
        required this.leftParen,
        required this.nestedExpression,
        required this.rightParen,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(leftParen);
        enclose(nestedExpression);
        enclose(rightParen);
    }

    @override
    String toString() => "($nestedExpression)";
}

class LiteralExpressionSyntax extends ExpressionSyntax
{
    LiteralSyntax literal;

    LiteralExpressionSyntax({
        required this.literal,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(literal);
    }

    @override
    String toString() => literal.toString();
}

class TokenExpressionSyntax extends ExpressionSyntax
{
    TokenSyntax token;

    TokenExpressionSyntax({
        required this.token,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(token);
    }

    @override
    String toString() => token.toString();
}

class IdentifierExpressionSyntax extends ExpressionSyntax
{
    IdentifierSyntax identifier;

    IdentifierExpressionSyntax({
        required this.identifier,
        super.location,
        super.attributes,
        super.declaringNode,
        super.attachedComments
    })
    {
        enclose(identifier);
    }

    @override
    String toString() => identifier.toString();
}
