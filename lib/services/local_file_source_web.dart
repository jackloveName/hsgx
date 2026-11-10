import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

import '../storage/local_image_store.dart';

class LocalFileSource {
  const LocalFileSource._();

  static Future<Uint8List?> readIfExists(String path) async {
    if (path.startsWith('indexeddb:')) {
      return LocalImageStore.instance.load(path);
    }
    if (!path.startsWith('blob:') && !path.startsWith('data:')) return null;
    return XFile(path).readAsBytes();
  }

  static Future<bool> exists(String path) async {
    if (path.startsWith('indexeddb:')) {
      return await LocalImageStore.instance.load(path) != null;
    }
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
