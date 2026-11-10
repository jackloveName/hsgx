import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'services/cloud_sync_service.dart';
import 'storage/app_state_storage.dart';
import 'storage/default_app_state_storage.dart';
import 'storage/local_image_store.dart';
import 'storage/session_token_store.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    AppStateStorage? storage,
    SessionTokenStore? tokenStore,
    CloudSyncService? cloudService,
  }) : _storage = storage ?? createDefaultAppStateStorage(),
       _tokenStore =
           tokenStore ??
           (storage == null
               ? const SecureSessionTokenStore()
               : MemorySessionTokenStore()) {
    _cloudService =
        cloudService ?? CloudSyncService(onUnauthorized: handleUnauthorized);
  }

  static final AppStore instance = AppStore();
  static const _storageKey = 'hsgx_flutter_state_v1';
  static const _backupKey = '${_storageKey}_backup';
  static const _schemaVersion = 7;
  static const guestRetention = Duration(days: 3);
  static const guestAddLimit = 3;

  final AppStateStorage _storage;
  final SessionTokenStore _tokenStore;
  late final CloudSyncService _cloudService;
  Future<void> _writeQueue = Future.value();
  Future<void> _cloudSyncQueue = Future.value();
  final ValueNotifier<int> _skinNotifier = ValueNotifier(0);

  final List<InventoryItem> _items = [];
  final List<WishEntry> _wishlist = [];
  final List<String> _storageLocations = [
    '玄关',
    '客厅',
    '卧室',
    '书房',
    '厨房',
    '卫生间',
    '其他',
  ];

  bool isReady = false;
  int skinIndex = 0;
  String authMode = 'guest';
  String accountPhone = '';
  String accountName = '拾花人';
  String accountAvatarPath = '';
  String accountBirthday = '';
  String accountGender = '';
  String sessionToken = '';
  DateTime? guestStartedAt;
  int guestAddCount = 0;
  DateTime? lastCloudSyncedAt;
  bool cloudSyncPending = false;
  String? cloudSyncError;
  String? guestDataNotice;
  String? _globalNotice;
  DateTime? lastSavedAt;
  String? loadError;
  String? persistenceWarning;
  bool _corruptedDataBlocked = false;
  bool _accountCacheLocked = false;
  bool _sessionExpiryScheduled = false;
  int _pendingWrites = 0;
  int _dataRevision = 0;

  List<InventoryItem> get items => List.unmodifiable(_items);
  List<WishEntry> get wishlist => List.unmodifiable(_wishlist);
  List<String> get storageLocations => List.unmodifiable(_storageLocations);
  List<InventoryItem> get activeItems =>
      _items.where((item) => item.isActive).toList();
  ValueListenable<int> get skinListenable => _skinNotifier;
  bool get isSaving => _pendingWrites > 0;
  bool get accountCacheLocked => _accountCacheLocked;
  int get dataRevision => _dataRevision;
  int get foreignCurrencyItemCount => _items
      .where((item) => item.isActive && !item.canAggregateInBaseCurrency)
      .length;
  bool get hasForeignCurrencyItems => foreignCurrencyItemCount > 0;
  GuestCloudData get guestCloudData {
    if (_accountCacheLocked) {
      return const GuestCloudData(
        items: [],
        wishlist: [],
        storageLocations: [],
      );
    }
    return GuestCloudData(
      items: List<InventoryItem>.from(_items),
      wishlist: List<WishEntry>.from(_wishlist),
      storageLocations: List<String>.from(_storageLocations),
    );
  }

  bool get isGuest => authMode != 'account' || sessionToken.isEmpty;
  bool get isAuthenticated => !isGuest;
  String get displayName => isGuest ? '游客' : accountName;
  DateTime? get guestExpiresAt => guestStartedAt?.add(guestRetention);
  int get guestAddsRemaining => _accountCacheLocked
      ? 0
      : isGuest
      ? math.max(0, guestAddLimit - guestAddCount)
      : guestAddLimit;
  bool get canAddGuestItem =>
      !_accountCacheLocked && (!isGuest || guestAddCount < guestAddLimit);
  int get guestDaysRemaining {
    final expiresAt = guestExpiresAt;
    if (_accountCacheLocked || !isGuest || expiresAt == null) return 0;
    final remaining = expiresAt.difference(DateTime.now());
    return math.max(0, (remaining.inSeconds / Duration.secondsPerDay).ceil());
  }

  bool get guestExpiryWarning =>
      guestStartedAt != null && guestDaysRemaining <= 1;

  double get totalPurchaseValue => _items
      .where((item) => item.canAggregateInBaseCurrency)
      .fold(0, (sum, item) => sum + item.purchaseTotal);
  double get totalCurrentValue => activeItems
      .where((item) => item.canAggregateInBaseCurrency)
      .fold(0, (sum, item) => sum + item.currentTotal);
  double get totalOwnedDaily => activeItems
      .where((item) => item.canAggregateInBaseCurrency)
      .fold(0, (sum, item) => sum + item.ownedDailyCost);
  double get avoidedAmount => _wishlist
      .where((entry) => entry.status == 'abandoned')
      .fold(0, (sum, entry) => sum + entry.expectedPrice);
  double get recoveredAmount => _items
      .where(
        (item) => item.status == 'processed' && item.canAggregateInBaseCurrency,
      )
      .fold(0, (sum, item) => sum + item.cashRecoveredAmount);

  int countByStatus(String status) =>
      _items.where((item) => item.status == status).length;

  String? consumeGuestDataNotice() {
    final notice = guestDataNotice;
    guestDataNotice = null;
    return notice;
  }

  String? consumeGlobalNotice() {
    final notice = _globalNotice;
    _globalNotice = null;
    return notice;
  }

  InventoryItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    loadError = null;
    persistenceWarning = null;
    _corruptedDataBlocked = false;
    _accountCacheLocked = false;
    _dataRevision = 0;

    String? primary;
    String? backup;
    try {
      primary = await _storage.read(_storageKey);
      backup = await _storage.read(_backupKey);
    } catch (error) {
      _corruptedDataBlocked = true;
      loadError = '本地存储暂时无法读取，已停止写入以保护数据：$error';
      isReady = true;
      notifyListeners();
      return;
    }
    _AppSnapshot? loaded;
    var restoredFromBackup = false;
    var primaryUsesFutureSchema = false;

    if (primary != null && primary.isNotEmpty) {
      try {
        loaded = _decodeSnapshot(primary);
      } catch (error) {
        primaryUsesFutureSchema = error.toString().contains('版本高于');
        loaded = null;
      }
    }

    if (loaded == null &&
        !primaryUsesFutureSchema &&
        backup != null &&
        backup.isNotEmpty) {
      try {
        loaded = _decodeSnapshot(backup);
        restoredFromBackup = true;
      } catch (_) {
        loaded = null;
      }
    }

    if (loaded != null) {
      _applySnapshot(loaded);
      final now = DateTime.now();
      String? storedToken;
      var tokenStorageFailed = false;
      try {
        storedToken = await _tokenStore.read();
        if ((storedToken == null || storedToken.isEmpty) &&
            loaded.sessionToken.isNotEmpty) {
          storedToken = loaded.sessionToken;
          await _tokenStore.write(storedToken);
        }
      } on Object {
        tokenStorageFailed = true;
        persistenceWarning = '登录凭证读取失败，本次以游客模式启动';
      }
      sessionToken = storedToken?.trim() ?? '';
      if (authMode == 'guest' && sessionToken.isNotEmpty) {
        try {
          await _tokenStore.clear();
        } on Object {
          persistenceWarning = '本机遗留登录凭证清理失败';
        }
        sessionToken = '';
      }
      if (authMode == 'account' && sessionToken.isEmpty) {
        _accountCacheLocked = true;
        cloudSyncPending = false;
        cloudSyncError = null;
        loadError = tokenStorageFailed
            ? '登录凭证暂时无法读取，账号缓存已保护，请重新登录'
            : '登录状态已失效，账号缓存已保护，请重新登录';
        guestDataNotice = loadError;
      } else if (isGuest && guestStartedAt == null) {
        guestStartedAt = now;
      }
      final expired =
          !_accountCacheLocked &&
          isGuest &&
          guestExpiresAt != null &&
          !guestExpiresAt!.isAfter(now);
      if (expired) _clearGuestData(now);
      final normalized = _encodeSnapshot();
      if (primary == null ||
          primary.isEmpty ||
          restoredFromBackup ||
          primary != normalized) {
        final repaired = await _storage.write(_storageKey, normalized);
        if (!repaired) {
          persistenceWarning = '本地数据已载入，但主数据文件修复失败';
        }
      }
      if (restoredFromBackup) {
        loadError = '主数据文件损坏，已从最近一次备份恢复';
      }
      if ((primary?.contains('"sessionToken"') ?? false) ||
          (backup?.contains('"sessionToken"') ?? false)) {
        await _storage.write(_backupKey, '');
      }
      if (expired) {
        await _storage.write(_backupKey, '');
        try {
          await LocalImageStore.instance.deleteAll();
        } on Object {
          // Expired records are already removed; image cleanup is best effort.
        }
      }
      lastSavedAt = DateTime.now();
    } else if ((primary != null && primary.isNotEmpty) ||
        (backup != null && backup.isNotEmpty)) {
      final protectedData = primary != null && primary.isNotEmpty
          ? primary
          : backup!;
      _corruptedDataBlocked = true;
      loadError = primaryUsesFutureSchema
          ? '本地数据来自更高版本应用，已停止写入以避免降级损坏'
          : '本地数据损坏且没有可用备份，已停止写入以保护原始文件';
      await _storage.write(
        '${_storageKey}_corrupt_${DateTime.now().millisecondsSinceEpoch}',
        protectedData,
      );
    } else {
      authMode = 'guest';
      guestStartedAt = DateTime.now();
      final created = await _storage.write(_storageKey, _encodeSnapshot(null));
      if (!created) {
        persistenceWarning = '本地存储初始化失败';
      } else {
        lastSavedAt = DateTime.now();
      }
    }
    isReady = true;
    notifyListeners();
  }

  _AppSnapshot _decodeSnapshot(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('本地数据根节点格式错误');
    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    if (!map.containsKey('items') && !map.containsKey('wishlist')) {
      throw const FormatException('本地数据缺少必要字段');
    }
    final version = (map['version'] as num?)?.toInt() ?? 1;
    if (version > _schemaVersion) {
      throw StateError('本地数据版本高于当前应用支持版本');
    }

    List<Map<String, Object?>> objectList(String field) {
      final source = map[field];
      if (source == null) return const [];
      if (source is! List) throw FormatException('$field 格式错误');
      return source.map((entry) {
        if (entry is! Map) throw FormatException('$field 包含无效条目');
        return entry.map((key, value) => MapEntry(key.toString(), value));
      }).toList();
    }

    final itemMaps = objectList('items');
    final wishMaps = objectList('wishlist');
    final rawLocations = map['storageLocations'];
    final locations = rawLocations is List
        ? rawLocations
              .map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toSet()
              .toList()
        : const <String>[];

    final items = itemMaps.map(InventoryItem.fromJson).toList();
    final authMode = map['authMode']?.toString() == 'account'
        ? 'account'
        : 'guest';
    final guestAddCount =
        (map['guestAddCount'] as num?)?.toInt() ??
        (authMode == 'guest'
            ? math.min(items.length, AppStore.guestAddLimit)
            : 0);
    return _AppSnapshot(
      version: version,
      items: items,
      wishlist: wishMaps.map(WishEntry.fromJson).toList(),
      storageLocations: locations,
      skinIndex: (map['skinIndex'] as num?)?.toInt() ?? 0,
      authMode: authMode,
      accountPhone: map['accountPhone']?.toString() ?? '',
      accountName: map['accountName']?.toString() ?? '拾花人',
      accountAvatarPath: map['accountAvatarPath']?.toString() ?? '',
      accountBirthday: map['accountBirthday']?.toString() ?? '',
      accountGender: map['accountGender']?.toString() ?? '',
      sessionToken: map['sessionToken']?.toString() ?? '',
      guestStartedAt: DateTime.tryParse(
        map['guestStartedAt']?.toString() ?? '',
      ),
      guestAddCount: guestAddCount,
      cloudSyncPending: map['cloudSyncPending'] == true,
      cloudSyncError: map['cloudSyncError']?.toString(),
      lastCloudSyncedAt: DateTime.tryParse(
        map['lastCloudSyncedAt']?.toString() ?? '',
      ),
    );
  }

  void _applySnapshot(_AppSnapshot snapshot) {
    _items
      ..clear()
      ..addAll(snapshot.items);
    _wishlist
      ..clear()
      ..addAll(snapshot.wishlist);
    _storageLocations
      ..clear()
      ..addAll(
        snapshot.storageLocations.isEmpty
            ? const ['玄关', '客厅', '卧室', '书房', '厨房', '卫生间', '其他']
            : snapshot.storageLocations,
      );
    skinIndex = snapshot.skinIndex;
    authMode = snapshot.authMode;
    accountPhone = snapshot.accountPhone;
    accountName = snapshot.accountName;
    accountAvatarPath = snapshot.accountAvatarPath;
    accountBirthday = snapshot.accountBirthday;
    accountGender = snapshot.accountGender;
    guestStartedAt = snapshot.guestStartedAt;
    guestAddCount = snapshot.guestAddCount;
    cloudSyncPending = snapshot.cloudSyncPending;
    cloudSyncError = snapshot.cloudSyncError;
    lastCloudSyncedAt = snapshot.lastCloudSyncedAt;
    _skinNotifier.value = skinIndex;
  }

  String _encodeSnapshot([_AppSnapshot? provided]) {
    final snapshot =
        provided ??
        _AppSnapshot(
          version: _schemaVersion,
          items: List<InventoryItem>.from(_items),
          wishlist: List<WishEntry>.from(_wishlist),
          storageLocations: List<String>.from(_storageLocations),
          skinIndex: skinIndex,
          authMode: authMode,
          accountPhone: accountPhone,
          accountName: accountName,
          accountAvatarPath: accountAvatarPath,
          accountBirthday: accountBirthday,
          accountGender: accountGender,
          guestStartedAt: guestStartedAt,
          guestAddCount: guestAddCount,
          cloudSyncPending: cloudSyncPending,
          cloudSyncError: cloudSyncError,
          lastCloudSyncedAt: lastCloudSyncedAt,
        );
    return jsonEncode({
      'version': _schemaVersion,
      'items': snapshot.items.map((item) => item.toJson()).toList(),
      'wishlist': snapshot.wishlist.map((entry) => entry.toJson()).toList(),
      'storageLocations': snapshot.storageLocations,
      'skinIndex': snapshot.skinIndex,
      'authMode': snapshot.authMode,
      'accountPhone': snapshot.accountPhone,
      'accountName': snapshot.accountName,
      'accountAvatarPath': snapshot.accountAvatarPath,
      'accountBirthday': snapshot.accountBirthday,
      'accountGender': snapshot.accountGender,
      'guestStartedAt': snapshot.guestStartedAt?.toIso8601String(),
      'guestAddCount': snapshot.guestAddCount,
      'cloudSyncPending': snapshot.cloudSyncPending,
      'cloudSyncError': snapshot.cloudSyncError,
      'lastCloudSyncedAt': snapshot.lastCloudSyncedAt?.toIso8601String(),
    });
  }

  Future<void> _persistSnapshot(String payload, String previousPayload) async {
    if (previousPayload.isNotEmpty && previousPayload != payload) {
      final backupSaved = await _storage.write(_backupKey, previousPayload);
      if (!backupSaved) throw StateError('无法写入本地备份');
    }
    final saved = await _storage.write(_storageKey, payload);
    if (!saved) throw StateError('本地存储写入失败');
  }

  void _clearGuestData(DateTime now) {
    _items.clear();
    _wishlist.clear();
    _storageLocations
      ..clear()
      ..addAll(['玄关', '客厅', '卧室', '书房', '厨房', '卫生间', '其他']);
    guestStartedAt = now;
    guestAddCount = 0;
    guestDataNotice = '游客数据仅保存 3 天，上一轮游客数据已自动清理';
  }

  Future<bool> expireGuestDataIfNeeded({DateTime? now}) async {
    final current = now ?? DateTime.now();
    if (!isGuest) return false;
    final expiresAt = guestExpiresAt;
    if (expiresAt == null || expiresAt.isAfter(current)) return false;
    await _mutate(
      () => _clearGuestData(current),
      allowCorruptedOverwrite: true,
    );
    await _storage.write(_backupKey, '');
    try {
      await LocalImageStore.instance.deleteAll();
    } on Object {
      // Data expiry succeeded; missing image permissions should not restore it.
    }
    return true;
  }

  Future<void> completeAccountSync({
    required String token,
    required String phone,
    required String name,
    required CloudSyncResult result,
    String avatarPath = '',
    String birthday = '',
    String gender = '',
  }) async {
    await _tokenStore.write(token);
    try {
      await _mutate(() {
        _items
          ..clear()
          ..addAll(result.items);
        _wishlist
          ..clear()
          ..addAll(result.wishlist);
        _storageLocations
          ..clear()
          ..addAll(
            result.storageLocations.isEmpty
                ? const ['玄关', '客厅', '卧室', '书房', '厨房', '卫生间', '其他']
                : result.storageLocations,
          );
        authMode = 'account';
        _accountCacheLocked = false;
        accountPhone = phone;
        accountName = name;
        accountAvatarPath = avatarPath;
        accountBirthday = birthday;
        accountGender = gender;
        sessionToken = token;
        guestStartedAt = null;
        guestAddCount = 0;
        loadError = null;
        lastCloudSyncedAt = result.syncedAt;
        cloudSyncPending = false;
        cloudSyncError = null;
        guestDataNotice =
            '已同步 ${result.items.length} 件物品'
            '${result.uploadedImageCount > 0 ? '和 ${result.uploadedImageCount} 张图片' : ''}';
      }, allowCorruptedOverwrite: true);
    } catch (_) {
      await _tokenStore.clear();
      rethrow;
    }
    await _storage.write(_backupKey, '');
    try {
      await LocalImageStore.instance.deleteAll();
    } on Object {
      // The guest snapshot is already replaced by the account cache.
    }
    notifyListeners();
  }

  Future<void> logoutToGuest() async {
    await _mutate(() {
      _items.clear();
      _wishlist.clear();
      _storageLocations
        ..clear()
        ..addAll(['玄关', '客厅', '卧室', '书房', '厨房', '卫生间', '其他']);
      authMode = 'guest';
      _accountCacheLocked = false;
      accountPhone = '';
      accountName = '拾花人';
      accountAvatarPath = '';
      accountBirthday = '';
      accountGender = '';
      sessionToken = '';
      guestStartedAt = DateTime.now();
      guestAddCount = 0;
      lastCloudSyncedAt = null;
      cloudSyncPending = false;
      cloudSyncError = null;
      guestDataNotice = '已退出账号，当前以游客身份使用';
    }, allowCorruptedOverwrite: true);
    try {
      await _tokenStore.clear();
    } on Object {
      persistenceWarning = '本机登录凭证清理失败';
    }
    await _storage.write(_backupKey, '');
    try {
      await LocalImageStore.instance.deleteAll();
    } on Object {
      // Account cloud data is still available after the next login.
    }
    notifyListeners();
  }

  void handleUnauthorized() {
    if (isGuest || _sessionExpiryScheduled) return;
    _sessionExpiryScheduled = true;
    unawaited(Future<void>.microtask(_expireSession));
  }

  Future<void> _expireSession() async {
    try {
      await logoutToGuest();
      _globalNotice = '登录状态已失效，请重新登录';
      notifyListeners();
    } finally {
      _sessionExpiryScheduled = false;
    }
  }

  Future<void> _mutate(
    void Function() change, {
    bool allowCorruptedOverwrite = false,
    bool syncAccount = true,
    bool backupPrevious = true,
  }) {
    if (_corruptedDataBlocked && !allowCorruptedOverwrite) {
      return Future.error(StateError('本地数据读取异常，已阻止覆盖。请保留原始数据文件并联系支持'));
    }
    if (_accountCacheLocked && !allowCorruptedOverwrite) {
      return Future.error(StateError('账号登录状态不可用，本地缓存已保护，请重新登录后再修改'));
    }
    _pendingWrites += 1;
    notifyListeners();
    final operation = _writeQueue.then((_) async {
      final beforePayload = _encodeSnapshot();
      final before = _decodeSnapshot(beforePayload);
      final wasAuthenticated = isAuthenticated;
      try {
        change();
      } catch (error) {
        _applySnapshot(before);
        _pendingWrites = math.max(0, _pendingWrites - 1);
        notifyListeners();
        rethrow;
      }
      final shouldSyncCloud =
          syncAccount && wasAuthenticated && isAuthenticated;
      if (shouldSyncCloud) {
        cloudSyncPending = true;
        cloudSyncError = null;
      }
      try {
        final payload = _encodeSnapshot();
        await _persistSnapshot(
          payload,
          backupPrevious ? beforePayload : payload,
        );
        _corruptedDataBlocked = false;
        persistenceWarning = null;
        lastSavedAt = DateTime.now();
        _dataRevision += 1;
        _skinNotifier.value = skinIndex;
      } catch (error) {
        _applySnapshot(before);
        persistenceWarning = '保存失败，已恢复修改前状态：$error';
        _pendingWrites = math.max(0, _pendingWrites - 1);
        notifyListeners();
        rethrow;
      }
      _pendingWrites = math.max(0, _pendingWrites - 1);
      notifyListeners();
      if (shouldSyncCloud) {
        unawaited(_scheduleCloudSync());
      }
    });
    _writeQueue = operation.then<void>((_) {}).catchError((_) {});
    return operation;
  }

  Future<void> _scheduleCloudSync() {
    if (!isAuthenticated || _accountCacheLocked) return Future.value();
    cloudSyncPending = true;
    cloudSyncError = null;
    notifyListeners();
    final operation = _cloudSyncQueue.then((_) => _drainCloudSync());
    _cloudSyncQueue = operation.catchError((_) {});
    return operation;
  }

  Future<void> _drainCloudSync() async {
    while (cloudSyncPending && isAuthenticated && !_accountCacheLocked) {
      final revision = _dataRevision;
      final phone = accountPhone;
      final token = sessionToken;
      final items = List<InventoryItem>.from(_items);
      final wishlist = List<WishEntry>.from(_wishlist);
      final locations = List<String>.from(_storageLocations);
      final localImages = items
          .expand((item) => item.imagePaths)
          .where(
            (path) =>
                path.isNotEmpty &&
                !path.startsWith('http://') &&
                !path.startsWith('https://'),
          )
          .toSet();
      try {
        final result = await _cloudService.replaceAccountData(
          phone: phone,
          token: token,
          items: items,
          wishlist: wishlist,
          storageLocations: locations,
        );
        if (!isAuthenticated || sessionToken != token) return;
        await _writeQueue;
        if (revision != _dataRevision) continue;
        await _mutate(
          () {
            _items
              ..clear()
              ..addAll(result.items);
            _wishlist
              ..clear()
              ..addAll(result.wishlist);
            _storageLocations
              ..clear()
              ..addAll(result.storageLocations);
            lastCloudSyncedAt = result.syncedAt;
            cloudSyncPending = false;
            cloudSyncError = null;
          },
          allowCorruptedOverwrite: true,
          syncAccount: false,
          backupPrevious: false,
        );
        for (final path in localImages) {
          try {
            await LocalImageStore.instance.delete(path);
          } on Object {
            // The synchronized record already references the remote copy.
          }
        }
      } catch (error) {
        if (!isAuthenticated || sessionToken != token) return;
        cloudSyncPending = true;
        cloudSyncError = error.toString().replaceFirst('Bad state: ', '');
        await _mutate(() {}, allowCorruptedOverwrite: true, syncAccount: false);
        return;
      }
    }
  }

  Future<bool> applyCloudRefresh(
    CloudSyncResult result, {
    int? expectedRevision,
  }) async {
    if (expectedRevision != null && _dataRevision != expectedRevision) {
      return false;
    }
    await _mutate(
      () {
        if (expectedRevision != null && _dataRevision != expectedRevision) {
          throw StateError('本地数据刚刚发生变化，已取消本次云端覆盖');
        }
        _items
          ..clear()
          ..addAll(result.items);
        _wishlist
          ..clear()
          ..addAll(result.wishlist);
        _storageLocations
          ..clear()
          ..addAll(
            result.storageLocations.isEmpty
                ? const ['玄关', '客厅', '卧室', '书房', '厨房', '卫生间', '其他']
                : result.storageLocations,
          );
        lastCloudSyncedAt = result.syncedAt;
      },
      allowCorruptedOverwrite: true,
      syncAccount: false,
    );
    return true;
  }

  Future<bool> retryCloudSync() async {
    if (isGuest || _accountCacheLocked) return false;
    cloudSyncPending = true;
    cloudSyncError = null;
    await _scheduleCloudSync();
    return !cloudSyncPending;
  }

  Future<void> purgeCloudAccountData() async {
    if (isGuest) return;
    final phone = accountPhone;
    final token = sessionToken;
    final resources = <String>[
      for (final item in _items) ...item.imagePaths,
      accountAvatarPath,
    ];
    try {
      await _cloudService.deleteRemoteImages(resources, token: token);
    } catch (error) {
      throw StateError(
        '云端图片清理失败，账号数据尚未删除：'
        '${error.toString().replaceFirst('Bad state: ', '')}',
      );
    }
    try {
      await _cloudService.clearAccountData(phone: phone, token: token);
    } catch (error) {
      throw StateError(
        '云端数据清理失败：${error.toString().replaceFirst('Bad state: ', '')}',
      );
    }
  }

  Future<void> addItem(InventoryItem item) async {
    if (isGuest && !canAddGuestItem) {
      return Future.error(StateError('游客模式最多添加 3 次物品，登录后可不限次数记录'));
    }
    await _mutate(() {
      _items.insert(0, item);
      if (isGuest) guestAddCount += 1;
    });
  }

  Future<void> updateItem(InventoryItem item) async {
    final previous = itemById(item.id);
    await _mutate(() {
      final index = _items.indexWhere((entry) => entry.id == item.id);
      if (index >= 0) _items[index] = item;
    });
    if (previous != null && isAuthenticated && !cloudSyncPending) {
      final retained = item.imagePaths.toSet();
      await _deleteRemoteImages(
        previous.imagePaths.where((path) => !retained.contains(path)),
      );
    }
  }

  Future<void> deleteItem(String id) async {
    final previous = itemById(id);
    await _mutate(() {
      _items.removeWhere((item) => item.id == id);
      for (var index = 0; index < _items.length; index++) {
        final item = _items[index];
        if (!item.relatedItemIds.contains(id)) continue;
        _items[index] = item.copyWith(
          relatedItemIds: item.relatedItemIds
              .where((relatedId) => relatedId != id)
              .toList(),
        );
      }
    });
    if (previous != null && isAuthenticated && !cloudSyncPending) {
      await _deleteRemoteImages(previous.imagePaths);
    }
  }

  Future<void> _deleteRemoteImages(Iterable<String> resources) async {
    final remote = resources
        .where(
          (path) => path.startsWith('https://') || path.startsWith('http://'),
        )
        .toList();
    if (remote.isEmpty || !isAuthenticated) return;
    try {
      await _cloudService.deleteRemoteImages(remote, token: sessionToken);
    } catch (error) {
      cloudSyncError = error.toString().replaceFirst('Bad state: ', '');
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    await _mutate(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final item = _items[index];
        _items[index] = item.copyWith(favorite: !item.favorite);
      }
    });
  }

  Future<void> setRelatedItems(String id, Iterable<String> relatedIds) async {
    final targets = relatedIds.where((relatedId) => relatedId != id).toSet();
    await _mutate(() {
      final sourceIndex = _items.indexWhere((item) => item.id == id);
      if (sourceIndex < 0) return;
      final validIds = targets
          .where(
            (relatedId) =>
                _items.any((item) => item.id == relatedId && item.isActive),
          )
          .toSet();
      for (var index = 0; index < _items.length; index++) {
        final item = _items[index];
        final related = item.relatedItemIds.toSet();
        if (item.id == id) {
          _items[index] = item.copyWith(relatedItemIds: validIds.toList());
        } else if (validIds.contains(item.id)) {
          related.add(id);
          _items[index] = item.copyWith(relatedItemIds: related.toList());
        } else {
          related.remove(id);
          if (related.length != item.relatedItemIds.length) {
            _items[index] = item.copyWith(relatedItemIds: related.toList());
          }
        }
      }
    });
  }

  Future<void> updateAccountProfile({
    required String name,
    required String avatarPath,
    required String birthday,
    required String gender,
  }) async {
    await _mutate(() {
      accountName = name.trim().isEmpty ? accountPhone : name.trim();
      accountAvatarPath = avatarPath.trim();
      accountBirthday = birthday.trim();
      accountGender = gender.trim();
    }, syncAccount: false);
  }

  Future<void> changeStatus(
    String id,
    String status, {
    String idleReason = '',
    String repairPlatform = '',
    int repairDays = 0,
    String repairContactName = '',
    String repairContactPhone = '',
    String disposalMethod = '',
    String disposalDetail = '',
    String disposalPlatform = '',
    String disposalContact = '',
    double disposalPrice = 0,
    double disposalCost = 0,
    String processDate = '',
  }) async {
    await _mutate(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index < 0) return;
      final item = _items[index];
      final now = DateTime.now();
      final normalizedDisposalPrice =
          disposalMethod == '转卖' || disposalMethod == '回收'
          ? math.max(0.0, disposalPrice)
          : 0.0;
      final normalizedDisposalCost =
          disposalMethod == '转卖' || disposalMethod == '回收'
          ? math.max(0.0, disposalCost)
          : 0.0;
      final note = switch (status) {
        'idle' => idleReason.trim().isEmpty ? '' : '闲置原因：${idleReason.trim()}',
        'repairing' => [
          if (repairPlatform.trim().isNotEmpty) repairPlatform.trim(),
          if (repairDays > 0) '预计 $repairDays 天',
        ].join(' · '),
        'processed' => [
          disposalMethod,
          if (disposalPlatform.trim().isNotEmpty) disposalPlatform.trim(),
          if (normalizedDisposalPrice > 0)
            '${item.currencySymbol}${formatMoney(normalizedDisposalPrice)}',
          if (normalizedDisposalCost > 0)
            '成本 ${item.currencySymbol}${formatMoney(normalizedDisposalCost)}',
        ].join(' · '),
        'retired' => '物品已退役',
        _ => '恢复使用中',
      };
      final history = [
        ...item.statusHistory,
        StatusEvent(status: status, at: now.toIso8601String(), note: note),
      ];
      _items[index] = item.copyWith(
        status: status,
        statusHistory: history,
        idleReason: status == 'idle' ? idleReason.trim() : item.idleReason,
        repairPlatform: status == 'repairing'
            ? repairPlatform.trim()
            : item.repairPlatform,
        repairDays: status == 'repairing' ? repairDays : item.repairDays,
        repairContactName: status == 'repairing'
            ? repairContactName.trim()
            : item.repairContactName,
        repairContactPhone: status == 'repairing'
            ? repairContactPhone.trim()
            : item.repairContactPhone,
        disposalMethod: status == 'processed'
            ? disposalMethod
            : item.disposalMethod,
        disposalDetail: status == 'processed'
            ? disposalDetail
            : item.disposalDetail,
        disposalPlatform: status == 'processed'
            ? disposalPlatform
            : item.disposalPlatform,
        disposalContact: status == 'processed'
            ? disposalContact
            : item.disposalContact,
        disposalPrice: status == 'processed'
            ? normalizedDisposalPrice
            : item.disposalPrice,
        disposalCost: status == 'processed'
            ? normalizedDisposalCost
            : item.disposalCost,
        processDate: status == 'processed'
            ? (processDate.trim().isEmpty
                  ? formatDate(now)
                  : formatDate(parseDate(processDate) ?? now))
            : item.processDate,
        recoveryMethod: status == 'processed' ? '' : item.recoveryMethod,
        recoveryTargetPrice: status == 'processed'
            ? 0
            : item.recoveryTargetPrice,
        recoveryDeadline: status == 'processed' ? '' : item.recoveryDeadline,
        recoveryPlatform: status == 'processed' ? '' : item.recoveryPlatform,
        recoveryContact: status == 'processed' ? '' : item.recoveryContact,
        recoveryNote: status == 'processed' ? '' : item.recoveryNote,
      );
    });
  }

  Future<void> planRecovery(
    String id, {
    required String method,
    required double targetPrice,
    required String deadline,
    String platform = '',
    String contact = '',
    String note = '',
  }) async {
    await _mutate(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index < 0) throw StateError('未找到这件物品');
      final item = _items[index];
      if (item.status != 'idle') {
        throw StateError('只有闲置物品可以制定回血计划');
      }
      final cashMethod = method == '转卖' || method == '回收';
      _items[index] = item.copyWith(
        recoveryMethod: method,
        recoveryTargetPrice: cashMethod ? math.max(0.0, targetPrice) : 0,
        recoveryDeadline: deadline.trim(),
        recoveryPlatform: cashMethod ? platform.trim() : '',
        recoveryContact: method == '转赠' ? contact.trim() : '',
        recoveryNote: note.trim(),
      );
    });
  }

  Future<void> cancelRecoveryPlan(String id) async {
    await _mutate(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index < 0) return;
      _items[index] = _items[index].copyWith(
        recoveryMethod: '',
        recoveryTargetPrice: 0,
        recoveryDeadline: '',
        recoveryPlatform: '',
        recoveryContact: '',
        recoveryNote: '',
      );
    });
  }

  Future<void> incrementUsage(String id, int delta) async {
    await _mutate(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index < 0 || _items[index].usageMode != 'manual') return;
      final item = _items[index];
      final records = List<String>.from(item.usageRecords);
      if (delta > 0) {
        final now = DateTime.now().toIso8601String();
        for (var index = 0; index < delta; index++) {
          records.add(now);
        }
      } else {
        for (var index = 0; index < -delta && records.isNotEmpty; index++) {
          records.removeLast();
        }
      }
      _items[index] = item.copyWith(
        manualUsageCount: (item.manualUsageCount + delta).clamp(0, 999999),
        usageRecords: records,
      );
    });
  }

  Future<void> addWish(WishEntry entry) async {
    await _mutate(() => _wishlist.insert(0, entry));
  }

  Future<void> updateWish(WishEntry entry) async {
    await _mutate(() {
      final index = _wishlist.indexWhere((current) => current.id == entry.id);
      if (index >= 0) _wishlist[index] = entry;
    });
  }

  Future<void> decideWish(String id, String status) async {
    await _mutate(() {
      final index = _wishlist.indexWhere((entry) => entry.id == id);
      if (index >= 0) {
        _wishlist[index] = _wishlist[index].copyWith(status: status);
      }
    });
  }

  Future<void> deleteWish(String id) async {
    await _mutate(() => _wishlist.removeWhere((entry) => entry.id == id));
  }

  Future<void> addStorageLocation(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || _storageLocations.contains(clean)) return;
    await _mutate(() => _storageLocations.add(clean));
  }

  Future<void> renameStorageLocation(String oldName, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) throw ArgumentError('收纳位置名称不能为空');
    if (clean == oldName) return;
    if (_storageLocations.contains(clean)) {
      throw ArgumentError('已存在同名收纳位置');
    }
    await _mutate(() {
      final index = _storageLocations.indexOf(oldName);
      if (index >= 0) _storageLocations[index] = clean;
      for (var itemIndex = 0; itemIndex < _items.length; itemIndex++) {
        final item = _items[itemIndex];
        if (item.storageLocation == oldName) {
          _items[itemIndex] = item.copyWith(storageLocation: clean);
        }
      }
    });
  }

  Future<void> deleteStorageLocation(String name) async {
    await _mutate(() {
      _storageLocations.removeWhere((location) => location == name);
      for (var index = 0; index < _items.length; index++) {
        final item = _items[index];
        if (item.storageLocation == name) {
          _items[index] = item.copyWith(storageLocation: '');
        }
      }
    });
  }

  Future<void> setSkin(int index) async {
    await _mutate(() => skinIndex = index);
  }

  Future<void> resetAll() async {
    await _mutate(() {
      _items.clear();
      _wishlist.clear();
      _storageLocations
        ..clear()
        ..addAll(['玄关', '客厅', '卧室', '书房', '厨房', '卫生间', '其他']);
      if (isGuest) guestStartedAt = DateTime.now();
      guestDataNotice = '本地数据已清空';
    }, allowCorruptedOverwrite: true);
    await _storage.write(_backupKey, '');
    try {
      await LocalImageStore.instance.deleteAll();
    } on Object {
      // Records are already cleared.
    }
  }
}

class _AppSnapshot {
  const _AppSnapshot({
    required this.version,
    required this.items,
    required this.wishlist,
    required this.storageLocations,
    required this.skinIndex,
    required this.authMode,
    required this.accountPhone,
    required this.accountName,
    required this.accountAvatarPath,
    required this.accountBirthday,
    required this.accountGender,
    this.sessionToken = '',
    required this.guestStartedAt,
    required this.guestAddCount,
    required this.cloudSyncPending,
    required this.cloudSyncError,
    required this.lastCloudSyncedAt,
  });

  final int version;
  final List<InventoryItem> items;
  final List<WishEntry> wishlist;
  final List<String> storageLocations;
  final int skinIndex;
  final String authMode;
  final String accountPhone;
  final String accountName;
  final String accountAvatarPath;
  final String accountBirthday;
  final String accountGender;
  final String sessionToken;
  final DateTime? guestStartedAt;
  final int guestAddCount;
  final bool cloudSyncPending;
  final String? cloudSyncError;
  final DateTime? lastCloudSyncedAt;
}
