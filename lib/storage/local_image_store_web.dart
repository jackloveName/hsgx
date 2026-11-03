import 'package:image_picker/image_picker.dart';

class LocalImageStore {
  LocalImageStore._();

  static final LocalImageStore instance = LocalImageStore._();

  // Browser object URLs remain valid for the current page lifetime. Persistent
  // web image bytes should be moved to IndexedDB when cloud storage is added.
  Future<String> persist(XFile picked) async => picked.path;

  Future<void> delete(String path) async {}

  Future<void> deleteAll() async {}
}
