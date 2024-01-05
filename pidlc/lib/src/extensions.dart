import 'package:pidl/pidl.dart';
import 'attributes.dart';

enum ImplementationKind
{
    unknown,
    host,
    application,
    abstract
}

enum EnumKind
{
    unknown,
    flags,
    normal
}

class OutputInfo
{
    String path = "";
    SemanticVersion version = SemanticVersion.unknown;

    bool hasChanged(SemanticVersion newVersion) => newVersion != version;
}

abstract class Outputs
{
    Iterable<OutputInfo> get items;
}

extension ListExtension<TElement> on List<TElement>
{
    TElement? firstOrDefault(bool Function(TElement element) predicate, [TElement? defaultValue])
    {
        for(final element in this)
        {
            if (predicate(element))
            {
                return element;
            }
        }

        return defaultValue;
    }
}

class TypeGeneratorData
{
    bool stateChecked = false;
    ImplementationKind interfaceImplementation = ImplementationKind.unknown;
    EnumKind enumKind = EnumKind.unknown;
    late ChannelAttribute channel;
    late List<NameOverrideAttribute> nameOverrides;

    Object? dartData;
    Object? cxxData;

    String? findNameOverride(String language)
    {
        final attr = nameOverrides.firstOrDefault((element) => element.language == language);
        return attr?.name;
    }
}

extension CompilationUnitExtension on CompilationUnit
{
    bool isDirty(OutputInfo output) => version != output.version;
}

extension DefinitionExtension on Definition
{
    TypeGeneratorData get typegen => (userData ??= TypeGeneratorData()) as TypeGeneratorData;

    List<NameOverrideAttribute> get nameOverrides => typegen.nameOverrides;
    set nameOverrides(List<NameOverrideAttribute> value) => typegen.nameOverrides = value;

    String? findNameOverride(String language) => typegen.findNameOverride(language);
}

extension InterfaceExtension on Interface
{
    ImplementationKind get kind => typegen.interfaceImplementation;
    set kind(ImplementationKind kind) => typegen.interfaceImplementation = kind;

    ChannelAttribute get channel => typegen.channel;
    set channel(ChannelAttribute value) => typegen.channel = value;
}

extension EnumExtension on Enum
{
    EnumKind get kind => typegen.enumKind;
    set kind(EnumKind kind) => typegen.enumKind = kind;
}
