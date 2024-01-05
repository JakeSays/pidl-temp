import 'package:pidl/src/types.dart';

import 'numeric_limits.dart';
import 'kinds.dart';

extension ListExtension<TElement> on List<TElement>
{
    void indexOver(void Function(int index, TElement element) predicate)
    {
        var index = 0;

        for (final element in this)
        {
            predicate(index++, element);
        }
    }
}

extension BigIntExtension on BigInt
{
    NumberKind get kind
    {
        if (NumericLimits.uint8.check(this))
        {
            return NumberKind.uint8;
        }
        if (NumericLimits.int8.check(this))
        {
            return NumberKind.int8;
        }
        if (NumericLimits.int16.check(this))
        {
            return NumberKind.int16;
        }
        if (NumericLimits.int32.check(this))
        {
            return NumberKind.int32;
        }
        if (NumericLimits.uint32.check(this))
        {
            return NumberKind.uint32;
        }
        if (NumericLimits.int64.check(this))
        {
            return NumberKind.int64;
        }
        if (NumericLimits.uint64.check(this))
        {
            return NumberKind.uint64;
        }

        return NumberKind.none;
    }
}

extension DoubleExtension on double
{
    NumberKind get kind => NumericLimits.float32.check(this)
        ? NumberKind.float32
        : NumberKind.float64;
}