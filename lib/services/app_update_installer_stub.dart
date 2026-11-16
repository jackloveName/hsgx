import 'package:flutter/foundation.dart';

class AppUpdateInstallException implements Exception {
  const AppUpdateInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> downloadAndInstallApk({
  required String url,
  required ValueChanged<double> onProgress,
}) {
  throw const AppUpdateInstallException('当前平台不支持应用内安装，请前往下载页更新');
}
