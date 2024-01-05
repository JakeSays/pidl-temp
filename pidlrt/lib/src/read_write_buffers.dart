// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;
import 'dart:typed_data';// show Int8List, Uint8List, Int16List, Uint16List, Int32List, Uint32List, Uint64List, Int64List, Float32List, Float64List, ByteData, Endian;

class PluginWriteBuffer 
{
    PluginWriteBuffer()
        : _buffer = Uint8Buffer(),
        _eightBytes = ByteData(8) 
    {
        _eightBytesAsList = _eightBytes.buffer.asUint8List();
    }

    Uint8Buffer? _buffer;
    final ByteData _eightBytes;
    late Uint8List _eightBytesAsList;
    
    void putInt8(int byte) 
    {
        _buffer!.add(byte);
    }

    void putUInt8(int byte) 
    {
        _buffer!.add(byte);
    }

    void putInt16(int value, {Endian? endian}) 
    {
        _eightBytes.setInt16(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList, 0, 2);
    }

    void putUInt16(int value, {Endian? endian}) 
    {
        _eightBytes.setUint16(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList, 0, 2);
    }

    void putInt32(int value, {Endian? endian}) 
    {
        _eightBytes.setInt32(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList, 0, 4);
    }

    void putUInt32(int value, {Endian? endian}) 
    {
        _eightBytes.setUint32(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList, 0, 4);
    }

    void putInt64(int value, {Endian? endian}) 
    {
        _eightBytes.setInt64(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList, 0, 8);
    }

    void putUInt64(int value, {Endian? endian}) 
    {
        _eightBytes.setUint64(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList, 0, 8);
    }

    void putFloat32(double value, {Endian? endian}) 
    {
        _alignTo(4);
        _eightBytes.setFloat32(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList);
    }

    void putFloat64(double value, {Endian? endian}) 
    {
        _alignTo(8);
        _eightBytes.setFloat64(0, value, endian ?? Endian.host);
        _buffer!.addAll(_eightBytesAsList);
    }

    void putTypedData(TypedData data, int alignment)
    {
        if (alignment > 0)
        {
            _alignTo(alignment);
        }

        _buffer!.addAll(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }

    void putInt8List(Int8List list) 
    {
        _buffer!.addAll(list);
    }

    void putUInt8List(Uint8List list) 
    {
        _buffer!.addAll(list);
    }

    void putInt16List(Int16List list) 
    {
        _alignTo(2);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 2 * list.length));
    }

    void putUInt16List(Uint16List list) 
    {
        _alignTo(2);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 2 * list.length));
    }

    void putInt32List(Int32List list) 
    {
        _alignTo(4);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
    }

    void putUInt32List(Uint32List list) 
    {
        _alignTo(4);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
    }

    void putInt64List(Int64List list) 
    {
        _alignTo(8);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
    }

    void putUInt64List(Uint64List list) 
    {
        _alignTo(8);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
    }

    void putFloat32List(Float32List list) 
    {
        _alignTo(4);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
    }

    void putFloat64List(Float64List list) 
    {        
        _alignTo(8);
        _buffer!.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
    }

    void _alignTo(int alignment) 
    {
        final int mod = _buffer!.length % alignment;
        if (mod != 0) 
        {
        for (int i = 0; i < alignment - mod; i++)
            {
                _buffer!.add(0);
            }
        }
    }

    ByteData done() 
    {
        final ByteData result = _buffer!.buffer.asByteData(0, _buffer!.lengthInBytes);
        _buffer = null;
        return result;
    }
}

class PluginReadBuffer 
{
    final ByteData _data;

    PluginReadBuffer(this._data, [int offset = 0])
    {
        _position = offset;
    }

    int _position = 0;

    bool get hasRemaining => _position < _data.lengthInBytes;

    int get position => _position;

    bool canRead(int count) => (_data.lengthInBytes - _position) >= count;

    ByteData? readBlock(int blockSize)
    {
        if (!canRead(blockSize))
        {
            return null;
        }

        final block = ByteData.view(_data.buffer,
            _position,
            blockSize);

        advance(blockSize);

        return block;
    }

    int peekUint8() 
    {
        return _data.getUint8(_position);
    }

    void advance(int count)
    {
        _position += count;
    }

    int getInt8({Endian? endian}) 
    {
        final int value = _data.getInt8(_position);
        _position += 1;
        return value;
    }

    int getUint8() 
    {
        return _data.getUint8(_position++);
    }

    int getInt16({Endian? endian}) 
    {
        final int value = _data.getInt16(_position, endian ?? Endian.host);
        _position += 2;
        return value;
    }

    int getUint16({Endian? endian}) 
    {
        final int value = _data.getUint16(_position, endian ?? Endian.host);
        _position += 2;
        return value;
    }

    int getInt32({Endian? endian}) 
    {
        final int value = _data.getInt32(_position, endian ?? Endian.host);
        _position += 4;
        return value;
    }

    int getUint32({Endian? endian}) 
    {
        final int value = _data.getUint32(_position, endian ?? Endian.host);
        _position += 4;
        return value;
    }

    int getInt64({Endian? endian}) 
    {
        final int value = _data.getInt64(_position, endian ?? Endian.host);
        _position += 8;
        return value;
    }

    int getUint64({Endian? endian}) 
    {
        final int value = _data.getUint64(_position, endian ?? Endian.host);
        _position += 8;
        return value;
    }

    double getFloat32({Endian? endian}) 
    {
        _alignTo(4);
        final double value = _data.getFloat32(_position, endian ?? Endian.host);
        _position += 4;
        return value;
    }

    double getFloat64({Endian? endian}) 
    {
        _alignTo(8);
        final double value = _data.getFloat64(_position, endian ?? Endian.host);
        _position += 8;
        return value;
    }

    Int8List getInt8List(int length) 
    {
        final Int8List list = _data.buffer.asInt8List(_data.offsetInBytes + _position, length);
        _position += length;
        return list;
    }

    Uint8List getUint8List(int length) 
    {
        final Uint8List list = _data.buffer.asUint8List(_data.offsetInBytes + _position, length);
        _position += length;
        return list;
    }

    Int16List getInt16List(int length) 
    {
        _alignTo(2);
        final Int16List list = _data.buffer.asInt16List(_data.offsetInBytes + _position, length);
        _position += 2 * length;
        return list;
    }

    Uint16List getUint16List(int length) 
    {
        _alignTo(2);
        final Uint16List list = _data.buffer.asUint16List(_data.offsetInBytes + _position, length);
        _position += 2 * length;
        return list;
    }

    Int32List getInt32List(int length) 
    {
        _alignTo(4);
        final Int32List list = _data.buffer.asInt32List(_data.offsetInBytes + _position, length);
        _position += 4 * length;
        return list;
    }

    Uint32List getUint32List(int length) 
    {
        _alignTo(4);
        final Uint32List list = _data.buffer.asUint32List(_data.offsetInBytes + _position, length);
        _position += 4 * length;
        return list;
    }

    Int64List getInt64List(int length) 
    {
        _alignTo(8);
        final Int64List list = _data.buffer.asInt64List(_data.offsetInBytes + _position, length);
        _position += 8 * length;
        return list;
    }

    Uint64List getUint64List(int length) 
    {
        _alignTo(8);
        final Uint64List list = _data.buffer.asUint64List(_data.offsetInBytes + _position, length);
        _position += 8 * length;
        return list;
    }

    Float64List getFloat64List(int length) 
    {
        _alignTo(8);
        final Float64List list = _data.buffer.asFloat64List(_data.offsetInBytes + _position, length);
        _position += 8 * length;
        return list;
    }

    Float32List getFloat32List(int length) 
    {
        _alignTo(4);
        final Float32List list = _data.buffer.asFloat32List(_data.offsetInBytes + _position, length);
        _position += 8 * length;
        return list;
    }

    void _alignTo(int alignment) 
    {
        final int mod = _position % alignment;
        if (mod != 0)
        {
            _position += alignment - mod;
        }
    }
}
