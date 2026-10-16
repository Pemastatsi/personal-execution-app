import 'dart:io';

import 'package:flutter/services.dart';

import 'protocol.dart';

const _channel = MethodChannel('personal_execution/chatgpt');

Future<void> openSystemBrowser(Uri uri) async {
  if (Platform.isAndroid) {
    await _channel.invokeMethod<void>('openBrowser', uri.toString());
  } else if (Platform.isWindows) {
    final result = await Process.run('rundll32.exe', ['url.dll,FileProtocolHandler', uri.toString()]);
    if (result.exitCode != 0) throw const ConnectionFailure('The system browser could not be opened.');
  } else {
    throw const ConnectionFailure('This proof of concept supports Android and Windows.');
  }
}

class ScreenshotAttachment {
  ScreenshotAttachment(this.bytes, this.mime);
  final Uint8List bytes;
  final String mime;
}

Future<ScreenshotAttachment?> selectScreenshot() async {
  if (!Platform.isAndroid) throw const ConnectionFailure('Screenshot selection is available in the Android proof of concept.');
  final result = await _channel.invokeMapMethod<String, dynamic>('pickScreenshot');
  if (result == null) return null;
  final bytes = result['bytes'] as Uint8List;
  final mime = result['mime'] as String;
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024 || !['image/png', 'image/jpeg', 'image/webp'].contains(mime)) {
    throw const ConnectionFailure('Choose a PNG, JPEG, or WebP screenshot under 5 MiB.');
  }
  return ScreenshotAttachment(bytes, mime);
}
