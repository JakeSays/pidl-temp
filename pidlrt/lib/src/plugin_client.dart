import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'method_status.dart';

import 'binary_reader.dart';

class PluginClient
{
    String _channelName;
    String _serviceName;
    late String _serviceChannel;

    PluginClient(this._channelName, this._serviceName)
    {
        _serviceChannel = '$_channelName/$_serviceName';
    }

    Future<bool> invokeMethod(ByteData data) async
    {
        final returnData = await _sendPlatformMessage(data);
        if (returnData == null)
        {
            return false;
        }
        
        final status = returnData.getUint8(0);
        if (status == MethodStatus.Success)
        {
            return true;
        }

        if (status == MethodStatus.SuccessWithReply)
        {
            FlutterError.reportError(FlutterErrorDetails(
                exception: FlutterError("Method received an unexpected reply"),
                library: 'pluginapi',
                context: ErrorDescription('during a plugin method invocation'),
            ));
        }
        else if (status == MethodStatus.Error)
        {
            final buffer = BinaryReader.fromData(returnData, offset: 1);
            final error = buffer.readError();
            throw error!;            
        }
        else
        {
            FlutterError.reportError(FlutterErrorDetails(
                exception: FlutterError("Corrupt method reply data"),
                library: 'pluginapi',
                context: ErrorDescription('during a plugin method invocation'),
            ));
        }
        
        return false;
    }

    Future<bool> invokeMethodWithReturn(ByteData data, BinaryReader returnData) async
    {
        final replyData = await _sendPlatformMessage(data);
        if (replyData == null)
        {
            return false;
        }

        final status = replyData.getUint8(0);
        
        if (status == MethodStatus.Success)
        {
            FlutterError.reportError(FlutterErrorDetails(
                exception: FlutterError("Method expected a reply"),
                library: 'pluginapi',
                context: ErrorDescription('during a plugin method invocation'),
            ));
        }
        else if (status == MethodStatus.SuccessWithReply)
        {
            returnData.setData(replyData, 1);
            return true;
        }
        else if (status == MethodStatus.Error)
        {
            final buffer = BinaryReader.fromData(replyData, offset: 1);
            final error = buffer.readError();
            throw error!;            
        }
        else
        {
            FlutterError.reportError(FlutterErrorDetails(
                exception: FlutterError("Corrupt method reply data"),
                library: 'pluginapi',
                context: ErrorDescription('during a plugin method invocation'),
            ));
        }
        
        return false;
    }

    String get channelName => _channelName;

    @pragma('vm:notify-debugger-on-exception')
    Future<ByteData?> _sendPlatformMessage(ByteData? message) 
    {
        final Completer<ByteData?> completer = Completer<ByteData?>();
        // ui.PlatformDispatcher.instance is accessed directly instead of using
        // ServicesBinding.instance.platformDispatcher because this method might be
        // invoked before any binding is initialized. This issue was reported in
        // #27541. It is not ideal to statically access
        // ui.PlatformDispatcher.instance because the PlatformDispatcher may be
        // dependency injected elsewhere with a different instance. However, static
        // access at this location seems to be the least bad option.
        ui.PlatformDispatcher.instance.sendPlatformMessage(_serviceChannel, message, (ByteData? reply) 
        {
            try 
            {
                completer.complete(reply);
            } 
            catch (exception, stack) 
            {
                FlutterError.reportError(FlutterErrorDetails(
                    exception: exception,
                    stack: stack,
                    library: 'pluginapi',
                    context: ErrorDescription('during a platform message response callback'),
                ));
            }
        });
        return completer.future;
    }
}