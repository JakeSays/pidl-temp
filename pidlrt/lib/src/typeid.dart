

enum TypeId
{
//Compatible with the standard flutter codec
    //static const int Unused = 5;
    Null(value: 0),
    True(value: 1),
    False(value: 2),
    Int32(value: 3),
    UInt64(value: 4),
    Float64(value: 6),
    string(value: 7),
    UInt8List(value: 8),
    Int32List(value: 9),
    Int64List(value: 10),
    Float32(value: 11),
    List(value: 12),
    Map(value: 13),
    Float32List(value: 14),

    //Extensions
    Int8(value: 100),
    UInt8(value: 101),
    Int16(value: 102),
    UInt16(value: 103),
    Uint32(value: 104),
    Int64(value: 105),
    Object(value: 106),
    ObjectRef(value: 107),
    Int8List(value: 108),
    Int16List(value: 109),
    UInt16List(value: 110),
    UInt32List(value: 111),
    UInt64List(value: 112),
    Float64List(value: 113),
    BoolList(value: 114),
    StringList(value: 115),
    EncodableValue(value: 116),
    Error(value: 117);

    final int value;

    const TypeId({required this.value});
    
    static String typeIdName(TypeId value) => value.name;

    @override
    String toString() => this.name;

    bool get isint =>
        index == TypeId.Int8.index ||
        index == TypeId.UInt8.index ||
        index == TypeId.Int16.index ||
        index == TypeId.UInt16.index ||
        index == TypeId.Int32.index ||
        index == TypeId.Uint32.index ||
        index == TypeId.Int64.index ||
        index == TypeId.UInt64.index;

    bool get isfloat =>
        index == TypeId.Float32 ||
        index == TypeId.Float64;
}

