import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/services/cloud_sync_service.dart';
import 'package:hsgx/storage/app_state_storage.dart';
import 'package:hsgx/storage/session_token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryAppStateStorage implements AppStateStorage {
  final Map<String, String> values = {};
  bool failNextWrite = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      return false;
    }
    values[key] = value;
    return true;
  }
}

class ThrowingSessionTokenStore implements SessionTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async {
    throw StateError('secure storage unavailable');
  }

  @override
  Future<void> write(String token) async {}
}

InventoryItem testItem(String id) {
  return InventoryItem(
    id: id,
    name: '测试物品 $id',
    purchasePrice: 100,
    currentValue: 80,
    purchaseDate: '2026-01-01',
    createdAt: '2026-01-01T00:00:00.000',
    statusHistory: [
      StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
    ],
  );
}

void main() {
  const storageKey = 'hsgx_flutter_state_v1';

  test('首次启动写入空的游客数据', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);

    await store.load();

    expect(store.items, isEmpty);
    expect(store.wishlist, isEmpty);
    final snapshot = jsonDecode(storage.values[storageKey]!) as Map;
    expect(snapshot['version'], 7);
    expect(snapshot.containsKey('sessionToken'), isFalse);
  });

  test('旧版无版本号数据可以无损载入并在下次保存时迁移', () async {
    final storage = MemoryAppStateStorage();
    storage.values[storageKey] = jsonEncode({
      'items': [testItem('legacy').toJson()],
      'wishlist': <Object?>[],
      'storageLocations': ['书房'],
      'skinIndex': 1,
    });
    final store = AppStore(storage: storage);

    await store.load();
    expect(store.itemById('legacy'), isNotNull);
    expect(store.skinIndex, 1);
    expect(store.guestAddsRemaining, 2);

    await store.toggleFavorite('legacy');
    final migrated = jsonDecode(storage.values[storageKey]!) as Map;
    expect(migrated['version'], 7);
    expect(store.itemById('legacy')?.favorite, isTrue);
  });

  test('旧版明文会话 Token 会迁移到安全存储并从业务快照移除', () async {
    final storage = MemoryAppStateStorage();
    final tokenStore = MemorySessionTokenStore();
    storage.values[storageKey] = jsonEncode({
      'version': 5,
      'items': <Object?>[],
      'wishlist': <Object?>[],
      'authMode': 'account',
      'accountPhone': '13800138000',
      'accountName': '测试账号',
      'sessionToken': 'legacy-token',
    });

    final store = AppStore(storage: storage, tokenStore: tokenStore);
    await store.load();

    expect(store.isAuthenticated, isTrue);
    expect(tokenStore.value, 'legacy-token');
    expect(
      (jsonDecode(storage.values[storageKey]!) as Map).containsKey(
        'sessionToken',
      ),
      isFalse,
    );
  });

  test('登录凭证读取失败时保留并锁定账号本地缓存', () async {
    final storage = MemoryAppStateStorage();
    final tokenStore = MemorySessionTokenStore();
    final store = AppStore(storage: storage, tokenStore: tokenStore);
    await store.load();
    await store.completeAccountSync(
      token: 'account-token',
      phone: '13800138000',
      name: '测试账号',
      result: CloudSyncResult(
        items: [testItem('cached-account-item')],
        wishlist: const [],
        storageLocations: const ['书房'],
        uploadedImageCount: 0,
        syncedAt: DateTime.now(),
      ),
    );

    final reopened = AppStore(
      storage: storage,
      tokenStore: ThrowingSessionTokenStore(),
    );
    await reopened.load();

    expect(reopened.itemById('cached-account-item'), isNotNull);
    expect(reopened.accountCacheLocked, isTrue);
    expect(reopened.loadError, contains('账号缓存已保护'));
    expect(reopened.guestCloudData.items, isEmpty);
    await expectLater(
      reopened.addItem(testItem('blocked-while-locked')),
      throwsA(isA<StateError>()),
    );
    expect(jsonDecode(storage.values[storageKey]!)['items'], hasLength(1));
  });

  test('当前资产排除已处理物品和外币，并明确标记外币数量', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.addItem(testItem('active-cny'));
    await store.addItem(
      testItem('processed-cny')
          .copyWith(status: 'processed', processDate: '2026-01-02'),
    );
    await store.addItem(
      testItem('active-usd').copyWith(purchaseCurrency: 'USD'),
    );

    expect(store.totalCurrentValue, 80);
    expect(store.totalPurchaseValue, 200);
    expect(store.activeItems, hasLength(2));
    expect(store.foreignCurrencyItemCount, 1);
  });

  test('云端刷新检测到本地版本变化时不会覆盖本地数据', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.addItem(testItem('local-change'));
    final revision = store.dataRevision;
    await store.addItem(testItem('second-local-change'));

    final applied = await store.applyCloudRefresh(
      CloudSyncResult(
        items: const [],
        wishlist: const [],
        storageLocations: const ['书房'],
        uploadedImageCount: 0,
        syncedAt: DateTime.now(),
      ),
      expectedRevision: revision,
    );

    expect(applied, isFalse);
    expect(store.itemById('local-change'), isNotNull);
    expect(store.itemById('second-local-change'), isNotNull);
  });

  test('账号本地修改不会等待后台云同步完成', () async {
    final storage = MemoryAppStateStorage();
    final tokenStore = MemorySessionTokenStore();
    var saveCount = 0;
    final cloudDone = Completer<void>();
    final cloud = CloudSyncService(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (request.method == 'POST' && ++saveCount == 3) {
          cloudDone.complete();
        }
        return http.Response(
          jsonEncode({'code': '00000', 'data': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final store = AppStore(
      storage: storage,
      tokenStore: tokenStore,
      cloudService: cloud,
    );
    await store.load();
    await store.completeAccountSync(
      token: 'token',
      phone: '13800138000',
      name: '测试账号',
      result: CloudSyncResult(
        items: const [],
        wishlist: const [],
        storageLocations: const ['书房'],
        uploadedImageCount: 0,
        syncedAt: DateTime.now(),
      ),
    );

    final stopwatch = Stopwatch()..start();
    await store.addItem(testItem('background-sync'));
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(100));
    expect(store.itemById('background-sync'), isNotNull);
    expect(store.cloudSyncPending, isTrue);

    await cloudDone.future;
    for (var attempt = 0; attempt < 20 && store.cloudSyncPending; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(store.cloudSyncPending, isFalse);
  });

  test('未来版本数据不会被旧版应用覆盖', () async {
    final storage = MemoryAppStateStorage();
    storage.values[storageKey] = jsonEncode({
      'version': 999,
      'items': <Object?>[],
      'wishlist': <Object?>[],
    });
    final store = AppStore(storage: storage);

    await store.load();

    expect(store.loadError, contains('更高版本'));
    await expectLater(
      store.addItem(testItem('future-blocked')),
      throwsA(isA<StateError>()),
    );
    expect(jsonDecode(storage.values[storageKey]!)['version'], 999);
  });

  test('主数据损坏时从上一份备份恢复并禁止静默清空', () async {
    final storage = MemoryAppStateStorage();
    final firstStore = AppStore(storage: storage);
    await firstStore.load();
    await firstStore.addItem(testItem('first'));
    await firstStore.addItem(testItem('second'));
    storage.values[storageKey] = '{broken json';

    final restoredStore = AppStore(storage: storage);
    await restoredStore.load();

    expect(restoredStore.items, isNotEmpty);
    expect(restoredStore.itemById('first'), isNotNull);
    expect(restoredStore.loadError, contains('备份恢复'));
    expect(storage.values[storageKey], isNot('{broken json'));
  });

  test('存储写入失败时回滚内存修改并给出提示', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    final before = store.items.length;
    storage.failNextWrite = true;

    await expectLater(
      store.addItem(testItem('failed')),
      throwsA(isA<StateError>()),
    );

    expect(store.items.length, before);
    expect(store.itemById('failed'), isNull);
    expect(store.persistenceWarning, contains('保存失败'));
  });

  test('没有可用备份时阻止覆盖损坏的原始文件', () async {
    final storage = MemoryAppStateStorage();
    storage.values[storageKey] = '{broken json';
    final store = AppStore(storage: storage);

    await store.load();

    expect(store.loadError, contains('没有可用备份'));
    await expectLater(
      store.addItem(testItem('blocked')),
      throwsA(isA<StateError>()),
    );
    expect(storage.values[storageKey], '{broken json');
    expect(
      storage.values.keys.where(
        (key) => key.startsWith('${storageKey}_corrupt_'),
      ),
      isNotEmpty,
    );
  });

  test('连续修改按顺序持久化，不会互相覆盖', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();

    await Future.wait([
      store.addItem(testItem('concurrent-a')),
      store.addItem(testItem('concurrent-b')),
    ]);

    expect(store.itemById('concurrent-a'), isNotNull);
    expect(store.itemById('concurrent-b'), isNotNull);
    final reloaded = AppStore(storage: storage);
    await reloaded.load();
    expect(reloaded.itemById('concurrent-a'), isNotNull);
    expect(reloaded.itemById('concurrent-b'), isNotNull);
  });

  test('手动使用记录同时更新次数和时间', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    final item = testItem('manual-usage').copyWith(usageMode: 'manual');
    await store.addItem(item);

    await store.incrementUsage(item.id, 1);
    await store.incrementUsage(item.id, 1);

    final updated = store.itemById(item.id)!;
    expect(updated.manualUsageCount, 2);
    expect(updated.usageRecords, hasLength(2));
    expect(updated.lastUsedAt, isNotNull);
  });

  test('重命名或删除收纳位置会同步更新关联物品', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    final item = testItem('location').copyWith(storageLocation: '书房');
    await store.addItem(item);

    await store.renameStorageLocation('书房', '阅读角');
    expect(store.itemById(item.id)?.storageLocation, '阅读角');
    expect(store.storageLocations, contains('阅读角'));

    await store.deleteStorageLocation('阅读角');
    expect(store.itemById(item.id)?.storageLocation, '');
    expect(store.storageLocations, isNot(contains('阅读角')));
  });

  test('物品关联双向保存，删除物品时自动清理关联', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.addItem(testItem('camera'));
    await store.addItem(testItem('lens'));

    await store.setRelatedItems('camera', ['lens']);

    expect(store.itemById('camera')?.relatedItemIds, contains('lens'));
    expect(store.itemById('lens')?.relatedItemIds, contains('camera'));

    await store.deleteItem('lens');
    expect(store.itemById('camera')?.relatedItemIds, isEmpty);
  });

  test('维修和闲置状态会保存完整生命周期字段', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.addItem(testItem('repair'));

    await store.changeStatus(
      'repair',
      'repairing',
      repairPlatform: '品牌官方',
      repairDays: 7,
      repairContactName: '维修员',
      repairContactPhone: '13800138000',
    );

    final repaired = store.itemById('repair')!;
    expect(repaired.repairPlatform, '品牌官方');
    expect(repaired.repairDays, 7);
    expect(repaired.repairContactName, '维修员');
    expect(repaired.statusHistory.last.note, contains('预计 7 天'));

    await store.changeStatus('repair', 'idle', idleReason: '暂时收纳');
    expect(store.itemById('repair')?.idleReason, '暂时收纳');
  });

  test('游客数据超过三天后自动清理并开启新的三天周期', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    await store.addItem(testItem('expired-guest'));
    final snapshot = jsonDecode(storage.values[storageKey]!) as Map;
    snapshot['guestStartedAt'] = DateTime.now()
        .subtract(const Duration(days: 4))
        .toIso8601String();
    storage.values[storageKey] = jsonEncode(snapshot);

    final reopened = AppStore(storage: storage);
    await reopened.load();

    expect(reopened.isGuest, isTrue);
    expect(reopened.items, isEmpty);
    expect(reopened.guestDaysRemaining, 3);
    expect(reopened.consumeGuestDataNotice(), contains('已自动清理'));
    expect(storage.values['${storageKey}_backup'], isEmpty);
  });

  test('游客每个会话最多成功添加三次，删除或清空不会返还次数', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();

    await store.addItem(testItem('guest-1'));
    await store.addItem(testItem('guest-2'));
    await store.addItem(testItem('guest-3'));

    expect(store.guestAddsRemaining, 0);
    expect(store.canAddGuestItem, isFalse);
    await expectLater(
      store.addItem(testItem('guest-4')),
      throwsA(isA<StateError>()),
    );

    await store.deleteItem('guest-1');
    expect(store.guestAddsRemaining, 0);

    await store.resetAll();
    expect(store.guestAddsRemaining, 0);
    await expectLater(
      store.addItem(testItem('guest-after-reset')),
      throwsA(isA<StateError>()),
    );

    final reopened = AppStore(storage: storage);
    await reopened.load();
    expect(reopened.guestAddsRemaining, 0);
  });

  test('游客同步成功后切换账号并清除游客备份', () async {
    final storage = MemoryAppStateStorage();
    final tokenStore = MemorySessionTokenStore();
    final store = AppStore(storage: storage, tokenStore: tokenStore);
    await store.load();
    final item = testItem('guest-sync');
    await store.addItem(item);
    final result = CloudSyncResult(
      items: [item],
      wishlist: const [],
      storageLocations: const ['书房'],
      uploadedImageCount: 0,
      syncedAt: DateTime.now(),
    );
    await store.completeAccountSync(
      token: 'token',
      phone: '13800138000',
      name: '测试账号',
      result: result,
    );

    expect(store.isGuest, isFalse);
    expect(store.accountPhone, '13800138000');
    expect(store.accountName, '测试账号');
    expect(store.sessionToken, 'token');
    expect(store.guestStartedAt, isNull);
    expect(storage.values['${storageKey}_backup'], isEmpty);
    expect(tokenStore.value, 'token');
    expect(
      (jsonDecode(storage.values[storageKey]!) as Map).containsKey(
        'sessionToken',
      ),
      isFalse,
    );

    final reopened = AppStore(storage: storage, tokenStore: tokenStore);
    await reopened.load();
    expect(reopened.isAuthenticated, isTrue);
    expect(reopened.itemById('guest-sync'), isNotNull);
  });

  test('登录失效回调会清除安全 Token 并切回游客模式', () async {
    final storage = MemoryAppStateStorage();
    final tokenStore = MemorySessionTokenStore();
    final store = AppStore(storage: storage, tokenStore: tokenStore);
    await store.load();
    final item = testItem('auth-expired');
    await store.completeAccountSync(
      token: 'expired-token',
      phone: '13800138000',
      name: '测试账号',
      result: CloudSyncResult(
        items: [item],
        wishlist: const [],
        storageLocations: const ['书房'],
        uploadedImageCount: 0,
        syncedAt: DateTime.now(),
      ),
    );

    store.handleUnauthorized();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(store.isGuest, isTrue);
    expect(tokenStore.value, isNull);
    expect(store.consumeGlobalNotice(), contains('登录状态已失效'));
  });

  test('转赠和丢弃不会计入现金回血金额', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    final sold = testItem('sold');
    final gifted = testItem('gifted');
    await store.addItem(sold);
    await store.addItem(gifted);

    await store.changeStatus(
      sold.id,
      'processed',
      disposalMethod: '转卖',
      disposalPlatform: '闲鱼',
      disposalPrice: 500,
    );
    await store.changeStatus(
      gifted.id,
      'processed',
      disposalMethod: '转赠',
      disposalContact: '朋友',
      disposalPrice: 999,
    );

    expect(store.itemById('gifted')?.disposalPrice, 0);
    expect(store.itemById('gifted')?.disposalCost, 0);
    expect(store.itemById('gifted')?.cashRecoveredAmount, 0);
    expect(store.recoveredAmount, 500);
  });

  test('闲置物品可以制定计划并按净回血完成处理', () async {
    final storage = MemoryAppStateStorage();
    final store = AppStore(storage: storage);
    await store.load();
    final item = testItem('planned').copyWith(status: 'idle');
    await store.addItem(item);

    await store.planRecovery(
      item.id,
      method: '转卖',
      targetPrice: 600,
      deadline: '2026-12-01',
      platform: '闲鱼',
      note: '先清洁',
    );
    final planned = store.itemById(item.id)!;
    expect(planned.hasRecoveryPlan, isTrue);
    expect(planned.recoveryTargetPrice, 600);
    expect(planned.recoveryDeadline, '2026-12-01');

    await store.changeStatus(
      item.id,
      'processed',
      disposalMethod: '转卖',
      disposalPlatform: '闲鱼',
      disposalPrice: 560,
      disposalCost: 60,
    );
    final processed = store.itemById(item.id)!;
    expect(processed.hasRecoveryPlan, isFalse);
    expect(processed.cashRecoveredAmount, 500);
    expect(store.recoveredAmount, 500);
  });
}
