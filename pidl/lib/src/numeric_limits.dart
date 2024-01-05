import 'kinds.dart' show NumberKind;

class IntRange
{
    final BigInt min;
    final BigInt max;

    IntRange({
        required this.min,
        required this.max
    });

    bool check(BigInt target) => target >= min && target <= max;
}

class RealRange
{
    final double min;
    final double max;

    RealRange({
        required this.min,
        required this.max
    });

    bool check(double target) => target >= min && target <= max;
}

class NumericLimits
{
    static IntRange _n(int min, int max) => IntRange(min: BigInt.from(min), max: BigInt.from(max));
    
    static final int8 = _n(-128, 127);
    static final uint8 = _n(0, 255);
    static final int16 = _n(-32768, 32767);
    static final uint16 = _n(0, 65535);
    static final int32 = _n(-2147483648, 2147483647);
    static final uint32 = _n(0, 4294967295);
    static final int64 = _n(-9223372036854775808, 9223372036854775807);
    static final uint64 = IntRange(min: BigInt.zero, max: BigInt.parse("0xFFFFFFFFFFFFFFFF"));
    static final float32 = RealRange(min: -3.40282347E+38, max: 3.40282347E+38);
    static final float64 = RealRange(min: -1.7976931348623157E+308, max: 1.7976931348623157E+308);

    static bool checkInt(BigInt value, NumberKind kind)
    {
        switch (kind)
        {            
            case NumberKind.none:
                return false;
            case NumberKind.int8:
                return int8.check(value);
            case NumberKind.uint8:
                return uint8.check(value);
            case NumberKind.int16:
                return int16.check(value);
            case NumberKind.uint16:
                return uint16.check(value);
            case NumberKind.int32:
                return int32.check(value);
            case NumberKind.uint32:
                return uint32.check(value);
            case NumberKind.int64:
                return int64.check(value);
            case NumberKind.uint64:
                return uint64.check(value);
            default:
                throw StateError("Kind does not represent an integer");
        }
    }

    static bool checkReal(double value, NumberKind kind)
    {
        if (kind == NumberKind.float32)
        {
            return float32.check(value);
        }
        if (kind == NumberKind.float64)
        {
            return float64.check(value);
        }

        throw StateError("Kind does not represent a real");
    }
}