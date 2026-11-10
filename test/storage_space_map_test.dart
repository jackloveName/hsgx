import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/storage_screen.dart';
import 'package:hsgx/storage/app_state_storage.dart';
import 'package:hsgx/theme.dart';

class _MemoryStorage implements AppStateStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> write(String key, String value) async {
    values[key] = value;
    return true;
  }
}

InventoryItem _item({
  required String id,
  required String name,
  required String location,
  double value = 0,
}) {
  return InventoryItem(
    id: id,
    name: name,
    currentValue: value,
    purchaseDate: '2026-01-01',
    createdAt: '2026-01-01T00:00:00.000',
    storageLocation: location,
    statusHistory: [
      StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
    ],
  );
}

Future<AppStore> _storeWithItems() async {
  final store = AppStore(storage: _MemoryStorage());
  await store.load();
  await store.addItem(
    _item(id: 'camera', name: '旅行相机', location: ' 书房 ', value: 1280),
  );
  await store.addItem(_item(id: 'watch', name: '旧手表', location: ''));
  return store;
}

void main() {
  testWidgets('空间地图展示总览、待安放收件箱并可进入空间详情', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _storeWithItems();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('storage-overview')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('storage-placed-count')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('storage-unassigned-count')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('storage-unassigned-inbox')), findsOneWidget);
    expect(find.text('1 件物品暂未归处'), findsOneWidget);
    expect(find.byKey(const Key('storage-space-书房')), findsOneWidget);
    expect(find.text('¥1,280'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('storage-space-书房')));
    await tester.pumpAndSettle();

    expect(find.text('这里的物品'), findsNothing);
    expect(find.text('旅行相机'), findsOneWidget);
    expect(find.text('1 件物品'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索匹配空空间名称时仍展示对应空间卡片', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _storeWithItems();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageScreen(store: store),
      ),
    );
    await tester.enterText(find.byType(TextField), '卧室');
    await tester.pump();

    expect(find.byKey(const Key('storage-space-卧室')), findsOneWidget);
    expect(find.text('没有找到对应物品'), findsNothing);
    expect(find.byKey(const Key('storage-space-书房')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
