import 'dart:io';
import 'dart:typed_data';

class LocalFileSource {
  const LocalFileSource._();

  static Future<Uint8List?> readIfExists(String path) async {
    final file = File(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  static Future<bool> exists(String path) => File(path).exists();

  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last;
}
