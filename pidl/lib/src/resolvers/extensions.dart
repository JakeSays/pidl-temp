import 'package:pidl/src/source.dart';

import '../type_scope.dart';
import '../parsing/ast.dart';
import '../types.dart';
import '../diagnostics.dart';
import '../util.dart';

extension IntExtension on int
{
    bool inrange(int min, int max) => this >= min && this <= max;
}

extension IdentifierSyntaxExtension on IdentifierSyntax
{
    Identifier definition()
    {
        final ident = Identifier(
            name: name,
            namespace: namespace,
            location: location);
        return ident;
    }
}

extension TypeKindExtesion on TypeKind
{
    NumberKind asnum()
    {
        switch (this)
        {
            case TypeKind.float32:
                return NumberKind.float32;
            case TypeKind.float64:
                return NumberKind.float64;
            case TypeKind.int8:
                return NumberKind.int8;
            case TypeKind.uint8:
                return NumberKind.uint8;
            case TypeKind.int16:
                return NumberKind.int16;
            case TypeKind.uint16:
                return NumberKind.uint16;
            case TypeKind.int32:
                return NumberKind.int32;
            case TypeKind.uint32:
                return NumberKind.uint32;
            case TypeKind.int64:
                return NumberKind.int64;
            case TypeKind.uint64:
                return NumberKind.uint64;
            default:
                throw StateError("Invalid type kind");
        }
    }

    DeclKind asdecl()
    {
        switch (this)
        {
            case TypeKind.none:
                return DeclKind.none;
            case TypeKind.boolean:
                return DeclKind.boolean;
            case TypeKind.string:
                return DeclKind.string;
            case TypeKind.list:
                return DeclKind.list;
            case TypeKind.map:
                return DeclKind.map;
            case TypeKind.struct:
                return DeclKind.struct;
            case TypeKind.alias:
                return DeclKind.alias;
            case TypeKind.interface:
                return DeclKind.interface;
            case TypeKind.$enum:
                return DeclKind.$enum;
            case TypeKind.$void:
                return DeclKind.$void;
            case TypeKind.float32:
                return DeclKind.float32;
            case TypeKind.float64:
                return DeclKind.float64;
            case TypeKind.int8:
                return DeclKind.int8;
            case TypeKind.uint8:
                return DeclKind.uint8;
            case TypeKind.int16:
                return DeclKind.int16;
            case TypeKind.uint16:
                return DeclKind.uint16;
            case TypeKind.int32:
                return DeclKind.int32;
            case TypeKind.uint32:
                return DeclKind.uint32;
            case TypeKind.int64:
                return DeclKind.int64;
            case TypeKind.uint64:
                return DeclKind.uint64;
            default:
                throw StateError("Invalid type kind");
        }
    }
}

extension NumberKindExtension on NumberKind
{
    TypeKind asTypeKind()
    {
        switch (this)
        {
            case NumberKind.float32:
                return TypeKind.float32;
            case NumberKind.float64:
                return TypeKind.float64;
            case NumberKind.int8:
                return TypeKind.int8;
            case NumberKind.uint8:
                return TypeKind.uint8;
            case NumberKind.int16:
                return TypeKind.int16;
            case NumberKind.uint16:
                return TypeKind.uint16;
            case NumberKind.int32:
                return TypeKind.int32;
            case NumberKind.uint32:
                return TypeKind.uint32;
            case NumberKind.int64:
                return TypeKind.int64;
            case NumberKind.uint64:
                return TypeKind.uint64;
            case NumberKind.none:
                return TypeKind.none;
        }        
    }
}

extension DeclKindExtension on DeclKind
{
    TypeKind asTypeKind()
    {
        switch (this)
        {
            case DeclKind.none:
                return TypeKind.none;
            case DeclKind.boolean:
                return TypeKind.boolean;
            case DeclKind.string:
                return TypeKind.string;
            case DeclKind.list:
                return TypeKind.list;
            case DeclKind.map:
                return TypeKind.map;
            case DeclKind.struct:
                return TypeKind.struct;
            case DeclKind.alias:
                return TypeKind.alias;
            case DeclKind.interface:
                return TypeKind.interface;
            case DeclKind.$enum:
                return TypeKind.$enum;
            case DeclKind.$void:
                return TypeKind.$void;
            case DeclKind.float32:
                return TypeKind.float32;
            case DeclKind.float64:
                return TypeKind.float64;
            case DeclKind.int8:
                return TypeKind.int8;
            case DeclKind.uint8:
                return TypeKind.uint8;
            case DeclKind.int16:
                return TypeKind.int16;
            case DeclKind.uint16:
                return TypeKind.uint16;
            case DeclKind.int32:
                return TypeKind.int32;
            case DeclKind.uint32:
                return TypeKind.uint32;
            case DeclKind.int64:
                return TypeKind.int64;
            case DeclKind.uint64:
                return TypeKind.uint64;
            default:
                return TypeKind.none;            
        }
    }
}

enum LiteralStatus
{
    error,
    success,
    notFound;

    bool get iserror => index == error.index;
    bool get issuccess => index == success.index;
    bool get isnotfound => index == notFound.index;
}

class LiteralWithStatus
{
    LiteralStatus status;
    Literal? value;

    LiteralWithStatus({
        required this.status,
        this.value
    });

    LiteralWithStatus.success(this.value)
        : status = LiteralStatus.success;

    LiteralWithStatus.error([SourceLocation? location])
        : status = LiteralStatus.error
    {
        value = Literal.error(location);
    }

    LiteralWithStatus.notFound()
        : status = LiteralStatus.notFound;
}

extension LiteralSyntaxExtension on LiteralSyntax
{
    Number toNumber(TypeReference targetType, TypeKind kind)
    {
        return Number(
            value: value!, 
            kind: kind.asnum(), 
            radix: radix?.radix ?? IntRadix.none, 
            scale: scale.value, 
            type: targetType);
    }

    LiteralWithStatus toSemanticLiteral(
        TypeScope scope, 
        TypeReference targetType, 
        TypeReferenceSyntax targetTypeSyntax,
        [LookupStatus notfoundStatus = LookupStatus.error])
    {
        if (status != LiteralParseStatus.success)
        {
            scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.illFormedLiteral,
                severity: IssueSeverity.error,
                message: value != null ? value as String : null,
                related: [declaringNode!], 
                target: this));
            return LiteralWithStatus.error();
        }

        if (kind == LiteralKindSyntax.nil)
        {
            if (targetType.nullable)
            {
                return LiteralWithStatus.success(Literal.nil(targetType, location));
            }

            scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.nullValueNotAllowed,
                severity: IssueSeverity.error,
                related: [declaringNode!], 
                target: this));
            return LiteralWithStatus.error();
        }

        if (targetType.target.declKind == DeclKind.$enum)
        {
            final result = scope.lookupEnumerantForLiteral(this, targetTypeSyntax, null, notfoundStatus);
            if (result.status == LookupStatus.error)
            {
                return LiteralWithStatus.error();
            }
            if (result.status == LookupStatus.notfound)
            {
                return LiteralWithStatus.notFound();
            }

            return LiteralWithStatus.success(Literal.enumerantref(result.as!, targetType, location));
        }

        if (kind == LiteralKindSyntax.identifier)
        {
            final ident = value as IdentifierSyntax;

            final result = scope.lookupByName<Constant>(ident.fullName, this);
            if (result.status == LookupStatus.error)
            {
                return LiteralWithStatus.error();
            }
            if (result.status == LookupStatus.notfound)
            {
                return LiteralWithStatus.notFound();
            }

            final constResult = valueConsistentForType(targetType.targetKind.asTypeKind(), result.as!.value);

            if (constResult == ConsistentResult.invalidType)
            {
                scope.diagnostics.addIssue(SemanticIssue(
                    code: IssueCode.invalidValueType,
                    severity: IssueSeverity.error,
                    message: "Unexpected const type for literal value", 
                    related: [declaringNode!], 
                    target: this));
                return LiteralWithStatus.error();
            }

            if (constResult == ConsistentResult.outOfRange)
            {
                scope.diagnostics.addIssue(SemanticIssue(
                    code: IssueCode.outOfRange,
                    severity: IssueSeverity.error,
                    related: [declaringNode!], 
                    target: this));
                return LiteralWithStatus.error();
            }

            return LiteralWithStatus.success(Literal.constref(result.as!, result.import, targetType, location));
        }

        final result = valueConsistentForType(targetType.targetKind.asTypeKind(), value);

        if (result == ConsistentResult.invalidType)
        {
            scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.invalidValueType,
                severity: IssueSeverity.error,
                message: "Unexpected literal value type", 
                related: [declaringNode!], 
                target: this));
            return LiteralWithStatus.error();
        }

        if (result == ConsistentResult.outOfRange)
        {
            scope.diagnostics.addIssue(SemanticIssue(
                code: IssueCode.outOfRange,
                severity: IssueSeverity.error,
                related: [declaringNode!], 
                target: this));
            return LiteralWithStatus.error();
        }

        var realValue = value;

        LiteralKind litKind;
        switch(kind)
        {           
            case LiteralKindSyntax.boolean:
                litKind = LiteralKind.boolean;
                break;
            case LiteralKindSyntax.int:
            case LiteralKindSyntax.real:
                litKind = LiteralKind.number;
                realValue = toNumber(targetType, targetTypeSyntax.builtinKind);
                break;
            case LiteralKindSyntax.string:
                litKind = LiteralKind.string;
                break;
            default:
                throw UnsupportedError("Should never reach here!");
        }

        return LiteralWithStatus.success(Literal(value: realValue, kind: litKind, dataType: targetType));
    }
}