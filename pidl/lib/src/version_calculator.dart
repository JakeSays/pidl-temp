import 'dart:typed_data';

import 'types.dart';
import 'type_visitor.dart';

class VersionCalculator extends TypeVisitor
{
    late final SemanticVersion version;

    final _MD5Digest _input = _MD5Digest();

    VersionCalculator({required CompilationUnit cu})
    {
        visit(cu);
        final data = _input.complete();

        version = SemanticVersion(data[0], data[1], data[2], data[3]);
    }

    @override
    void visitAttribute(Attribute node)
    {
        _input.defn(node);
        _input.ident(node.category);
        _input.ident(node.ident);

        super.visitAttribute(node);
    }

    @override
    void visitAttributeArg(AttributeArg node)
    {
        _input.defn(node);
        _input.ident(node.name);

        super.visitAttributeArg(node);
    }

    @override
    void visitBaseInterface(TypeReference node) => _input.typeRef(node);

    // @override
    // void visitCompilationUnit(CompilationUnit node)
    // {
    // }

    @override
    void visitConstant(Constant node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitConstant(node);
    }

    @override
    void visitEnum(Enum node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitEnum(node);
    }

    @override
    void visitEnumerant(Enumerant node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitEnumerant(node);
    }

    @override
    void visitField(Field node)
    {
        _input.add(node.parentOrder);
        _input.defn(node);
        _input.ident(node.ident);
        super.visitField(node);
    }

    @override
    void visitFieldType(TypeReference node) => _input.typeRef(node);

    @override
    void visitIdentifier(Identifier node) => _input.ident(node);

    @override
    void visitImport(Import node)
    {
        _input.defn(node);
        final ver = node.importedUnit.version;
        _input.add(ver.a);
        _input.add(ver.b);
        _input.add(ver.c);
        _input.add(ver.d);
    }

    @override
    void visitInterface(Interface node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitInterface(node);
    }

    @override
    void visitLiteral(Literal node)
    {
        _input.defn(node);

        switch(node.kind)
        {
        case LiteralKind.nil:
            _input.string("null");
            break;
        case LiteralKind.boolean:
            _input.$int((node.value as bool) ? 1 : 0);
            break;
        case LiteralKind.number:
            final number = node.asNumber;
            _input.number(number);
            break;
        case LiteralKind.string:
            _input.string(node.value as String);
            break;
        case LiteralKind.constref:
            visit(node.asConstRef.target);
            break;
        case LiteralKind.enumerantref:
            visit(node.asEnum);
            break;
        case LiteralKind.none:
        case LiteralKind.error:
            break;
        }
    }

    @override
    void visitMethod(Method node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitMethod(node);
    }

    @override
    void visitMethodReturnType(TypeReference node) => _input.typeRef(node);

    @override
    void visitNamespace(Namespace node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitNamespace(node);
    }

    @override
    void visitParameter(Parameter node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitParameter(node);
    }

    // @override
    // void visitExpression(Expression node) 
    // {
    //     _input.add(0xF000F000);
    //     super.visitExpression(node);
    // }

    @override
    void visitParenExpression(ParenExpression node) 
    {
        _input.add(0xF000F001);
        super.visitParenExpression(node);
        _input.add(0xF000F002);        
    }

    @override
    void visitOperator(OperatorKind kind) 
    {
        _input.add(kind.index);
    }

    @override
    void visitStruct(Struct node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitStruct(node);
    }

    @override
    void visitStructBase(TypeReference node) => _input.typeRef(node);

    @override
    void visitTypeAlias(Alias node)
    {
        _input.defn(node);
        _input.ident(node.ident);
        super.visitTypeAlias(node);
    }

    @override
    void visitTypeParameter(TypeReference node) => _input.typeRef(node);

    @override
    void visitTypeReference(TypeReference node) => _input.typeRef(node);

    @override
    void visitEmptyExpression(EmptyExpression node) => _input.string("empty");
}

class _MD5Digest
{
    final _digest = Uint32List(4);

    static const int _bufferSize = 16;
    final Uint32List _buffer = Uint32List(_bufferSize);
    int _bufferIndex = 0;
    static final List<int> _null = "null".codeUnits;
    final ByteData _eightBytes = ByteData(8);

    void ident(Identifier? ident) => string(ident?.fullName);

    Uint32List complete()
    {
        if (_bufferIndex == 0)
        {
            return _digest;
        }

        for(; _bufferIndex < _bufferSize; _bufferIndex++)
        {
            _buffer[_bufferIndex] = 0;
        }

        updateHash();

        return _digest;
    }

    void string(String? string)
    {
        final codes = (string?.codeUnits ?? _null).iterator;
        while (codes.moveNext())
        {
            var value = codes.current << 16;
            if (codes.moveNext())
            {
                value |= codes.current & 0xFFFF;
            }
            add(value);
        }
    }

    void defn(Definition node) => add(node.declKind.index);

    void $int(int value) => add(value);

    void $bool(bool value) => add(value ? 1 : 0);
    
    void bigint(BigInt? value)
    {
        if (value == null)
        {
            addAll(_null);
            return;
        }

        string(value.toString());
    }

    void real(double value)
    {
        _eightBytes.setFloat64(0, value, Endian.host);
        var bits = _eightBytes.getUint32(0);
        add(bits);
        bits = _eightBytes.getUint32(4);
        add(bits);
    }

    void number(Number value)
    {
        add(value.kind.index);
        add(value.scale.index);
        add(value.radix.index);
        
        if (value.kind.isint)
        {
            bigint(value.value as BigInt);
        }
        else if (value.kind.isreal)
        {
            real(value.value as double);
        }
    }

    void typeRef(TypeReference node)
    {
        defn(node);
        ident(node.name);
        $bool(node.nullable);
    }

    void add(int value)
    {
        if (_bufferIndex >= _bufferSize)
        {
            updateHash();
            _bufferIndex = 0;
        }

        _buffer[_bufferIndex++] = value;
    }

    void addAll(List<int> values)
    {
        for (final value in values)
        {
            add(value);
        }
    }

    _MD5Digest()
    {
        _digest[0] = 0x67452301;
        _digest[1] = 0xefcdab89;
        _digest[2] = 0x98badcfe;
        _digest[3] = 0x10325476;
    }

    void updateHash() 
    {
        var a = _digest[0];
        var b = _digest[1];
        var c = _digest[2];
        var d = _digest[3];

        int e;
        int f;

        for (var i = 0; i < 64; i++) 
        {
            if (i < 16) 
            {
                e = (b & c) | ((~b & _mask32) & d);
                f = i;
            }
            else if (i < 32) 
            {
                e = (d & b) | ((~d & _mask32) & c);
                f = ((5 * i) + 1) % 16;
            }
            else if (i < 48) 
            {
                e = b ^ c ^ d;
                f = ((3 * i) + 5) % 16;
            }
            else 
            {
                e = c ^ (b | (~d & _mask32));
                f = (7 * i) % 16;
            }

            var temp = d;
            d = c;
            c = b;
            b = _add32(
                b,
                _rotl32(_add32(_add32(a, e), _add32(_noise[i], _buffer[f])),
                    _shiftAmounts[i]));
            a = temp;
        }

        _digest[0] = _add32(a, _digest[0]);
        _digest[1] = _add32(b, _digest[1]);
        _digest[2] = _add32(c, _digest[2]);
        _digest[3] = _add32(d, _digest[3]);
    }

    /// A bitmask that limits an integer to 32 bits.
    static const _mask32 = 0xFFFFFFFF;

    /// Adds [x] and [y] with 32-bit overflow semantics.
    static int _add32(int x, int y) => (x + y) & _mask32;

    /// Bitwise rotates [val] to the left by [shift], obeying 32-bit overflow
    /// semantics.
    static int _rotl32(int val, int shift) 
    {
        final modShift = shift & 31;
        return ((val << modShift) & _mask32) | ((val & _mask32) >> (32 - modShift));
    }

    /// Data from a non-linear mathematical function that functions as
    /// reproducible noise.
    static const _noise = 
    [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, //
        0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
        0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
        0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
        0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
        0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    ];

    /// Per-round shift amounts.
    static const _shiftAmounts = 
    [
        07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 05, 09, 14, //
        20, 05, 09, 14, 20, 05, 09, 14, 20, 05, 09, 14, 20, 04, 11, 16, 23, 04, 11,
        16, 23, 04, 11, 16, 23, 04, 11, 16, 23, 06, 10, 15, 21, 06, 10, 15, 21, 06,
        10, 15, 21, 06, 10, 15, 21
    ];

}