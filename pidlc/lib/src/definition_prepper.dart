import 'package:pidl/pidl.dart';
import 'generator_options.dart';
import 'extensions.dart';
import 'attributes.dart';

class DefinitionPrepper extends TypeVisitor
{
    final Diagnostics diagnostics;
    final GeneratorOptions options;

    DefinitionPrepper._({
        required this.diagnostics,
        required this.options});

    static void go(CompileResult result, Diagnostics diagnostics, GeneratorOptions options)
    {
        final me = DefinitionPrepper._(diagnostics: diagnostics, options: options);

        for(final cu in result.unitsInDependencyOrder)
        {
            me.visit(cu);
        }
    }

    @override
    void visitConstant(Constant node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
    }

    @override
    void visitEnum(Enum node) 
    {        
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
        node.typegen.enumKind = EnumKindAttribute.parse(node).kind;

        super.visitEnum(node);
    }

    @override
    void visitField(Field node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
    }

    @override
    void visitStruct(Struct node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
        super.visitStruct(node);
    }

    @override
    void visitInterface(Interface node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
        node.typegen.interfaceImplementation = ImplementationAttribute.parse(node, diagnostics)?.kind ?? ImplementationKind.unknown;
        node.channel = ChannelAttribute.parse(node, diagnostics, options);
        
        super.visitInterface(node);
    }

    @override
    void visitMethod(Method node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
        super.visitMethod(node);
    }

    @override
    void visitParameter(Parameter node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
        super.visitParameter(node);
    }

    @override
    void visitNamespace(Namespace node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
        super.visitNamespace(node);
    }

    @override
    void visitTypeAlias(Alias node) 
    {
        node.nameOverrides = NameOverrideAttribute.parseAll(node, diagnostics);
    }
}