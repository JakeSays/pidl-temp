import 'typeid.dart';

class NullValueError extends Error
{
    String message;

    NullValueError({String? message})
        : message = message ?? "Null value not allowed in non-null context";
}

class NumericRangeError extends Error
{
    TypeId expected;
    String message;
    
    NumericRangeError(this.expected)
        : message = "Numeric value out of range for type ${expected.name}";
}

class InvalidTypeError extends Error
{
    InvalidTypeError(this.expected, this.actual, {this.position = -1})
    {
        message = 'Expected ${TypeId.typeIdName(expected)} found ${TypeId.typeIdName(actual)}';
        if (position >= 0)
        {
            message += ' at position $position';
        }
    }

    TypeId expected;
    TypeId actual;
    int position;

    late String message;

    String toString() => message;
}

class OutOfSpaceError extends Error
{
    OutOfSpaceError();

    String toString() => "No space left";
}

class InvalidDataError extends Error
{
    InvalidDataError({this.position = -1})
    {
        message = "Invalid data detected";
        if (position >= 0)
        {
            message += ' at position $position';
        }
    }

    int position;

    late String message;

    String toString() => message;
}

class PluginError extends Error
{
    String get code => _code;
    String get message => _message;
    Object? get details => _details;

    PluginError(
        this._code,
        this._message,
        this._details
    );

    String _code;
    String _message;
    Object? _details;
}