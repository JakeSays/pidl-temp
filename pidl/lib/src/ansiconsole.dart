///
/// Copyright 2013 Google Inc. All Rights Reserved.
///
/// ANSI/XTERM SGR (Select Graphics Rendering) support for 256 colors.
/// Note: if you're using the dart editor, these won't look right in the
///     terminal; disable via [color_disabled] or use Eclipse with the Dart and
///     AnsiConsol plugins!

import 'dart:io';

/// ANSI Control Sequence Introducer, signals the terminal for new settings.
const ansiEscape = '\x1B[';

/// Reset all colors and options for current SGRs to terminal defaults.
const ansiDefault = '${ansiEscape}0m';

/// Ansi codes that default the terminal's foreground color without
/// altering the background, when printed.
///
/// Does not modify [AnsiConsole]!
const ansiResetForeground = '${ansiEscape}39m';

///Ansi codes that default the terminal's background color without
///altering the foreground, when printed.
///
/// Does not modify [AnsiConsole]!
const ansiResetBackground = '${ansiEscape}49m';

bool _colorDisabled = !stdout.supportsAnsiEscapes;

void disableColorConsole() => _colorDisabled = true;
void enableColorConsole() => _colorDisabled = false;

bool get colorEnabled => _colorDisabled;

/// Pen attributes for foreground and background colors.
///
/// Use the pen in string interpolation to output ansi codes.
/// Use [up] in string interpolation to globally reset colors.
class AnsiConsole 
{
    AnsiConsole();

    AnsiConsole.makeEnabled()
    {
        enableColorConsole();
    }

    /// Treat a pen instance as a function such that `pen('msg')` is the same as
    /// `pen.write('msg')`.
    AnsiConsole call(Object msg) 
        => write(msg);

    /// Allow pen colors to be used in a string.
    ///
    /// Note: Once the pen is down, its attributes remain in effect till they are
    ///     changed by another pen or [up].
    @override
    String toString() 
    {
        if (_colorDisabled) 
        {
            return '';
        }
        
        if (!_dirty) 
        {
            return _pen;
        }

        final sb = StringBuffer();
        if (_fcolor != -1) 
        {
            sb.write('${ansiEscape}38;5;${_fcolor}m');
        }

        if (_bcolor != -1) 
        {
            sb.write('${ansiEscape}48;5;${_bcolor}m');
        }

        _dirty = false;
        _pen = sb.toString();
        return _pen;
    }

    /// Returns control codes to change the terminal colors.
    String get down => '${this}';

    /// Resets all pen attributes in the terminal.
    String get up => _colorDisabled ? '' : ansiDefault;

    /// Write the [msg.toString()] with the pen's current settings and then
    /// reset all attributes.
    AnsiConsole write(Object msg) 
    {
        stdout.write('${this}$msg$up');
        return this;
    }

    AnsiConsole black({bool bg = false, bool bold = false}) 
    {
        _std(0, bold, bg);
        return this;
    }
    AnsiConsole red({bool bg = false, bool bold = false}) 
    {
        _std(1, bold, bg);
        return this;
    }
    AnsiConsole green({bool bg = false, bool bold = false}) 
    {
        _std(2, bold, bg);
        return this;
    }
    AnsiConsole yellow({bool bg = false, bool bold = false}) 
    {
        _std(3, bold, bg);
        return this;
    }
    AnsiConsole blue({bool bg = false, bool bold = false}) 
    {
        _std(4, bold, bg);
        return this;
    }
    AnsiConsole magenta({bool bg = false, bool bold = false}) 
    {
        _std(5, bold, bg);
        return this;
    }
    AnsiConsole cyan({bool bg = false, bool bold = false}) 
    {
        _std(6, bold, bg);
        return this;
    }
    AnsiConsole white({bool bg = false, bool bold = false}) 
    {
        _std(7, bold, bg);
        return this;
    }

    /// Sets the pen color to the rgb value between 0.0..1.0.
    AnsiConsole rgb({num r = 1.0, num g = 1.0, num b = 1.0, bool bg = false}) 
    {
        xterm(
            (r.clamp(0.0, 1.0) * 5).toInt() * 36 +
                (g.clamp(0.0, 1.0) * 5).toInt() * 6 +
                (b.clamp(0.0, 1.0) * 5).toInt() +
                16,
            bg: bg);
        return this;            
    }

    /// Sets the pen color to a grey scale value between 0.0 and 1.0.
    AnsiConsole gray({num level = 1.0, bool bg = false}) 
    {
        xterm(232 + (level.clamp(0.0, 1.0) * 23).round(), bg: bg);
        return this;
    }

    void _std(int color, bool bold, bool bg) =>
        xterm(color + (bold ? 8 : 0), bg: bg);

    /// Directly index the xterm 256 color palette.
    AnsiConsole xterm(int color, {bool bg = false}) 
    {
        _dirty = true;
        final c = color < 0
            ? 0
            : color > 255
                ? 255
                : color;
        if (bg) 
        {
            _bcolor = c;
        }
        else 
        {
            _fcolor = c;
        }
        return this;
    }

    ///Resets the pen's attributes.
    AnsiConsole reset() 
    {
        _dirty = false;
        _pen = '';
        _bcolor = _fcolor = -1;
        return this;
    }

    int _fcolor = -1;
    int _bcolor = -1;
    String _pen = '';
    bool _dirty = false;
}

