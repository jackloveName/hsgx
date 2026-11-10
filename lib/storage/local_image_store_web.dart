import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

class LocalImageStore {
  LocalImageStore._();

  static final LocalImageStore instance = LocalImageStore._();
  static const _databaseName = 'hsgx_images';
  static const _storeName = 'images';
  static const _pathPrefix = 'indexeddb:';

  Future<web.IDBDatabase>? _database;

  Future<String> persist(XFile picked) async {
    final bytes = await picked.readAsBytes();
    final name = picked.name;
    final dotIndex = name.lastIndexOf('.');
    final extension = dotIndex >= 0 ? name.substring(dotIndex + 1) : 'jpg';
    final key = 'item_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName.toJS, 'readwrite');
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: _contentType(extension)),
    );
    await _wait(transaction.objectStore(_storeName).put(blob, key.toJS));
    await _waitForTransaction(transaction);
    return '$_pathPrefix$key';
  }

  Future<Uint8List?> load(String path) async {
    if (!path.startsWith(_pathPrefix)) return null;
    final key = path.substring(_pathPrefix.length);
    if (key.isEmpty) return null;
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName.toJS);
    final value = await _wait(
      transaction.objectStore(_storeName).get(key.toJS),
    );
    if (value == null) return null;
    final blob = value as web.Blob;
    final buffer = await blob.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }

  Future<void> delete(String path) async {
    if (!path.startsWith(_pathPrefix)) return;
    final key = path.substring(_pathPrefix.length);
    if (key.isEmpty) return;
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName.toJS, 'readwrite');
    await _wait(transaction.objectStore(_storeName).delete(key.toJS));
    await _waitForTransaction(transaction);
  }

  Future<void> deleteAll() async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName.toJS, 'readwrite');
    await _wait(transaction.objectStore(_storeName).clear());
    await _waitForTransaction(transaction);
  }

  Future<web.IDBDatabase> _openDatabase() {
    return _database ??= () async {
      final request = web.window.indexedDB.open(_databaseName, 1);
      request.addEventListener(
        'upgradeneeded',
        ((web.Event _) {
          final database = request.result as web.IDBDatabase;
          if (!database.objectStoreNames.contains(_storeName)) {
            database.createObjectStore(_storeName);
          }
        }).toJS,
      );
      return await _wait(request) as web.IDBDatabase;
    }();
  }

  Future<JSAny?> _wait(web.IDBRequest request) {
    final completer = Completer<JSAny?>();
    request.addEventListener(
      'success',
      ((web.Event _) {
        if (!completer.isCompleted) completer.complete(request.result);
      }).toJS,
    );
    request.addEventListener(
      'error',
      ((web.Event _) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('图片存储失败：${request.error?.message ?? '未知错误'}'),
          );
        }
      }).toJS,
    );
    return completer.future;
  }

  Future<void> _waitForTransaction(web.IDBTransaction transaction) {
    final completer = Completer<void>();
    transaction.addEventListener(
      'complete',
      ((web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }).toJS,
    );
    transaction.addEventListener(
      'error',
      ((web.Event _) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('图片事务保存失败'));
        }
      }).toJS,
    );
    transaction.addEventListener(
      'abort',
      ((web.Event _) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('图片事务已中止'));
        }
      }).toJS,
    );
    return completer.future;
  }

  String _contentType(String extension) {
    return switch (extension.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}
