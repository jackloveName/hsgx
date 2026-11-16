import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppUpdateInstallException implements Exception {
  const AppUpdateInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _installChannel = MethodChannel('hsgx/app_update');

Future<void> downloadAndInstallApk({
  required String url,
  required ValueChanged<double> onProgress,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
    throw const AppUpdateInstallException('更新地址无效，请稍后重试');
  }

  onProgress(0);
  File? apkFile;
  final client = http.Client();
  try {
    final directory = await getTemporaryDirectory();
    apkFile = File(
      path.join(
        directory.path,
        'hsgx-update-${DateTime.now().millisecondsSinceEpoch}.apk',
      ),
    );
    final response = await client
        .send(http.Request('GET', uri))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppUpdateInstallException('更新包下载失败（${response.statusCode}）');
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    final sink = apkFile.openWrite();
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
    if (receivedBytes == 0) {
      throw const AppUpdateInstallException('更新包为空，请稍后重试');
    }
    onProgress(1);

    await _installChannel.invokeMethod<void>('installApk', {
      'path': apkFile.path,
    });
  } on AppUpdateInstallException {
    rethrow;
  } on PlatformException catch (error) {
    throw AppUpdateInstallException(error.message ?? '无法打开安装程序，请稍后重试');
  } on TimeoutException {
    throw const AppUpdateInstallException('更新包下载超时，请稍后重试');
  } on Object {
    throw const AppUpdateInstallException('更新包下载或安装失败，请稍后重试');
  } finally {
    client.close();
  }
}
