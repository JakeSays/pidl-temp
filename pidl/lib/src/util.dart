import 'source.dart';
import 'resolvers/extensions.dart';
import 'types.dart';
import 'type_scope.dart';
import 'diagnostics.dart';
import 'parsing/ast.dart';
import 'dart:typed_data';
import "dart:math" as Math;
import "numeric_limits.dart";

TypeReference makeTypeRef(TypeDefinition defn, Import? import, [SourceLocation? location, bool isnullable = false])
    => TypeReference(
            target: defn,
            import: import,
            nullable: isnullable,
            location: location ?? defn.location);

bool intWithinRangeForType(TypeKind kind, BigInt value)
{
    final numberKind = kind.asnum();
    return NumericLimits.checkInt(value, numberKind);
}

bool realWithinRangeForType(TypeKind kind, double value)
{
    final numberKind = kind.asnum();
    return NumericLimits.checkReal(value, numberKind);}

enum ConsistentResult
{
    yes,
    outOfRange,
    invalidType,
    nullValue
}

Object? _dereferenceValue(Object? value)
{
    if (value == null)
    {
        return null;
    }

    if (value is Literal)
    {
        return _dereferenceValue(value.value);
    }

    if (value is LiteralExpression)
    {
        return _dereferenceValue(value.literal.value);
    }

    if (value is ConstantReference)
    {
        return _dereferenceValue(value.value);
    }

    if (value is EnumerantReference)
    {
        return _dereferenceValue(value.target.value);
    }

    if (value is bool ||
        value is String ||
        value is double ||
        value is BigInt ||
        value is Number)
    {
        return value;        
    }

    throw StateError("bad juju!");
}

ConsistentResult valueConsistentForType(TypeKind kind, Object? value, [bool nullAllowed = false])
{
    if (value == null)
    {
        return nullAllowed
            ? ConsistentResult.yes
            : ConsistentResult.nullValue;
    }

    value = _dereferenceValue(value);

    switch (kind)
    {
        case TypeKind.boolean:
            return value is bool
                ? ConsistentResult.yes
                : ConsistentResult.invalidType;
        case TypeKind.string:
            return value is String
                ? ConsistentResult.yes
                : ConsistentResult.invalidType;
        case TypeKind.float32:
        case TypeKind.float64:
            if (value is double)
            {
                return realWithinRangeForType(kind, value)
                    ? ConsistentResult.yes
                    : ConsistentResult.outOfRange;
            }
            if (value is Number)
            {
                if (!value.kind.isreal)
                {
                    return ConsistentResult.invalidType;
                }
                return realWithinRangeForType(kind, value.asreal)
                    ? ConsistentResult.yes
                    : ConsistentResult.outOfRange;
            }
            return ConsistentResult.invalidType;
        case TypeKind.int8:
        case TypeKind.uint8:
        case TypeKind.int16:
        case TypeKind.uint16:
        case TypeKind.int32:
        case TypeKind.uint32:
        case TypeKind.int64:
        case TypeKind.uint64:
            if (value is BigInt)
            {
                return intWithinRangeForType(kind, value)
                    ? ConsistentResult.yes
                    : ConsistentResult.outOfRange;
            }
            if (value is Number)
            {
                if (!value.kind.isint)
                {
                    return ConsistentResult.invalidType;
                }
                return intWithinRangeForType(kind, value.asint)
                    ? ConsistentResult.yes
                    : ConsistentResult.outOfRange;
            }
            return ConsistentResult.invalidType;
        default:
            return ConsistentResult.invalidType;
    }
}

void createAmbiguousTypesIssue(Diagnostics diagnostics, 
    SyntaxNode target,
    List<Object> types,
    [String? targetMessage = "for type"])
{
    final message = StringBuffer();
    message.writeln("Ambiguous definitions found $targetMessage:");
    for (final type in types)
    {
        if (type is NamedDefinition)
        {
            message.writeln("    ${type.ident} at ${type.location}");
        }
        else if (type is VisibleDefinition)
        {
            message.writeln("    ${type.qualifiedName} at ${type.definition.location}");
        }
    }

    diagnostics.addIssue(SemanticIssue(
        code: IssueCode.ambiguousTypes,
        severity: IssueSeverity.warning,
        message: message.toString(), 
        related: [], 
        target: target));
}

void validateAttributes(Diagnostics diagnostics, 
    SyntaxNode node, 
    Set<String> allowed, 
    [String? message])
{
    if (node.attributesChecked ||
        node.attributes == null)
    {
        return;
    }

    node.attributesChecked = true;
    for (final attr in node.attributes!.list.where((attr) => !allowed.contains(attr.name.fullName)))
    {
        diagnostics.addIssue(SemanticIssue(
            code: IssueCode.unknownAttribute,
            severity: IssueSeverity.warning,
            message: message ?? "Unexpected or unknown attribute '${attr.name}'", 
            related: [], 
            target: attr));
    }
}

String formatIntAsHex(int value,
    {int bitWidth = 32, bool upperCase = true, bool withPrefix = true})
{
    if (bitWidth != 8 &&
        bitWidth != 16 &&
        bitWidth != 32 &&
        bitWidth != 64)
    {
        throw ArgumentError("bitWidth must be 8, 16, 32, or 64", "bitWidth");        
    }

    final maxValue = ((bitWidth == 64
        ? -1
        : Math.pow(2, bitWidth)) as int) - 1;
    
    if (value > maxValue)
    {
        throw ArgumentError("value is too large for bit width", "value");        
    }

    var hex = _hexEncode(value, bitWidth);
    if (!upperCase)
    {
        hex = hex.toLowerCase();
    }

    if (withPrefix)
    {
        hex = "0x$hex";
    }

    return hex;
}

String _hexEncode(int value, int bitWidth) 
{
    const hexDigits = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];

    final int charSize = (bitWidth ~/ 8) * 2;

    var charCodes = Uint8List(charSize);
    var charIndex = 0;

    void encode(int value)
    {
        charCodes[charIndex++] = hexDigits[value & 0xF];
        charCodes[charIndex++] = hexDigits[(value >> 4) & 0xF];
    }

    while (bitWidth > 0)
    {
        final byte = value & 0xFF;
        value = value >>> 8;
        encode(byte);
        bitWidth -= 8;
    }

    return String.fromCharCodes(charCodes.reversed);
}

String _binaryEncode(int value, int bitWidth) 
{
    const zero = 48;
    const one = 49;

    final int charSize = bitWidth;

    var charCodes = Uint8List(charSize);
    var charIndex = 0;

    while (bitWidth > 0)
    {
        final byte = value & 0x1;
        value = value >>> 1;
        charCodes[charIndex++] = byte != 0 ? one : zero;
        bitWidth -= 1;
    }

    return String.fromCharCodes(charCodes.reversed);
}
