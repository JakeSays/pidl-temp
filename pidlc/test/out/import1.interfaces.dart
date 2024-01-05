
// ******************************DO NOT EDIT********************************
// *** This file was generated by pidlc version 1.0.0
// *** on 2022-07-16 08:05:12.403603
// *** from '/p/flutter/f/EmbeddedFlutter/pluginapi/pidlc/samples/import1.idl'
// *** and contains interface proxies and services.
// ***
// *** Any edits to this file will be lost the next time it is generated.
// *** You have been warned!
// ******************************DO NOT EDIT********************************
// @dart = 2.17.3

import 'package:pidlrt/pidlrt.dart' as pidl;

import 'import2.types.dart' as frob;
import 'import2.codecs.dart' as codecs_frob;

const _fileVersion = pidl.FileVersion(0x7872D2F2, 0xBD77436E, 0x4C266FBA, 0x98EBA990);


class Interface1Service extends PluginService
{
    final Interface1 implementation;

    Interface1Service({required this.implementation, bool includeTypeTags = false})
        : super(ServiceConfig(includeTypeTags, ChannelName, "Interface1", _fileVersion))
    {
        registerMethod(_method1);
        registerMethod(_method2);
        registerMethod(_fack);
    }

    Future<ByteData?> _method1(BinaryReader? argData)
    {
        final p1Arg = argData!.readObject<StructWithDependency>(decodeStructWithDependency);
        final result = await implementation.method1(p1Arg);
        final output = BinaryWriter(includeTypeTags);
        output.writeObject<DependentStruct>(result, encodeDependentStruct);
        return output.done();
    }

    Future<ByteData?> _method2(BinaryReader? argData)
    {
        final p1Arg = argData!.readObject<frob.Import2Struct>(codecs_frob.decodeImport2Struct);
        await implementation.method2(p1Arg);
        return null;
    }

    Future<ByteData?> _fack(BinaryReader? argData)
    {
        final p1Arg = argData!.readObject<AnotherStruct>(decodeAnotherStruct);
        await implementation.fack(p1Arg);
        return null;
    }

    static const _method1 = pidl.MethodInfo("Method1", 0);
    static const _method2 = pidl.MethodInfo("Method2", 1);
    static const _fack = pidl.MethodInfo("Fack", 0);
}

class Interface2Proxy extends PluginProxy implements Interface2
{
    Interface2Proxy({bool includeTypeTags = false})
        : super(ProxyConfig(includeTypeTags, ChannelName, "Interface2", _fileVersion));

    Future<DependentStruct> method1({required StructWithDependency p1})
    {
        final output = BinaryWriter(includeTypeTags, method: _method1);
        output.writeObject<StructWithDependency>(p1, encodeStructWithDependency);
        final resultReader = BinaryReader(null);

        if (!await invokeMethodWithArgsAndReturn(output, resultReader))
        {
            throw PlatformException(code: 'channel-error', message: 'Unable to send to channel $channelString');
        }
        final result = resultReader.readObject<DependentStruct>(decodeDependentStruct);
        return result;
    }

    Future<void> method2({required frob.Import2Struct p1})
    {
        final output = BinaryWriter(includeTypeTags, method: _method2);
        output.writeObject<frob.Import2Struct>(p1, codecs_frob.encodeImport2Struct);
        if (!await invokeMethodWithParams(output))
        {
            throw PlatformException(code: 'channel-error', message: 'Unable to send to channel $channelString');
        }
    }

    Future<void> fack({required AnotherStruct p1})
    {
        final output = BinaryWriter(includeTypeTags, method: _fack);
        output.writeObject<AnotherStruct>(p1, encodeAnotherStruct);
        if (!await invokeMethodWithParams(output))
        {
            throw PlatformException(code: 'channel-error', message: 'Unable to send to channel $channelString');
        }
    }

    static const _method1 = pidl.MethodInfo("Method1", 0);
    static const _method2 = pidl.MethodInfo("Method2", 1);
    static const _fack = pidl.MethodInfo("Fack", 0);
}
