import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LocalImageStore {
  LocalImageStore._();

  static final LocalImageStore instance = LocalImageStore._();

  Future<String> persist(XFile picked) async {
    final directory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory('${directory.path}/item_photos');
    if (!photoDirectory.existsSync()) {
      await photoDirectory.create(recursive: true);
    }
    final name = picked.name;
    final dotIndex = name.lastIndexOf('.');
    final extension = dotIndex >= 0 ? name.substring(dotIndex + 1) : 'jpg';
    final target =
        '${photoDirectory.path}/item_${DateTime.now().microsecondsSinceEpoch}.$extension';
    await picked.saveTo(target);
    return target;
  }

  Future<void> delete(String path) async {
    if (path.trim().isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteAll() async {
    final directory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory('${directory.path}/item_photos');
    if (await photoDirectory.exists()) {
      await photoDirectory.delete(recursive: true);
    }
  }
}
