import 'errors.dart';

import 'read_write_buffers.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'typeid.dart';
//import 'errors.dart';

extension _IntExtension on int
{
    bool inrange(int min, int max) => this >= min && this <= max;
}

bool _checkIntValue(TypeId kind, int value)
{
    switch (kind)
    {           
        case TypeId.Int8:
            return value.inrange(-128, 127);
        case TypeId.UInt8:
            return value.inrange(0, 255);
        case TypeId.Int16:
            return value.inrange(-32768, 32767);
        case TypeId.UInt16:
            return value.inrange(0, 65535);
        case TypeId.Int32:
            return value.inrange(-2147483648, 2147483647);
        case TypeId.Uint32:
            return value.inrange(0, 4294967295);
        case TypeId.Int64:
            return value.inrange(-9223372036854775808, 9223372036854775807);
        case TypeId.UInt64:
            return true;
        default:
            return false;
    }
}

bool _checkFloatValue(TypeId kind, double value)
{
    if (kind == TypeId.Float32 &&
        value >= -3.40282347E+38 &&
        value <= 3.40282347E+38)
    {
        return true;
    }

    if (kind == TypeId.Float64)
    {
        return true;
    }

    return false;
}

void _checkValue(Object value, TypeId kind)
{
    if (kind.isint)
    {
        if (!_checkIntValue(kind, value as int))
        {
            throw NumericRangeError(kind);
        }

        return;
    }

    if (kind.isfloat && !_checkFloatValue(kind, value as double))
    {
        throw NumericRangeError(kind);
    }
}

class BinaryWriter
{
    BinaryWriter({required bool trackObjects, required bool tagged})
        : _trackObjects = trackObjects,
          _tagged = tagged;

    final PluginWriteBuffer _buffer = PluginWriteBuffer();
    final Map<Object, int> _objectMap = <Object, int>{};
    final bool _trackObjects;
    final bool _tagged;

    int _nextObjectId = 1;

    ByteData done() => _buffer.done();

    void writeNull()
    {
        _buffer.putUInt8(TypeId.Null.value);
    }

    void writeBool(bool value) =>
        _writeBool(value, tagged: _tagged);
    void writeFloat32(double value) =>
        _writeFloat32(value, tagged: _tagged);
    void writeFloat64(double value) =>
        _writeFloat64(value, tagged: _tagged);
    void writeInt16(int value) =>
        _writeInt16(value, tagged: _tagged);
    void writeInt32(int value) =>
        _writeInt32(value, tagged: _tagged);
    void writeInt64(int value) =>
        _writeInt64(value, tagged: _tagged);
    void writeInt8(int value) =>
        _writeInt8(value, tagged: _tagged);
    void writeString(String value) =>
        _writeString(value, tagged: _tagged);
    void writeUInt16(int value) =>
        _writeUInt16(value, tagged: _tagged);
    void writeUInt32(int value) =>
        _writeUInt32(value, tagged: _tagged);
    void writeUInt64(int value) =>
        _writeUInt64(value, tagged: _tagged);
    void writeUInt8(int value) =>
        _writeUInt8(value, tagged: _tagged);

    void _writeBool(bool value, {bool tagged = false})
    {
        if (tagged)
        {
            _buffer.putUInt8(value ? TypeId.True.value : TypeId.False.value);
        }
        else
        {
            _buffer.putUInt8(value ? 0xFF : 0x00);
        }
    }

    void _writeUInt8(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.UInt8);

        if (tagged)
        {
            _buffer.putUInt8(TypeId.UInt8.value);
        }
        _buffer.putUInt8(value);
    }

    void _writeUInt16(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.UInt16);

        if (tagged)
        {
            _buffer.putUInt8(TypeId.UInt16.value);
        }
        _buffer.putUInt16(value);
    }

    void _writeUInt32(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.Uint32);

        if (tagged)
        {
            _buffer.putUInt8(TypeId.Uint32.value);
        }
        _buffer.putUInt32(value);
    }

    void _writeUInt64(int value, {bool tagged = false})
    {
        if (tagged)
        {
            _buffer.putUInt8(TypeId.UInt64.value);
        }
        _buffer.putInt64(value);
    }

    void _writeInt8(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.Int8);

        if (tagged)
        {
            _buffer.putUInt8(TypeId.Int8.value);
        }
        _buffer.putUInt8(value);
    }

    void _writeInt16(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.Int16);

        if (tagged)
        {
            _buffer.putUInt8(TypeId.Int16.value);
        }
        _buffer.putUInt16(value);
    }

    void _writeInt32(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.Int32);
        if (tagged)
        {
            _buffer.putUInt8(TypeId.Int32.value);
        }
        _buffer.putUInt32(value);
    }

    void _writeInt64(int value, {bool tagged = false})
    {
        _checkValue(value, TypeId.Int64);
        if (tagged)
        {
            _buffer.putUInt8(TypeId.Int64.value);
        }
        _buffer.putInt64(value);
    }

    void _writeFloat32(double value, {bool tagged = false})
    {
        _checkValue(value, TypeId.Float32);        
        if (tagged)
        {
            _buffer.putUInt8(TypeId.Float32.value);
        }
        _buffer.putFloat32(value);
    }

    void _writeFloat64(double value, {bool tagged = false})
    {
        if (tagged)
        {
            _buffer.putUInt8(TypeId.Float64.value);
        }
        _buffer.putFloat64(value);
    }

    void _writeString(String value, {bool tagged = false})
    {
        if (tagged)
        {
            _buffer.putUInt8(TypeId.string.value);
        }
        if (value.length == 0)
        {
            writeSize(0);
            return;
        }
        final Uint8List bytes = utf8.encoder.convert(value);
        writeSize(bytes.length);
        _buffer.putUInt8List(bytes);
    }

    void beginMap(int size, int keyType, int elementType, {bool tagged = false})
    {
        if (tagged)
        {
            _buffer.putUInt8(TypeId.Map.value);
        }
        _buffer.putUInt32(size);
        // _buffer.putUInt8(keyType);
        // _buffer.putUInt8(elementType);
    }

    void beginList(int size, {bool tagged = false})
    {
        if (tagged)
        {
            _buffer.putUInt8(TypeId.List.value);
        }
        writeSize(size);
    }

    bool _beginList(List? list, TypeId tag, bool tagged, [bool nullable = false])
    {
        if (list == null && nullable == false)
        {
            throw NullValueError();
        }

        if (tagged)
        {
            if (list == null)
            {
                writeNull();
                return false;
            }
            _buffer.putUInt8(tag.value);
        }
        if (list == null)
        {
            writeSize(0);
            return false;
        }

        writeSize(list.length);
        return list.length > 0;
    }

    bool _beginTypedList(TypedData? list, TypeId tag, bool tagged, [bool nullable = false])
    {
        if (list == null && nullable == false)
        {
            throw NullValueError();
        }

        if (tagged)
        {
            if (list == null)
            {
                writeNull();
                return false;
            }
            _buffer.putUInt8(tag.value);
        }
        if (list == null)
        {
            writeSize(0);
            return false;
        }
        final elementCount = list.lengthInBytes / list.elementSizeInBytes;
        writeSize(elementCount as int);
        return elementCount > 0;
    }

    void writeTypedData(TypedData data, TypeId kind) =>
        _writeTypedData(data, kind, allowNull: false);

    void writeNullableTypedData(TypedData? data, TypeId kind) =>
        _writeTypedData(data, kind, allowNull: true);

    void _writeTypedData(TypedData? data, TypeId kind, {bool tagged = false, bool allowNull = false})
    {
        if (!_beginTypedList(data, kind, tagged, allowNull))
        {
            return;
        }

        int alignment;
        switch(kind)
        {
        case TypeId.Int8List:
        case TypeId.UInt8List:
            alignment = 1;
            break;
        case TypeId.Int16List:
        case TypeId.UInt16List:
            alignment = 2;
            break;
        case TypeId.Int32List:
        case TypeId.UInt32List:
        case TypeId.Float32List:
            alignment = 4;
            break;
        case TypeId.Int64List:
        case TypeId.UInt64List:
        case TypeId.Float64List:
            alignment = 8;
            break;
        default:
            throw ArgumentError.value(kind);
        }

        _buffer.putTypedData(data!, alignment);
    }


    void writeNullableStringList(List<String>? value)
    {
        if (!_beginList(value, TypeId.StringList, true, true))
        {
            return;
        }
        for (var str in value!) 
        {
            writeNullableString(str);
        }
    }

    void writeBoolList(List<bool>? value, {bool tagged = false})
    {
        if (!_beginList(value, TypeId.BoolList, tagged, false))
        {
            return;
        }

        for (var b in value!)
        {
            _writeBool(b, tagged: false);
        }
    }

    void writeNullableBoolList(List<bool>? value)
    {
        if (!_beginList(value, TypeId.Int8List, true, true))
        {
            return;
        }
        for (var b in value!)
        {
            _writeBool(b, tagged: false);
        }
    }

    void writeNullableBool(bool? value)
    {        
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeBool(value, tagged: true);
    }

    void writeNullableInt8(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeInt8(value, tagged: true);
    }

    void writeNullableUInt8(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeUInt8(value, tagged: true);
    }

    void writeNullableInt16(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeInt16(value, tagged: true);
    }

    void writeNullableUInt16(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeUInt16(value, tagged: true);
    }

    void writeNullableInt32(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeInt32(value, tagged: true);
    }

    void writeNullableUInt32(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeUInt32(value, tagged: true);
    }

    void writeNullableInt64(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeInt64(value, tagged: true);
    }

    void writeNullableUInt64(int? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeUInt64(value, tagged: true);
    }

    void writeNullableFloat32(double? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeFloat32(value, tagged: true);
    }

    void writeNullableFloat64(double? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeFloat64(value, tagged: true);
    }

    void writeNullableString(String? value)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        _writeString(value, tagged: true);
    }

    void writeObject<TObject>(TObject value, Function encoder, {bool tagged = false})
    {
        if (_trackObjects)
        {
            var objectId = _objectMap[value];
            if (objectId != null)
            {
                _buffer.putUInt8(TypeId.ObjectRef.value);
                writeSize(objectId);
                return;
            }

            objectId = _nextObjectId++;
            _objectMap[value as Object] = objectId;
            _buffer.putUInt8(TypeId.Object.value);
            writeSize(objectId);
        }
        else if (tagged)
        {
            _buffer.putUInt8(TypeId.Object.value);
        }

        encoder(this, value, tagged: tagged);
    }

    void writeNullableObject<TObject>(TObject? value, Function encoder)
    {
        if (value == null)
        {
            writeNull();
            return;
        }

        writeObject<TObject>(value, encoder, tagged: true);
    }

    void writeObjectList<TObject>(List<TObject> list, Function encoder, {bool tagged = false})
    {
        beginList(list.length);
        if (list.isEmpty)
        {
            return;
        }

        for (var item in list)
        {
            writeObject(item, encoder, tagged: tagged);
        }
    }

    void writeNullableObjectList<TObject>(List<TObject?> list, Function encoder, {bool tagged = false})
    {
        beginList(list.length);
        if (list.isEmpty)
        {
            return;
        }

        for (var item in list)
        {
            writeNullableObject(item, encoder);
        }
    }

    /// Writes a non-negative 32-bit integer [value] to [_buffer]
    /// using an expanding 1-5 byte encoding that optimizes for small values.
    void writeSize(int value) 
    {
        assert(0 <= value && value <= 0xffffffff);
        if (value < 254) 
        {
            _buffer.putUInt8(value);
        }
        else if (value <= 0xffff) 
        {
            _buffer.putUInt8(254);
            _buffer.putUInt16(value);
        }
        else 
        {
            _buffer.putUInt8(255);
            _buffer.putUInt32(value);
        }
    }
}
