import 'package:pidl/pidl.dart';
import '../extensions.dart';

export '../extensions.dart';

class DartOutputPaths implements Outputs
{
    OutputInfo types = OutputInfo();
    OutputInfo codecs = OutputInfo();
    OutputInfo interfaces = OutputInfo();
    
    @override
    Iterable<OutputInfo> get items sync*
    {
        yield types;
        yield codecs;
        yield interfaces;
    }
}

class DartGeneratorData
{
    bool visited = false;
    String name = "";
    String enumerantName = "";
    String referenceName = "";
    String literalValue = "";
    String codecSuffix = "";
    String methodSignature = "";

    DartOutputPaths? output;
}

extension DartCompilationUnitExtension on CompilationUnit
{
    DartOutputPaths get dartOutput => (_dartData.output ??= DartOutputPaths());
}

extension DartDefinitionExtension on Definition
{
    DartGeneratorData get _dartData => (typegen.dartData ??= DartGeneratorData()) as DartGeneratorData;

    String get dartName => _dartData.name;
    set dartName(String value) => _dartData.name = value;

    String get dartReferenceName => _dartData.referenceName;
    set dartReferenceName(String value) => _dartData.referenceName = value;

    bool get dartVisited => _dartData.visited;
    set dartVisited(bool value) => _dartData.visited = value;

    bool get stateChecked => typegen.stateChecked;
    set stateChecked(bool value) => typegen.stateChecked = value;
}

extension DartEnumerantExtension on Enumerant
{
    String get dartQualifiedName => _dartData.enumerantName;
    set dartQualifiedName(String value) => _dartData.enumerantName = value;
}

extension DartLiteralExtension on Literal
{
    String get dartLiteralValue => _dartData.literalValue;
    set dartLiteralValue(String value) => _dartData.literalValue = value;
}

extension DartStructExtension on Struct
{
    String get dartCodecSuffix => _dartData.codecSuffix;
    set dartCodecSuffix(String value) => _dartData.codecSuffix = value;
}

extension DartMethodExtension on Method
{
    String get dartSignature => _dartData.methodSignature;
    set dartSignature(String value) => _dartData.methodSignature = value;
}

extension DartTypeReferenceExtension on TypeReference
{
    String get dartCodecSuffix => _dartData.codecSuffix;
    set dartCodecSuffix(String value) => _dartData.codecSuffix = value;
}