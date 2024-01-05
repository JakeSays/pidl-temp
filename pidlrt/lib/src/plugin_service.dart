import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/src/services/binary_messenger.dart';
import 'binary_reader.dart';

typedef MethodHandler = ByteData? Function(BinaryReader? message);

class PluginService
{
    String _channelName;
    String _serviceName;
    late String _serviceChannel;
    final Map<String, MethodHandler> _handlers = <String, MethodHandler>{};

    PluginService(this._channelName, this._serviceName)
    {
        _serviceChannel = '$_channelName/$_serviceName';
    }

    void start()
    {
        ui.channelBuffers.setListener(_serviceChannel, onIncommingMessage);
    }

    void stop()
    {
        ui.channelBuffers.clearListener(_serviceChannel);
    }

    void onIncommingMessage(ByteData? data, void Function(ByteData? data) callback)
    {
        try
        {
            final reader = BinaryReader.fromData(data!);

            final methodName = reader.readString();

            final handler = _handlers[methodName];
            final returnData = handler!(reader);
            if (returnData != null)
            {
                callback(returnData);
            }
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
    }


    void registerMethod(String methodName, MethodHandler handler) 
    {
        _handlers[methodName] = handler;
    }

    bool checkMessageHandler(String channel, MessageHandler? handler) => _handlers[channel] == handler;

    Future<void> handlePlatformMessage(
        String channel,
        ByteData? data,
        ui.PlatformMessageResponseCallback? callback,
    ) async
    {
        ByteData? response;
        try 
        {
            final handler = _handlers[channel];
            if (handler != null) 
            {
                response = await handler(BinaryReader.fromData(data!));
            }
            else 
            {
                ui.channelBuffers.push(channel, data, callback!);
                callback = null;
            }
        } 
        catch (exception, stack) 
        {
            FlutterError.reportError(FlutterErrorDetails(
                exception: exception,
                stack: stack,
                library: 'plugin support',
                context: ErrorDescription('during a platform message callback'),
            ));
        }
        finally 
        {
            if (callback != null) 
            {
                callback(response);
            }
        }
    }

}
