import 'package:pidl/pidl.dart';
import 'generator_options.dart';
import 'generator_issue.dart';
import 'extensions.dart';

class NameOverrideAttribute
{
    final String language;
    String name;

    NameOverrideAttribute._(this.name, this.language);

    static List<NameOverrideAttribute> parseAll(NamedDefinition node, Diagnostics diagnostics)
    {
        final overrides = <NameOverrideAttribute>[];

        for (final attr in node.findAttributes((attr) => attr.ident.name == "name"))
        {
            if (attr.category == null)
            {
                diagnostics.addIssue(GeneratorIssue(
                    severity: IssueSeverity.error,
                    definition: attr,
                    message: "Name override attribute requires a language category"
                ));
                return [];
            }

            final result = _make(attr, diagnostics, attr.category!.name);
            if (result != null)
            {
                overrides.add(result);
            }            
        }

        return overrides;
    }

    static NameOverrideAttribute? parse(NamedDefinition node, Diagnostics diagnostics, String language)
    {
        final attr = node.findAttribute((a) => a.category?.name == language && a.ident.fullName == "name");
        if (attr == null)
        {
            return null;
        }

        return _make(attr, diagnostics, language);
    }

    static NameOverrideAttribute? _make(Attribute attr, Diagnostics diagnostics, String language)
    {
        final arg = attr.args.firstWhere((arg) => arg.name == null || arg.name!.fullName == "name", orElse: () => AttributeArg.none);
        if (arg.name != null && arg.name!.fullName != "name")
        {
            diagnostics.addIssue(GeneratorIssue(
                severity: IssueSeverity.warning,
                definition: attr,
                message: "$language:name attribute requires a 'name' string argument"
            ));
            return null;
        }
        if (arg.value == null ||
            arg.value!.kind != LiteralKind.string ||
            (arg.value!.value as String).isEmpty)
        {
            diagnostics.addIssue(GeneratorIssue(
                severity: IssueSeverity.warning,
                definition: attr,
                message: "$language:name attribute requires a string argument, attribute igored"
                ));
            return null;
        }

        return NameOverrideAttribute._(arg.value!.value as String, language);
    }
}

class ImplementationAttribute
{
    final ImplementationKind kind;

    ImplementationAttribute._(this.kind);

    static ImplementationAttribute? parse(Interface node, Diagnostics diagnostics)
    {
        final appImplAttr = node.findAttributeByName("implementation:application");
        final hostImplAttr = node.findAttributeByName("implementation:host");

        if (appImplAttr != null &&
            hostImplAttr != null)
        {
            diagnostics.addIssue(GeneratorIssue(
                severity: IssueSeverity.error,
                definition: node,
                message: "Only one implementation location attribute allowed"));
            return null;
        }

        ImplementationKind kind;
        if (appImplAttr == null && hostImplAttr == null)
        {
            kind = ImplementationKind.abstract;
        }
        else if (appImplAttr != null)
        {
            kind = ImplementationKind.application;
        }
        else
        {
            kind = ImplementationKind.host;
        }

        return ImplementationAttribute._(kind);
    }
}

class EnumKindAttribute
{
    final EnumKind kind;

    EnumKindAttribute._(this.kind);

    static EnumKindAttribute parse(Enum node)
    {
        return EnumKindAttribute._(node.findAttributeByName("flags") != null
            ? EnumKind.flags
            : EnumKind.normal);
    }
}

enum ChannelNameKind
{
    unknown,
    string,
    constant
}

class ChannelAttribute
{
    final String? channelString;
    final Constant? channelConst;
    final ChannelNameKind kind;

    ChannelAttribute._()
        : channelConst = null,
          channelString = null,
          kind = ChannelNameKind.unknown;
    
    ChannelAttribute._string(this.channelString)
        : kind = ChannelNameKind.string,
          channelConst = null;

    ChannelAttribute._const(this.channelConst)
        : kind = ChannelNameKind.constant,
          channelString = null;

    static ChannelAttribute parse(Interface node, Diagnostics diagnostics, GeneratorOptions options)
    {
        if (node.kind == ImplementationKind.abstract)
        {
            return ChannelAttribute._();
        }

        if (options.forceChannelOverride &&
            options.defaultChannelName != null)
        {
            return ChannelAttribute._();
        }

        final channelAttr = node.findAttributeByName("channel");
        if (channelAttr == null)
        {
            if (options.defaultChannelName != null)
            {
                return ChannelAttribute._string(options.defaultChannelName);
            }

            diagnostics.addIssue(GeneratorIssue(
                severity: IssueSeverity.error,
                definition: node,
                message: "Missing interface channel attribute"));
            return ChannelAttribute._();
        }

        if (channelAttr.args.isEmpty ||
            channelAttr.args[0].value == null)
        {
            diagnostics.addIssue(GeneratorIssue(
                severity: IssueSeverity.error,
                definition: node,
                message: "Missing interface channel name"));
            return ChannelAttribute._();
        }

        final channelArg = channelAttr.args[0];
        if (channelArg.value!.kind == LiteralKind.string)
        {
            return ChannelAttribute._string(channelArg.value!.value.toString());
        }

        if (channelArg.value!.kind != LiteralKind.constref ||
            channelArg.value!.asConstRef.valueKind != DeclKind.string)
        {
            diagnostics.addIssue(GeneratorIssue(
                severity: IssueSeverity.error,
                definition: channelArg,
                message: "Invalid value for channel name"));
            return ChannelAttribute._();
        }

        return ChannelAttribute._const(channelArg.value!.asConstRef.target);
    }
}