import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/services/cloud_sync_service.dart';
import 'package:hsgx/storage/app_state_storage.dart';

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
    expect(snapshot['version'], 5);
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
    expect(migrated['version'], 5);
    expect(store.itemById('legacy')?.favorite, isTrue);
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
    final store = AppStore(storage: storage);
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

    final reopened = AppStore(storage: storage);
    await reopened.load();
    expect(reopened.isAuthenticated, isTrue);
    expect(reopened.itemById('guest-sync'), isNotNull);
  });
}
