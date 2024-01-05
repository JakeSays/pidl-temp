import 'package:pidl/pidl.dart';

abstract class Generator
{
    bool _firstDecl = true;

    void reset() => _firstDecl = true;
    
    bool get firstDecl
    {
        if (_firstDecl)
        {
            _firstDecl = false;
            return true;
        }

        return false;
    }

    void go(CompileResult compileResults, String outputDir);
}