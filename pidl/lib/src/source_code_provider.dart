import 'source.dart';

abstract class SourceCodeProvider
{
    String normalizePath(String path);
    SourceFile? loadMainFile(String path);
    SourceFile? loadImport(String path);
}

class NullCodeProvider implements SourceCodeProvider
{
    @override
    SourceFile? loadImport(String path) => throw UnimplementedError();

    @override
    SourceFile? loadMainFile(String path) => throw UnimplementedError();

    @override
    String normalizePath(String path) => throw UnimplementedError();
}