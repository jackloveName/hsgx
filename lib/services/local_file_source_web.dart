import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

class LocalFileSource {
  const LocalFileSource._();

  static Future<Uint8List?> readIfExists(String path) async {
    if (!path.startsWith('blob:') && !path.startsWith('data:')) return null;
    return XFile(path).readAsBytes();
  }

  static Future<bool> exists(String path) async {
    if (!path.startsWith('blob:') && !path.startsWith('data:')) return false;
    return true;
  }

  static String fileName(String path) {
    final uri = Uri.tryParse(path);
    return uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : 'image.jpg';
  }
}
