import 'dart:convert';

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
  CloudSyncService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
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
    await _saveAccountData(
      phone: phone,
      token: token,
      items: prepared.items,
      wishlist: wishlist,
      storageLocations: storageLocations,
    );
    return CloudSyncResult(
      items: prepared.items,
      wishlist: wishlist,
      storageLocations: storageLocations,
      uploadedImageCount: prepared.uploadedImageCount,
      syncedAt: DateTime.now(),
    );
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

    await _saveAccountData(
      phone: phone,
      token: token,
      items: mergedItems,
      wishlist: mergedWishlist,
      storageLocations: mergedLocations,
    );

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
    var uploadedImageCount = 0;
    final items = <InventoryItem>[];
    for (final item in source) {
      final uploadedPaths = <String>[];
      for (final imagePath in item.imagePaths) {
        final clean = imagePath.trim();
        if (clean.isEmpty ||
            clean.startsWith('http://') ||
            clean.startsWith('https://')) {
          if (clean.isNotEmpty) uploadedPaths.add(clean);
          continue;
        }
        if (!await LocalFileSource.exists(clean)) continue;
        final remoteUrl = await _imageUploader.uploadLocalPath(
          clean,
          token: token,
        );
        uploadedPaths.add(remoteUrl);
        uploadedImageCount += 1;
      }
      items.add(item.copyWith(imagePaths: uploadedPaths));
    }
    return (items: items, uploadedImageCount: uploadedImageCount);
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
          return text;
        }
      }
      break;
    }
    return current;
  }

  List<InventoryItem> _parseItems(Object? value) {
    var decoded = _decodeConfig(value);
    if (decoded is Map && decoded['data'] is List) decoded = decoded['data'];
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((entry) {
      final item = InventoryItem.fromJson(
        entry.map((key, value) => MapEntry(key.toString(), value)),
      );
      final images = item.imagePaths
          .map(
            (path) => path.startsWith('/') && !path.startsWith('//')
                ? '${AppConfig.resourceBaseUrl}$path'
                : path,
          )
          .toList();
      return item.copyWith(imagePaths: images);
    }).toList();
  }

  List<WishEntry> _parseWishlist(Object? value) {
    var decoded = _decodeConfig(value);
    if (decoded is Map && decoded['data'] is List) decoded = decoded['data'];
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((entry) {
      return WishEntry.fromJson(
        entry.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  List<String> _parseLocations(Object? value) {
    final decoded = _decodeConfig(value);
    if (decoded is! List) return [];
    return decoded
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
  }
}
