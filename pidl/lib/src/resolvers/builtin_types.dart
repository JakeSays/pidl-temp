import '../types.dart';

final builtinTypes = 
[
    BuiltinTypeDefinition(declKind: DeclKind.nil),
    BuiltinTypeDefinition(declKind: DeclKind.boolean),
    BuiltinTypeDefinition(declKind: DeclKind.string),
    BuiltinTypeDefinition(declKind: DeclKind.float32, numberKind: NumberKind.float32),
    BuiltinTypeDefinition(declKind: DeclKind.float64, numberKind: NumberKind.float64),
    BuiltinTypeDefinition(declKind: DeclKind.int8, numberKind: NumberKind.int8),
    BuiltinTypeDefinition(declKind: DeclKind.uint8, numberKind: NumberKind.uint8),
    BuiltinTypeDefinition(declKind: DeclKind.int16, numberKind: NumberKind.int16),
    BuiltinTypeDefinition(declKind: DeclKind.uint16, numberKind: NumberKind.uint16),
    BuiltinTypeDefinition(declKind: DeclKind.int32, numberKind: NumberKind.int32),
    BuiltinTypeDefinition(declKind: DeclKind.uint32, numberKind: NumberKind.uint32),
    BuiltinTypeDefinition(declKind: DeclKind.int64, numberKind: NumberKind.int64),
    BuiltinTypeDefinition(declKind: DeclKind.uint64, numberKind: NumberKind.uint64),
    BuiltinTypeDefinition(declKind: DeclKind.list),
    BuiltinTypeDefinition(declKind: DeclKind.map),
    BuiltinTypeDefinition(declKind: DeclKind.$void),
];

// Map<DeclKind, BuiltinTypeDefinition> _builtins()
// {

//     final types = 
//     {
//         DeclKind.none: BuiltinTypeDefinition(declKind: DeclKind.none),
//         DeclKind.boolean: BuiltinTypeDefinition(declKind: DeclKind.boolean),
//         DeclKind.string: BuiltinTypeDefinition(declKind: DeclKind.string),
//         DeclKind.float32: BuiltinTypeDefinition(declKind: DeclKind.float32),
//         DeclKind.float64: BuiltinTypeDefinition(declKind: DeclKind.float64),
//         DeclKind.int8: BuiltinTypeDefinition(declKind: DeclKind.int8),
//         DeclKind.uint8: BuiltinTypeDefinition(declKind: DeclKind.uint8),
//         DeclKind.int16: BuiltinTypeDefinition(declKind: DeclKind.int16),
//         DeclKind.uint16: BuiltinTypeDefinition(declKind: DeclKind.uint16),
//         DeclKind.int32: BuiltinTypeDefinition(declKind: DeclKind.int32),
//         DeclKind.uint32: BuiltinTypeDefinition(declKind: DeclKind.uint32),
//         DeclKind.int64: BuiltinTypeDefinition(declKind: DeclKind.int64),
//         DeclKind.uint64: BuiltinTypeDefinition(declKind: DeclKind.uint64),
//         DeclKind.list: BuiltinTypeDefinition(declKind: DeclKind.list),
//         DeclKind.map: BuiltinTypeDefinition(declKind: DeclKind.map),
//         DeclKind.struct: BuiltinTypeDefinition(declKind: DeclKind.struct),
//         DeclKind.alias: BuiltinTypeDefinition(declKind: DeclKind.alias),
//         DeclKind.interface: BuiltinTypeDefinition(declKind: DeclKind.interface),
//         DeclKind.$enum: BuiltinTypeDefinition(declKind: DeclKind.$enum),
//         DeclKind.$void: BuiltinTypeDefinition(declKind: DeclKind.$void),
//     };

//     return types;
// }
