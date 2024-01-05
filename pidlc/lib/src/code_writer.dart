import 'package:pidl/pidl.dart';
import 'package:path/path.dart' as Path;
import 'dart:io';
import 'dart:math' as Math;

class WriterConfig
{
    String indent = "    ";
    String lineEnd = "\n";
    bool openBlocksOnNewLine = true;
    String outputRoot;

    WriterConfig({required this.outputRoot});
}

class Type
{
    DeclKind? declKind;
    bool nullable;
    TypeReference? reference;
    TypeDefinition? definition;
    Enumerant? enumerant;
    
    Type.kind(this.declKind, {this.nullable = false});
    Type.ref(TypeReference ref)
        : reference = ref,
          nullable = ref.nullable;
    Type.defn(this.definition, {this.nullable = false});
    Type.enumerant(this.enumerant)
        : nullable = false;
}

abstract class CodeWriter
{
    final WriterConfig config;

    int _indentCount = 0;
    bool _newLinePending = false;
    
    String currentIndent = "";
    final StringBuffer _output = StringBuffer();
    final StringBuffer temp = StringBuffer();

    String get output => _output.toString();

    CodeWriter({required this.config});

    String formatTypeName(Type type);
    
    String? get declBlockTerminator;
    String get readOnlyConstruct;
    String get variableConstruct;
    String get forSeparator;
    String? get refVarConstruct;
    String get nullValue;

    void reset()
    {
        _indentCount = 0;
        _output.clear();
        temp.clear();
    }

    void deleteOutput(String path)
    {
        final fullPath = Path.isAbsolute(path)
            ? path
            : Path.join(config.outputRoot, path);

        final file = File(fullPath);
        if (file.existsSync())
        {
            file.deleteSync();
        }
    }

    void save(String path)
    {
        final fullPath = Path.isAbsolute(path)
            ? path
            : Path.join(config.outputRoot, path);

        final dir = Directory(Path.dirname(fullPath));
        dir.createSync(recursive: true);

        final file = File(fullPath);
        file.writeAsStringSync(_output.toString(), flush: true);
    }

    CodeWriter nest([int count = 1])
    {
        _indentCount += count;
        currentIndent = config.indent * _indentCount;

        return this;
    }

    CodeWriter unnest([int count = 1])
    {
        _indentCount -= count;
        if (_indentCount < 0)
        {
            _indentCount = 0;
        }

        currentIndent = config.indent * _indentCount;

        return this;
    }

    void _indent()
    {
        if (_newLinePending)
        {
            _newLinePending = false;
            _output.write(config.lineEnd);
        }

        if (currentIndent.isNotEmpty)
        {
            _output.write(currentIndent);
        }
    }

    void _pendNl() => _newLinePending = true;

    CodeWriter append(String value)
    {
        _output.write(value);
        return this;
    }

    CodeWriter appendln(String value)
    {
        _output.write(value);
        
        if (_newLinePending)
        {
            _output.write(config.lineEnd);
        }

        _pendNl();        
        return this;
    }

    CodeWriter write(String value)
    {
        _indent();
        _output.write(value);
        return this;
    }

    CodeWriter writeln([String? value])
    {
        if (value != null)
        {
            _indent();        
            _output.write(value);
        }
        else if (_newLinePending)
        {
            _output.write(config.lineEnd);
        }

        _pendNl();        
        return this;
    }

    @override
    String toString() 
    {
        if (_output.isEmpty)
        {
            return "";
        }

        final content = _output.toString();
        if (content.length < 200)
        {
            return content;
        }

        return content.substring(content.length - 200);
    }

    CodeWriter writefmt(String value)
    {
        const int openBrace = 123;
        const int closeBrace = 125;
        const int tab = 9;
        const int nl = 10;
        const int cr = 13;
        const int nestin = 12;
        const int nestout = 8;
        const int backslash = 92;

        var nextIsLiteral = false;

        _indent();

        for(final chr in value.runes)
        {
            if (nextIsLiteral)
            {
                nextIsLiteral = false;
                _output.writeCharCode(chr);
                continue;
            }

            switch (chr)
            {
                case backslash:
                    nextIsLiteral = true;
                    continue;
                case openBrace:
                    this.nl();
                    writeln("{");
                    nest();
                    writeln();
                    continue;
                case closeBrace:
                    close();
                    continue;
                case tab:
                    write(config.indent);
                    continue;
                case nl:
                    writeln();
                    continue;
                case cr:
                    this.nl();
                    continue;
                case nestin:
                    nest();
                    continue;
                case nestout:
                    unnest();
                    continue;
                default:
                    _output.writeCharCode(chr);
                    continue;
            }
        }

        return this;
    }

    CodeWriter nl()
    {
        _output.write(config.lineEnd);
        return this;
    }

    CodeWriter open([bool needNewline = false])
    {        
        if (config.openBlocksOnNewLine)
        {
            if (needNewline)
            {
                _pendNl();
            }

//            _indent();
            writeln("{");
            nest();
        }
        else
        {
            _output.write(" {");
            nest();
            _pendNl();
            _indent();
        }

        return this;
    }

    CodeWriter close({bool decl = false})
    {
        unnest();
        _pendNl();
        writeln("}");
        if (decl && declBlockTerminator != null)
        {
            _output.write(declBlockTerminator);
        }
        return this;
    }

    CodeWriter $if(String condition, {String? ifblk, String? elblk})
    {
        writeln("if ($condition)");
        open();

        if (ifblk == null)
        {
            return this;
        }

        write(ifblk);
        if (elblk == null)
        {
            close();
            return this;
        }

        $else(elblk);

        return this;
    }

    CodeWriter $else([String? shortBlock])
    {
        close();
        if (config.openBlocksOnNewLine)
        {
            writeln("else");
        }
        else
        {
            _output.write(" else");
        }
        open();
        
        if (shortBlock != null)
        {
            writeln(shortBlock);
            close();
        }

        return this;
    }

    CodeWriter foreach(String varName, String container, {bool readonly = true, Type? type})
    {
        write("for (");
        if (readonly)
        {
            write(readOnlyConstruct);
        }
        if (type != null)
        {
            write(formatTypeName(type));
        }
        else
        {
            write(variableConstruct);
        }
        if (refVarConstruct != null)
        {
            write(refVarConstruct!);
        }       
        
        writeln(" $varName $forSeparator $container");
        open();

        return this;
    }

    CodeWriter declvar(String varName, {bool readonly = true, Type? type, String? init})
    {
       if (readonly)
        {
            write(readOnlyConstruct);
        }
        if (type != null)
        {
            write(formatTypeName(type));
        }
        else
        {
            write(variableConstruct);
        }
        if (refVarConstruct != null)
        {
            write(refVarConstruct!);
        }       
        
        write(" $varName $forSeparator");
        if (init != null)
        {
            write(" $init");
        }
        writeln(";");

        return this;
    }
}