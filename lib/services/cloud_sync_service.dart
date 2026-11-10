import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models.dart';
import 'api/api_client.dart';
import 'api/config_api.dart';
import 'image_upload_service.dart';
import 'local_file_source.dart';

class GuestCloudData {
  const GuestCloudData({
    required this.items,
    required this.wishlist,
    required this.storageLocations,
  });

  final List<InventoryItem> items;
  final List<WishEntry> wishlist;
  final List<String> storageLocations;
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.items,
    required this.wishlist,
    required this.storageLocations,
    required this.uploadedImageCount,
    required this.syncedAt,
  });

  final List<InventoryItem> items;
  final List<WishEntry> wishlist;
  final List<String> storageLocations;
  final int uploadedImageCount;
  final DateTime syncedAt;
}

class CloudSyncService {
  CloudSyncService({
    http.Client? client,
    ApiClient? apiClient,
    void Function()? onUnauthorized,
  }) : _api =
           apiClient ??
           ApiClient(client: client, onUnauthorized: onUnauthorized) {
    _config = ConfigApi(_api);
    _imageUploader = ImageUploadService(_api);
  }

  final ApiClient _api;
  late final ConfigApi _config;
  late final ImageUploadService _imageUploader;

  Future<CloudSyncResult> loadAccountData({
    required String phone,
    required String token,
  }) async {
    final values = await Future.wait([
      _readConfig('${phone}ItemData', token),
      _readConfig('${phone}WishListData', token),
      _readConfig('${phone}StorageLocations', token),
    ]);
    return CloudSyncResult(
      items: _parseItems(values[0]),
      wishlist: _parseWishlist(values[1]),
      storageLocations: _parseLocations(values[2]),
      uploadedImageCount: 0,
      syncedAt: DateTime.now(),
    );
  }

  Future<CloudSyncResult> replaceAccountData({
    required String phone,
    required String token,
    required List<InventoryItem> items,
    required List<WishEntry> wishlist,
    required List<String> storageLocations,
  }) async {
    final prepared = await _prepareItemsWithImages(items, token);
    try {
      await _saveAccountData(
        phone: phone,
        token: token,
        items: prepared.items,
        wishlist: wishlist,
        storageLocations: storageLocations,
      );
    } catch (_) {
      await _cleanupUploadedImages(
        prepared.items,
        existingResources: items.expand((item) => item.imagePaths).toSet(),
        token: token,
      );
      rethrow;
    }
    return CloudSyncResult(
      items: prepared.items,
      wishlist: wishlist,
      storageLocations: storageLocations,
      uploadedImageCount: prepared.uploadedImageCount,
      syncedAt: DateTime.now(),
    );
  }

  Future<void> clearAccountData({
    required String phone,
    required String token,
  }) {
    return _saveAccountData(
      phone: phone,
      token: token,
      items: const [],
      wishlist: const [],
      storageLocations: const [],
    );
  }

  Future<void> deleteRemoteImages(
    Iterable<String> resources, {
    required String token,
  }) {
    return _imageUploader.deleteRemoteImages(resources, token: token);
  }

  Future<CloudSyncResult> syncGuestData({
    required String phone,
    required String token,
    required GuestCloudData guest,
  }) async {
    final itemKey = '${phone}ItemData';
    final wishKey = '${phone}WishListData';
    final locationKey = '${phone}StorageLocations';

    final remoteValues = await Future.wait([
      _readConfig(itemKey, token),
      _readConfig(wishKey, token),
      _readConfig(locationKey, token),
    ]);
    final remoteItems = _parseItems(remoteValues[0]);
    final remoteWishlist = _parseWishlist(remoteValues[1]);
    final remoteLocations = _parseLocations(remoteValues[2]);

    final prepared = await _prepareItemsWithImages(guest.items, token);
    final migratedItems = prepared.items;

    final mergedItems = List<InventoryItem>.from(remoteItems);
    final takenIds = mergedItems.map((item) => item.id).toSet();
    for (var index = 0; index < migratedItems.length; index++) {
      final guestItem = migratedItems[index];
      if (takenIds.contains(guestItem.id)) continue;
      var id = guestItem.id;
      if (id.isEmpty || takenIds.contains(id)) {
        id = '${id}_guest_${DateTime.now().millisecondsSinceEpoch}_$index';
      }
      takenIds.add(id);
      mergedItems.add(
        id == guestItem.id ? guestItem : guestItem.copyWith(id: id),
      );
    }

    final mergedWishlist = List<WishEntry>.from(remoteWishlist);
    final wishIds = mergedWishlist.map((entry) => entry.id).toSet();
    for (var index = 0; index < guest.wishlist.length; index++) {
      final entry = guest.wishlist[index];
      if (wishIds.contains(entry.id)) continue;
      var id = entry.id;
      if (id.isEmpty) {
        id = 'wish_${DateTime.now().millisecondsSinceEpoch}_$index';
      }
      wishIds.add(id);
      mergedWishlist.add(id == entry.id ? entry : entry.copyWith(id: id));
    }

    final mergedLocations = <String>{
      ...remoteLocations,
      ...guest.storageLocations,
    }.where((location) => location.trim().isNotEmpty).toList();

    try {
      await _saveAccountData(
        phone: phone,
        token: token,
        items: mergedItems,
        wishlist: mergedWishlist,
        storageLocations: mergedLocations,
      );
    } catch (_) {
      await _cleanupUploadedImages(
        prepared.items,
        existingResources: guest.items
            .expand((item) => item.imagePaths)
            .toSet(),
        token: token,
      );
      rethrow;
    }

    return CloudSyncResult(
      items: mergedItems,
      wishlist: mergedWishlist,
      storageLocations: mergedLocations,
      uploadedImageCount: prepared.uploadedImageCount,
      syncedAt: DateTime.now(),
    );
  }

  void close() => _api.close();

  Future<({List<InventoryItem> items, int uploadedImageCount})>
  _prepareItemsWithImages(List<InventoryItem> source, String token) async {
    final tasks = <({int itemIndex, int imageIndex, String path})>[];
    for (var itemIndex = 0; itemIndex < source.length; itemIndex++) {
      final paths = source[itemIndex].imagePaths;
      for (var imageIndex = 0; imageIndex < paths.length; imageIndex++) {
        tasks.add((
          itemIndex: itemIndex,
          imageIndex: imageIndex,
          path: paths[imageIndex].trim(),
        ));
      }
    }
    var uploadedImageCount = 0;
    final resolved =
        await _mapConcurrent<
          ({int itemIndex, int imageIndex, String path}),
          String?
        >(
          tasks,
          concurrency: 3,
          action: (task) async {
            final clean = task.path;
            if (clean.isEmpty) return null;
            if (clean.startsWith('http://') || clean.startsWith('https://')) {
              return clean;
            }
            if (!await LocalFileSource.exists(clean)) return null;
            final remoteUrl = await _imageUploader.uploadLocalPath(
              clean,
              token: token,
            );
            uploadedImageCount += 1;
            return remoteUrl;
          },
        );
    final pathsByItem = <int, List<String>>{};
    for (var index = 0; index < tasks.length; index++) {
      final task = tasks[index];
      final path = resolved[index];
      if (path == null) continue;
      (pathsByItem[task.itemIndex] ??= []).add(path);
    }
    return (
      items: [
        for (var index = 0; index < source.length; index++)
          source[index].copyWith(imagePaths: pathsByItem[index] ?? const []),
      ],
      uploadedImageCount: uploadedImageCount,
    );
  }

  Future<List<T>> _mapConcurrent<S, T>(
    List<S> source, {
    required int concurrency,
    required Future<T> Function(S value) action,
  }) async {
    final results = List<T?>.filled(source.length, null);
    var nextIndex = 0;
    final workerCount = math.min(
      math.max(1, concurrency),
      math.max(1, source.length),
    );
    await Future.wait([
      for (var worker = 0; worker < workerCount; worker++)
        () async {
          while (nextIndex < source.length) {
            final index = nextIndex++;
            results[index] = await action(source[index]);
          }
        }(),
    ]);
    return results.cast<T>();
  }

  Future<void> _cleanupUploadedImages(
    List<InventoryItem> items, {
    required Set<String> existingResources,
    required String token,
  }) async {
    final uploaded = items
        .expand((item) => item.imagePaths)
        .where(
          (path) =>
              !existingResources.contains(path) &&
              (path.startsWith('https://') || path.startsWith('http://')),
        )
        .toList();
    if (uploaded.isEmpty) return;
    try {
      await _imageUploader.deleteRemoteImages(uploaded, token: token);
    } on Object {
      // Preserve the original save error; orphan cleanup is best effort.
    }
  }

  Future<void> _saveAccountData({
    required String phone,
    required String token,
    required List<InventoryItem> items,
    required List<WishEntry> wishlist,
    required List<String> storageLocations,
  }) async {
    await Future.wait([
      _saveConfig(
        '${phone}ItemData',
        items.map((item) => item.toJson()).toList(),
        '花拾归匣物品数据',
        token,
      ),
      _saveConfig(
        '${phone}WishListData',
        wishlist.map((entry) => entry.toJson()).toList(),
        '花拾归匣心愿匣数据',
        token,
      ),
      _saveConfig(
        '${phone}StorageLocations',
        storageLocations,
        '花拾归匣收纳位置配置',
        token,
      ),
    ]);
  }

  Future<Object?> _readConfig(String key, String token) async {
    return _config.readUser(key, token);
  }

  Future<void> _saveConfig(
    String key,
    Object value,
    String remark,
    String token,
  ) async {
    await _config.saveUser(
      key: key,
      value: value,
      remark: remark,
      token: token,
    );
  }

  Object? _unwrapData(Object? value) {
    var current = value;
    for (var index = 0; index < 5; index++) {
      if (current is Map) {
        final map = current.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (map['data'] != null) {
          current = map['data'];
          continue;
        }
      }
      break;
    }
    return current;
  }

  Object? _decodeConfig(Object? value) {
    var current = _unwrapData(value);
    for (var index = 0; index < 4; index++) {
      if (current is Map) {
        final map = current.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        current = map['paramValue'] ?? map['value'] ?? map['content'];
      }
      if (current is String) {
        final text = current.trim();
        if (text.isEmpty) return null;
        try {
          current = jsonDecode(text);
          continue;
        } on FormatException {
          throw const FormatException('云端配置不是有效的 JSON');
        }
      }
      break;
    }
    return current;
  }

  List<InventoryItem> _parseItems(Object? value) {
    var decoded = _decodeConfig(value);
    if (decoded is Map && decoded['data'] is List) decoded = decoded['data'];
    if (decoded == null) return [];
    if (decoded is! List) throw const FormatException('云端物品配置格式错误');
    final items = <InventoryItem>[];
    for (var index = 0; index < decoded.length; index++) {
      final entry = decoded[index];
      if (entry is! Map) {
        throw FormatException('云端物品配置第 ${index + 1} 项格式错误');
      }
      final map = entry.map((key, value) => MapEntry(key.toString(), value));
      if ((map['id']?.toString().trim() ?? '').isEmpty) {
        throw FormatException('云端物品配置第 ${index + 1} 项缺少 id');
      }
      final item = InventoryItem.fromJson(map);
      final images = item.imagePaths
          .map(
            (path) => path.startsWith('/') && !path.startsWith('//')
                ? '${AppConfig.resourceBaseUrl}$path'
                : path,
          )
          .toList();
      items.add(item.copyWith(imagePaths: images));
    }
    return items;
  }

  List<WishEntry> _parseWishlist(Object? value) {
    var decoded = _decodeConfig(value);
    if (decoded is Map && decoded['data'] is List) decoded = decoded['data'];
    if (decoded == null) return [];
    if (decoded is! List) throw const FormatException('云端心愿配置格式错误');
    final wishes = <WishEntry>[];
    for (var index = 0; index < decoded.length; index++) {
      final entry = decoded[index];
      if (entry is! Map) {
        throw FormatException('云端心愿配置第 ${index + 1} 项格式错误');
      }
      final map = entry.map((key, value) => MapEntry(key.toString(), value));
      if ((map['id']?.toString().trim() ?? '').isEmpty) {
        throw FormatException('云端心愿配置第 ${index + 1} 项缺少 id');
      }
      wishes.add(WishEntry.fromJson(map));
    }
    return wishes;
  }

  List<String> _parseLocations(Object? value) {
    final decoded = _decodeConfig(value);
    if (decoded == null) return [];
    if (decoded is! List) throw const FormatException('云端收纳位置配置格式错误');
    return decoded
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
  }
}
