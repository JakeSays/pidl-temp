
class _LineInfo
{
    final int start;
    final int end;
    final int length;
    final int number;

    bool ismatch(int offset) => offset >= start && offset <= end;

    _LineInfo({
        required this.start,
        required this.length,
        required this.number
    }) : end = start + length;
}

class SourceFile
{
    String path;
    String content;

    SourceFile({
        required this.path,
        required this.content
    });

    final List<_LineInfo> _lines = [];

    static final SourceFile unknown =
        SourceFile(path: "\$unknown", content: "");

    static final SourceFile builtins =
        SourceFile(path: "\$builtins", content: "");

    bool get isvalid => path != "\$unknown" && path != "\$builtins";

    void buildLineIndex()
    {
        if (!isvalid || _lines.isNotEmpty)
        {
            return;
        }

        int offset = 0;
        int currentLineStart = 0;
        int currentLine = 0;

        for (final chr in content.codeUnits)
        {
            final currentOffset = offset++;
            if (chr == 0x0A)
            {
                final length = currentOffset - currentLineStart;
                _lines.add(_LineInfo(start: currentLineStart, length: length, number: currentLine++));
                currentLineStart = offset;
                continue;
            }
        }

        if (_lines.isEmpty && content.isNotEmpty)
        {
            _lines.add(_LineInfo(start: 0, length: content.length, number: 0));
        }
    }

    SourcePosition findSourcePosition(int offset)
    {
        if (!isvalid)
        {
            return SourcePosition.invalid;
        }

        buildLineIndex();

        for(final info in _lines)
        {
            if (!info.ismatch(offset))
            {
                continue;
            }
            final column = offset - info.start;
            return SourcePosition(line: info.number + 1, column: column + 1, offset: offset, lineLength: info.length);
        }

        return SourcePosition.invalid;
    }

    String lineAtPosition(SourcePosition pos)
    {
        if (!isvalid)
        {
            return "";
        }

        buildLineIndex();

        final lineNumber = pos.line - 1;
        if (lineNumber < 0)
        {
            return "";
        }

        final line = _lines[lineNumber];
        return content.substring(line.start, line.end);
    }

    String? getLineAtOffset(int offset)
    {
        if (!isvalid)
        {
            return null;
        }

        final pos = findSourcePosition(offset);
        if (!pos.isvalid)
        {
            return null;
        }

        final line = content.substring(pos.offset, pos.offset + pos.lineLength);
        return line;
    }

    String sourceRange(int startOffset, int endOffset) => content.substring(startOffset, endOffset);
}

class SourcePosition
{
    final int line;
    final int column;
    final int offset;
    final int lineLength;

    bool get isvalid => line > -1 && column > -1 && offset > -1 && lineLength > -1;

    SourcePosition({
        required this.line,
        required this.column,
        required this.offset,
        required this.lineLength
    });

    static final SourcePosition invalid = SourcePosition(line: -1, column: -1, offset: -1, lineLength: -1);

    @override
    String toString() 
    {
        if (!isvalid)
        {
            return "unknown";
        }
        
        return "$line:$column";
    }
}

abstract class LocationProvider
{
    SourceLocation? location;

    LocationProvider({this.location});
}

class SourceLocation
{
    final SourceFile source;
    int length;
    int startOffset;
    int get endOffset => startOffset + length;

    bool get isvalid => length > -1 && startOffset > -1;
    
    SourcePosition get start => _start ??= source.findSourcePosition(startOffset);
    SourcePosition get end => _end ??= source.findSourcePosition(endOffset);

    static final SourceLocation unknown = SourceLocation.invalid(SourceFile.unknown);

    SourceLocation({
        required this.source,
        required this.startOffset,
        required this.length
    });

    factory SourceLocation.invalid(SourceFile source)
    {
        final location = SourceLocation(source: source, startOffset: -1, length: -1);
        location._start = SourcePosition.invalid;
        location._end = SourcePosition.invalid;

        return location;
    }

    SourcePosition? _start;
    SourcePosition? _end;

    @override
    String toString() => "[$start] - [$end]";

    String get description
    {
        final pos = start;
        if (!pos.isvalid)
        {
            return "unknown location";
        }

        return "${source.path}:$start";
    }

    String get startLine => source.lineAtPosition(start);
    String get endLine => source.lineAtPosition(end);

    String get content 
    {
        if (start.isvalid && end.isvalid)
        {
            return source.sourceRange(start.offset, end.offset + end.lineLength);
        }

        if (start.isvalid)
        {
            return source.getLineAtOffset(start.offset) ?? "";
        }

        if (end.isvalid)
        {
            return source.getLineAtOffset(end.offset) ?? "";
        }

        return "";
    }
}

SourceLocation joinLocations(Iterable<SourceLocation> locations)
{
    int start = 999999999999999999;
    int end = 0;

    for (final location in locations)
    {
        if (location.startOffset < start)
        {
            start = location.startOffset;
        }

        if (location.endOffset > end)
        {
            end = location.endOffset;
        }
    }

    return SourceLocation(source: locations.first.source, startOffset: start, length: end - start);
}