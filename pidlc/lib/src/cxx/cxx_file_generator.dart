import 'package:pidlc/src/extensions.dart';

import '../file_generator.dart';

abstract class CxxFileGenerator extends FileGenerator
{
    CxxFileGenerator({
        required super.code,
        required super.options,
        required super.diagnostics
    });    
}