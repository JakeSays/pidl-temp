import 'dart:typed_data';
import 'util.dart';

//Note: this class has NOTHING to do with semver.
class SemanticVersion
{
    final int _a;
    final int _b;
    final int _c;
    final int _d;

    int get a => _a;
    int get b => _b;
    int get c => _c;
    int get d => _d;

    const SemanticVersion(int a, int b, int c, int d)
        : _a = a,
          _b = b,
          _c = c,
          _d = d;

    static const unknown = SemanticVersion(0, 0, 0, 0);

    bool get isvalid => _a > 0 && _b > 0 && _c > 0 && _d > 0;

    String format(String separator) => _hexEncode(separator);

    @override
    String toString() => _hexEncode("-");

    @override
    int get hashCode => Object.hashAll([_a, _b, _c, _d]);

    @override
    bool operator==(Object other)
    {
        if (other is! SemanticVersion)
        {
            return false;
        }

        return _a == other._a &&
            _b == other._b &&
            _c == other._c &&
            _d == other._d;
    }

    String _hexEncode(String? separator) => "${formatIntAsHex(_a)}$separator${formatIntAsHex(_b)}$separator${formatIntAsHex(_c)}$separator${formatIntAsHex(_d)}";

    String _hexEncode_(String? separator) 
    {
        const hexDigits = '0123456789ABCDEF';
        const zerocu = 48;
        const xcu = 120;

        final byteLength = 4 * 4;
        final textLength = byteLength * 2 + 8;
        final dashCount = separator != null
            ? 3 * separator.length
            : 0;

        var charCodes = Uint8List(textLength + dashCount);
        var charIndex = 0;

        void encode(int value)
        {
            charCodes[charIndex++] = hexDigits.codeUnitAt((value >> 4) & 0xF);
            charCodes[charIndex++] = hexDigits.codeUnitAt(value & 0xF);            
        }

        var first = true;
        final sepdata = separator?.runes.toList();

        for (final value in [_a, _b, _c, _d])
        {
            if (!first && separator != null)
            {
                for(final sep in sepdata!)
                {
                    charCodes[charIndex++] = sep;
                }
            }

            first = false;

            charCodes[charIndex++] = zerocu;
            charCodes[charIndex++] = xcu;
            
            encode(value & 0xFF);
            encode((value >> 8) & 0xFF);
            encode((value >> 16) & 0xFF);
            encode((value >> 24) & 0xFF);
        }

        return String.fromCharCodes(charCodes);
    }
}
