import 'package:pidl/pidl.dart';
import '../extensions.dart';
export '../extensions.dart';

class CxxOutputs extends Outputs
{
    OutputInfo typesHeader = OutputInfo();
    OutputInfo typesImpl = OutputInfo();
    OutputInfo codecsHeader = OutputInfo();
    OutputInfo codecsImpl = OutputInfo();
    OutputInfo interfacesHeader = OutputInfo();
    OutputInfo interfacesImpl = OutputInfo();

    @override
    Iterable<OutputInfo> get items sync*
    {
        yield typesHeader;
        yield typesImpl;
        yield codecsHeader;
        yield codecsImpl;
        yield interfacesHeader;
        yield interfacesImpl;
    }
}

class CxxGeneratorData
{
    bool visited = false;
    CxxOutputs? output;
    String name = "";
    String enumerantName = "";
    String referenceName = "";
    String literalValue = "";
    String codecSuffix = "";
    String clientMethodSignature = "";
    String serviceMethodSignature = "";
    String qualifiedName = "";
}

extension CxxDefinitionExtension on Definition
{
    CxxGeneratorData get _cxxData => (typegen.cxxData ??= CxxGeneratorData()) as CxxGeneratorData;

    String get cxxName => _cxxData.name;
    set cxxName(String value) => _cxxData.name = value;

    String get cxxReferenceName => _cxxData.referenceName;
    set cxxReferenceName(String value) => _cxxData.referenceName = value;

    bool get cxxVisited => _cxxData.visited;
    set cxxVisited(bool value) => _cxxData.visited = value;

    String get cxxLiteralValue => _cxxData.literalValue;
    set cxxLiteralValue(String value) => _cxxData.literalValue = value;

    String get cxxQualifiedName => _cxxData.qualifiedName;
    set cxxQualifiedName(String value) => _cxxData.qualifiedName = value;

    String get cxxClientMethodSignature => _cxxData.clientMethodSignature;
    set cxxClientMethodSignature(String value) => _cxxData.clientMethodSignature = value;

    String get cxxServiceMethodSignature => _cxxData.serviceMethodSignature;
    set cxxServiceMethodSignature(String value) => _cxxData.serviceMethodSignature = value;
}

extension CxxCompilationUnitExtension on CompilationUnit
{
    CxxOutputs get cxxOutput => (_cxxData.output ??= CxxOutputs());
}
