
enum CommentKind
{
    line,
    block,
    doc
}

enum LiteralParseStatus
{
    success,
    formatError
}

enum OperatorKind
{
    negate(op: "-"),
    none(op: ""),
    compliment(op: "~"),
    add(op: "+"),
    subtract(op: "-"),
    multiply(op: "*"),
    divide(op: "/"),
    modulo(op: "%"),
    or(op: "|"),
    xor(op: "^"),
    and(op: "&"),
    leftShift(op: "<<"),
    rightShift(op: ">>"),
    power(op: "^^");

    final String op;

    const OperatorKind({required this.op});

    bool get isbinary => 
        index != compliment.index &&
        index != negate.index &&
        index != none.index;
}

enum NumberKind implements Comparable<NumberKind>
{
    none,
    int8,
    uint8,
    int16,
    uint16,
    int32,
    uint32,
    int64,
    uint64,
    float32,
    float64;

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

    int get bitWidth => _bitWidth();

    int _bitWidth()
    {
        switch (this)
        {
            case int8:
            case uint8:
                return 8;
            case int16:
            case uint16:
                return 16;
            case int32:
            case uint32:
            case float32:
                return 32;
            case int64:
            case uint64:
            case float64:
                return 64;
            default:
                throw StateError("Cannot obtain bit width");
        }
    }

    operator >(NumberKind other) => index > other.index;
    operator <(NumberKind other) => index < other.index;

    @override
    int compareTo(NumberKind other) => index.compareTo(other.index);
}

enum NumberScale
{
    none(n: ""),
    kilo2(n: "K"),
    kilo10(n: "k"),
    mega2(n: "M"),
    mega10(n: "m"),
    giga2(n: "G"),
    giga10(n: "g"),
    tera2(n: "T"),
    tera10(n: "t"),
    peta2(n: "P"),
    peta10(n: "p"),
    exa2(n: "X"),
    exa10(n: "x"),
    zetta2(n: "Z"),
    zetta10(n: "z"),
    yotta2(n: "Y"),
    yotta10(n: "y");

    final String n;

    const NumberScale({required this.n});
}

enum IntRadix
{
    none(base: 10, prefix: ""),
    decimal(base: 10, prefix: ""),
    hex(base: 16, prefix: "0x"),
    octal(base: 8, prefix: "0o"),
    binary(base: 2, prefix: "0b");

    final int base;
    final String prefix;

    const IntRadix({required this.base, required this.prefix});
}

enum LiteralKind
{
    none,
    nil,
    boolean,
    number,
    string,
    constref,
    enumerantref,
    error
}

enum DeclKind
{
    none,
    nil,
    boolean,
    string,
//    number,
    int8,
    uint8,
    int16,
    uint16,
    int32,
    uint32,
    int64,
    uint64,
    float32,
    float64,
    list,
    map,
    struct,
    alias,
    interface,
    $enum,
    enumerant,
    $void,
    constant,
    field,
    method,
    reference,
    attribute,
    attributeArg,
    parameter,
    identifier,
    literal,
    namespace,
    compilation,
    import,
    expression;

    bool get isvoid => index == $void.index;

    bool get isprimitive => 
        isnumber ||
        index == boolean.index ||
        index == $enum.index;
        
    bool get isnumber =>
        isint ||
        isreal;

    bool get istypedata => isnumber;

    bool get isbuiltin =>
        isnumber ||
        index == string.index ||
        index == boolean.index;
        
    bool get isconstant =>
        isnumber ||
        index == $enum.index ||
        index == string.index ||
        index == boolean.index;

    bool get isfield =>
        isnumber ||
        index == $enum.index ||
        index == string.index ||
        index == boolean.index ||
        index == struct.index ||
        index == list.index ||
        index == map.index ||
        index == alias.index;

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
}

extension DeclKindExtension on DeclKind
{
    NumberKind toNumber()
    {
        switch (this)
        {
            case DeclKind.int8:
                return NumberKind.int8;
            case DeclKind.uint8:
                return NumberKind.uint8;
            case DeclKind.int16:
                return NumberKind.int16;
            case DeclKind.uint16:
                return NumberKind.uint16;
            case DeclKind.int32:
                return NumberKind.int32;
            case DeclKind.uint32:
                return NumberKind.uint32;
            case DeclKind.int64:
                return NumberKind.int64;
            case DeclKind.uint64:
                return NumberKind.uint64;
            case DeclKind.float32:
                return NumberKind.float32;
            case DeclKind.float64:
                return NumberKind.float64;
            default:
                return NumberKind.none;
        }
    }
}

extension NumberKindExtension on NumberKind
{
    DeclKind toDecl()
    {
        switch (this)
        {
            case NumberKind.none:
                return DeclKind.none;
            case NumberKind.int8:
                return DeclKind.int8;
            case NumberKind.uint8:
                return DeclKind.uint8;
            case NumberKind.int16:
                return DeclKind.int16;
            case NumberKind.uint16:
                return DeclKind.uint16;
            case NumberKind.int32:
                return DeclKind.int32;
            case NumberKind.uint32:
                return DeclKind.uint32;
            case NumberKind.int64:
                return DeclKind.int64;
            case NumberKind.uint64:
                return DeclKind.uint64;
            case NumberKind.float32:
                return DeclKind.float32;
            case NumberKind.float64:
                return DeclKind.float64;
        }
    }
}

extension NumberScaleExtension on NumberScale
{
    BigInt get value 
    {
        switch (this)
        {
            case NumberScale.none:
                return BigInt.one;
            case NumberScale.kilo2:
                return _k2;
            case NumberScale.kilo10:
                return _k10;
            case NumberScale.mega2:
                return _m2;
            case NumberScale.mega10:
                return _m10;
            case NumberScale.giga2:
                return _g2;
            case NumberScale.giga10:
                return _g10;
            case NumberScale.tera2:
                return _t2;
            case NumberScale.tera10:
                return _t10;
            case NumberScale.peta2:
                return _p2;
            case NumberScale.peta10:
                return _p10;
            case NumberScale.exa2:
                return _e2;
            case NumberScale.exa10:
                return _e10;
            case NumberScale.zetta2:
                return _z2;
            case NumberScale.zetta10:
                return _z10;
            case NumberScale.yotta2:
                return _y2;
            case NumberScale.yotta10:
                return _y10;
            default:
                throw StateError("Bad juju!");
        }
    }

    static final _k2 = BigInt.from(1024);
    static final _k10 = BigInt.from(1000);
    static final _m2 = _k2.pow(2);
    static final _m10 = _k10.pow(2);
    static final _g2 = _k2.pow(3);
    static final _g10 = _k10.pow(3);
    static final _t2 = _k2.pow(4);
    static final _t10 = _k10.pow(4);
    static final _p2 = _k2.pow(5);
    static final _p10 = _k10.pow(5);
    static final _e2 = _k2.pow(6);
    static final _e10 = _k10.pow(6);
    static final _z2 = _k2.pow(7);
    static final _z10 = _k10.pow(7);
    static final _y2 = _k2.pow(8);
    static final _y10 = _k10.pow(8);
}
