import 'dart:io';
import 'source.dart';
import 'source_code_provider.dart';
import 'package:path/path.dart' as Path;
import 'diagnostics.dart';

class FileSystemProvider implements SourceCodeProvider
{
    final Diagnostics diagnostics;
    late String _basePath;

    FileSystemProvider({required this.diagnostics});

    @override
    SourceFile? loadMainFile(String path) 
    {
        path = Path.canonicalize(path);

        _basePath = Path.dirname(path);

        return _loadFile(path, false);
    }
    
    @override
    SourceFile? loadImport(String path) 
    {
        path = normalizePath(path);

        return _loadFile(path, true);
    }

    @override
    String normalizePath(String inpath)
    {
        if (Path.isAbsolute(inpath))
        {
            return Path.canonicalize(inpath);
        }

        return Path.canonicalize(Path.join(_basePath, inpath));
    }

    SourceFile? _loadFile(String sourcePath, bool isimport)
    {
        try 
        {
            final idlFile = File(sourcePath);
            if (!idlFile.existsSync())
            {
                diagnostics.addIssue(ParseIssue(
                    code: isimport ? IssueCode.importNotFound : IssueCode.fileNotFound, 
                    severity: IssueSeverity.error,
                    message: "Idl file '$sourcePath' does not exist"
                ));
                return null;
            }

            final source = 
                SourceFile(path: sourcePath,
                    content: idlFile.readAsStringSync());        

            return source;
        }
        on Exception catch (e)
        {
            diagnostics.addIssue(ExceptionIssue(exception: e));
            return null;
        }
    }
}
