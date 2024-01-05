import 'dart:io';
import 'ansiconsole.dart';

final _pen = AnsiConsole.makeEnabled();

void writeln([Object? value])
{
    if (value == null)
    {
        stdout.writeln();
        return;
    }

    stdout.writeln(value);
}

void write(Object value) => stdout.write(value);

void red(Object value)
{
    _pen.red();
    _pen.write(value);
}

void redln(Object? value)
{
    if (value == null)
    {
        stdout.writeln();
        return;
    }

    _pen.red();
    _pen.write("$value\n");
}

void green(Object value)
{
    _pen.green();
    _pen.write(value);
}

void greenln(Object? value)
{
    if (value == null)
    {
        stdout.writeln();
        return;
    }

    _pen.green();
    _pen.write("$value\n");
}

void yellow(Object value)
{
    _pen.yellow();
    _pen.write(value);
}

void yellowln(Object? value)
{
    if (value == null)
    {
        stdout.writeln();
        return;
    }

    _pen.yellow();
    _pen.write("$value\n");
}

void blue(Object value)
{
    _pen.blue();
    _pen.write(value);
}

void blueln(Object? value)
{
    if (value == null)
    {
        stdout.writeln();
        return;
    }

    _pen.blue();
    _pen.write("$value\n");
}
