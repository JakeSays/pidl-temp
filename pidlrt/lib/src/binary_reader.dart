import 'package:flutter/services.dart';

import 'read_write_buffers.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'typeid.dart';
import 'errors.dart';

class BinaryReader
{
    PluginReadBuffer? _input;
    final Map<int, Object> _objectMap = <int, Object>{};
    final bool _trackObjects;
    final bool _tagged;

    BinaryReader(this._input, {bool trackObjects = false, bool tagged = false})
        : _trackObjects = trackObjects,
          _tagged = tagged;

    void setData(ByteData data, [int offset = 0])
    {
        _input = PluginReadBuffer(data, offset);
    }

    BinaryReader.fromData(ByteData data, {int offset = 0, bool trackObjects = false, bool tagged = false})
        : _trackObjects = trackObjects,
          _tagged = tagged
    {
        _input = PluginReadBuffer(data, offset);
    }

    PluginReadBuffer get _buffer => _input!;

    bool isNull()
    {
        var isnull = _buffer.peekUint8() == TypeId.Null;
        if (isnull)
        {
            _buffer.advance(1);
        }
        return isnull;
    }

    bool readBool()
    {
        _check(1);
        var type = _buffer.getUint8() as TypeId;
        if (type != TypeId.True && type != TypeId.False)
        {
            throw InvalidTypeError(TypeId.True, type, position: _buffer.position - 1);
        }

        return _buffer.getUint8() == TypeId.True;
    }

    int readInt8()
    {
        _check(_tagged ? 2 : 1);
        if (_tagged)
        {
            _readType(TypeId.Int8);
        }

        return _buffer.getInt8();
    }

    int readUInt8()
    {
        _check(_tagged ? 2 : 1);
        if (_tagged)
        {
            _readType(TypeId.UInt8);
        }

        return _buffer.getUint8();
    }

    int readInt16()
    {
        _check(_tagged ? 3 : 2);
        if (_tagged)
        {
            _readType(TypeId.Int16);
        }

        return _buffer.getInt16();
    }

    int readUInt16()
    {
        _check(_tagged ? 3 : 2);
        if (_tagged)
        {
            _readType(TypeId.UInt16);
        }

        return _buffer.getUint16();
    }

    int readInt32()
    {
        _check(_tagged ? 5 : 4);
        if (_tagged)
        {
            _readType(TypeId.Int32);
        }

        return _buffer.getInt32();
    }

    int readUInt32()
    {
        _check(_tagged ? 5 : 4);
        if (_tagged)
        {
            _readType(TypeId.Uint32);
        }

        return _buffer.getUint32();
    }

    int readInt64()
    {
        _check(_tagged ? 9 : 8);
        if (_tagged)
        {
            _readType(TypeId.Int64);
        }

        return _buffer.getInt64();
    }

    int readUInt64()
    {
        _check(_tagged ? 9 : 8);
        if (_tagged)
        {
            _readType(TypeId.UInt64);
        }

        return _buffer.getUint64();
    }

    double readFloat32()
    {
        _check(_tagged ? 5 : 4);
        if (_tagged)
        {
            _readType(TypeId.Float32);
        }

        return _buffer.getFloat32();
    }

    double readFloat64()
    {
        _check(_tagged ? 9 : 8);
        _readType(TypeId.Float64);

        return _buffer.getFloat64();
    }

    String readString()
    {
        if (_tagged)
        {        
            _check(1);
            _readType(TypeId.string);
        }
        
        var size = _readSize();        
        if (size == 0)
        {
            return "";
        }

        var bytes = _buffer.getUint8List(size);
        return utf8.decoder.convert(bytes);
    }

    void _checkList(TypeId kind)
    {
        if (!_tagged)
        {
            return;
        }
        _check(1);
        _readType(kind);
    }

    int beginList()
    {
        _checkList(TypeId.List);

        final size = _readSize();
        return size;
    }

    Int8List readInt8List()
    {
        _checkList(TypeId.Int8List);
        
        var size = _readSize();
        if (size == 0)
        {
            return Int8List(0);
        }

        return _buffer.getInt8List(size);
    }

    Uint8List readUInt8List()
    {
        _checkList(TypeId.UInt8List);
        var size = _readSize();
        if (size == 0)
        {
            return Uint8List(0);
        }

        return _buffer.getUint8List(size);
    }

    Int16List readInt16List()
    {
        _checkList(TypeId.Int16List);
        var size = _readSize();
        if (size == 0)
        {
            return Int16List(0);
        }

        return _buffer.getInt16List(size);
    }

    Uint16List readUInt16List()
    {
        _checkList(TypeId.UInt16List);
        var size = _readSize();
        if (size == 0)
        {
            return Uint16List(0);
        }

        return _buffer.getUint16List(size);
    }

    Int32List readInt32List()
    {
        _checkList(TypeId.Int32List);
        var size = _readSize();
        if (size == 0)
        {
            return Int32List(0);
        }        

        return _buffer.getInt32List(size);
    }

    Uint32List readUInt32List()
    {
        _checkList(TypeId.UInt32List);
        var size = _readSize();
        if (size == 0)
        {
            return Uint32List(0);
        }

        return _buffer.getUint32List(size);
    }

    Int64List readInt64List()
    {
        _checkList(TypeId.Int64List);
        var size = _readSize();
        if (size == 0)
        {
            return Int64List(0);
        }

        return _buffer.getInt64List(size);
    }

    Uint64List readUInt64List()
    {
        _checkList(TypeId.UInt64List);
        var size = _readSize();
        if (size == 0)
        {
            return Uint64List(0);
        }

        return _buffer.getUint64List(size);
    }

    Float32List readFloat32List()
    {
        _checkList(TypeId.Float32List);
        var size = _readSize();
        if (size == 0)
        {
            return Float32List(0);
        }

        return _buffer.getFloat32List(size);
    }

    Float64List readFloat64List()
    {
        _checkList(TypeId.Float64List);
        var size = _readSize();

        if (size == 0)
        {
            return Float64List(0);
        }

        return _buffer.getFloat64List(size);
    }

    List<bool> readBoolList()
    {
        _checkList(TypeId.BoolList);

        var value = <bool>[];

        var size = _readSize();
        if (size == 0)
        {
            return value;
        }

        var bits = _buffer.getUint8List(size);
        for (var bit in bits)
        {
            assert(bit == TypeId.True || bit == TypeId.False);

            value.add(bit == TypeId.True);
        }

        return value;
    }

    List<String> readStringList()
    {
        _checkList(TypeId.StringList);
        var size = _readSize();

        var strings = <String>[];

        while (size-- > 0)
        {
            strings.add(readString());
        }
        
        return strings;
    }

    bool? readNullableBool()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readBool();
    }

    int? readNullableInt8()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt8();
    }

    int? readNullableUInt8()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt8();
    }

    int? readNullableInt16()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt16();
    }

    int? readNullableUInt16()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt16();
    }

    int? readNullableInt32()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt32();
    }

    int? readNullableUInt32()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt32();
    }

    int? readNullableInt64()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt64();
    }

    int? readNullableUInt64()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt64();
    }

    double? readNullableFloat32()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readFloat32();
    }

    double? readNullableFloat64()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readFloat64();
    }

    String? readNullableString()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readString();
    }

    Int8List? readNullableInt8List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt8List();
    }

    Uint8List? readNullableUInt8List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt8List();
    }

    Int16List? readNullableInt16List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt16List();
    }

    Uint16List? readNullableUInt16List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt16List();
    }

    Int32List? readNullableInt32List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt32List();
    }

    Uint32List? readNullableUInt32List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt32List();
    }

    Int64List? readNullableInt64List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readInt64List();
    }

    Uint64List? readNullableUInt64List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readUInt64List();
    }

    Float32List? readNullableFloat32List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readFloat32List();
    }

    Float64List? readNullableFloat64List()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readFloat64List();
    }

    List<bool>? readNullableBoolList()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readBoolList();
    }

    List<String>? readNullableStringList()
    {
        _check(1);
        if (isNull())
        {
            return null;
        }

        return readStringList();
    }

    void _check(int count)
    {
        if (_buffer.canRead(count))
        {
            return;
        }

        throw OutOfSpaceError();
    }

    T readObject<T>(Function decoder)
    {
        final type = getType();
        if (type != TypeId.Object && type != TypeId.ObjectRef)
        {
            throw InvalidTypeError(TypeId.Object, type, position: _buffer.position - 1);
        }

        final objectId = _readSize();
        
        if (objectId == 0)
        {
            throw InvalidDataError(position: _buffer.position - 1);
        }

        if (type == TypeId.ObjectRef)
        {
            final obj = _objectMap[objectId];
            if (obj == null)
            {
                throw InvalidDataError(position: _buffer.position - 1);
            }

            return obj as T;
        }

        final T value = decoder(this);
        _objectMap[objectId] = value!;

        return value;
    }

    T? readNullableObject<T>(Function decoder)
    {
        if (isNull())
        {
            return null;
        }

        return readObject<T>(decoder);
    }
    
    List<TObject> readObjectList<TObject>(Function decoder)
    {
        final list = <TObject>[];

        var size = beginList();
        while (size-- > 0)
        {
            final item = readObject(decoder);
            list.add(item);
        }

        return list;
    }

    List<TObject?> readNullableObjectList<TObject>(Function decoder)
    {
        final list = <TObject?>[];

        var size = beginList();
        while (size-- > 0)
        {
            final item = readNullableObject(decoder);
            list.add(item);
        }

        return list;
    }

    PluginError? readError()
    {
        _readType(TypeId.Error);
        final hasError = readBool();
        if (!hasError)
        {
            return null;
        }

        final code = readString();
        final message = readString();
        final details = readEncodableValue();

        return PluginError(code, message, details);
    }

    Object? readEncodableValue()
    {
        final type = getType();
        if (type == TypeId.Null)
        {
            return null;
        }
        if (type != TypeId.EncodableValue)
        {
            throw InvalidTypeError(TypeId.EncodableValue, type, position: _buffer.position - 1);
        }

        final size = _readSize();
        if (size == 0)
        {
            return null;
        }

        final evdata = _buffer.readBlock(size);

        final result = StandardMessageCodec().decodeMessage(evdata);
        return result;
    }

    TypeId getType()
    {
        _check(1);
        var value = _buffer.getUint8() as TypeId;
        return value;
    }

    int beginMap()
    {
        _check(1);
        _readType(TypeId.Map);
        return _readSize();
    }

    void checkMapTypes(TypeId keyType, TypeId elementType)
    {
        _readType(keyType);
        _readType(elementType);
    }

    TypeId _readType(TypeId type)
    {
        final value = _buffer.getUint8() as TypeId;
        if (value != type)
        {
            throw InvalidTypeError(type, value, position: _buffer.position - 1);
        }        

        return value;
    }

    int _readSize() 
    {
        _check(1);
        final value = _buffer.getUint8();
        if (value < 254) 
        {
            return value;
        }
        if (value == 254) 
        {
            _check(2);
            return _buffer.getUint16();
        }
        _check(4);
        return _buffer.getUint32();
    }
}
