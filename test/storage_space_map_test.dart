import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/components/storage/storage_item_card.dart';
import 'package:hsgx/components/storage/storage_space_card.dart';
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
  String status = 'inuse',
}) {
  return InventoryItem(
    id: id,
    name: name,
    status: status,
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
    expect(find.text('旧手表'), findsNothing);
    expect(find.byKey(const Key('storage-space-书房')), findsOneWidget);
    expect(find.text('¥1,280'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('storage-space-书房')));
    await tester.pumpAndSettle();

    expect(find.text('这里的物品'), findsNothing);
    expect(find.text('旅行相机'), findsOneWidget);
    expect(find.text('空间清单'), findsNothing);
    expect(find.text('点击物品设置归处'), findsNothing);
    expect(find.byIcon(Icons.drive_file_move_outline), findsNothing);

    await tester.tap(find.text('旅行相机'));
    await tester.pumpAndSettle();

    expect(find.text('更改「旅行相机」的位置'), findsOneWidget);
    expect(find.text('一物一页'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('归处页不显示搜索框和位置数量', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _storeWithItems();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageScreen(store: store),
      ),
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('搜索物品、位置、分类或标签'), findsNothing);
    expect(find.text('匣中归处'), findsOneWidget);
    expect(find.text('7 处归处'), findsNothing);
    expect(find.byKey(const Key('storage-space-卧室')), findsOneWidget);
    expect(find.byKey(const Key('storage-space-书房')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('归处网格只构建当前可见的空间卡片', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemoryStorage();
    storage.values['hsgx_flutter_state_v1'] = jsonEncode({
      'version': 10,
      'items': [
        for (var index = 0; index < 80; index++)
          _item(
            id: 'stored-$index',
            name: '物品 $index',
            location: '空间 $index',
          ).toJson(),
      ],
      'wishlist': <Object?>[],
      'storageLocations': <String>[],
    });
    final store = AppStore(storage: storage);
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.byType(StorageSpaceCard), findsWidgets);
    expect(
      find.byType(StorageSpaceCard, skipOffstage: false).evaluate().length,
      lessThan(80),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('未设置位置页改为设置归处并支持点击设置和长按禁用', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _storeWithItems();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageLocationScreen(location: '未设置位置', store: store),
      ),
    );
    await tester.pump();

    expect(find.text('设置归处'), findsOneWidget);
    expect(find.text('未设置位置'), findsNothing);
    expect(find.text('旧手表'), findsOneWidget);
    expect(find.text('点击物品设置归处'), findsNothing);
    expect(find.byIcon(Icons.drive_file_move_outline), findsNothing);

    final itemInkWell = tester.widget<InkWell>(
      find
          .descendant(
            of: find.byType(StorageItemCard),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(itemInkWell.onLongPress, isNull);

    await tester.tap(find.text('旧手表'));
    await tester.pumpAndSettle();
    expect(find.text('更改「旧手表」的位置'), findsOneWidget);
    expect(find.text('一物一页'), findsNothing);

    await tester.tap(find.text('客厅'));
    await tester.pumpAndSettle();
    expect(store.itemById('watch')?.storageLocation, '客厅');
    expect(tester.takeException(), isNull);
  });

  testWidgets('归处物品卡不显示维修、已处理和已退役状态', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    for (final status in ['repairing', 'processed', 'retired']) {
      await store.addItem(
        _item(id: status, name: '物品-$status', location: '客厅', status: status),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageLocationScreen(location: '客厅', store: store),
      ),
    );
    await tester.pump();

    expect(find.text('维修中'), findsNothing);
    expect(find.text('已处理'), findsNothing);
    expect(find.text('已退役'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('添归处使用带图标库的底部弹窗并保存所选图标', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore(storage: _MemoryStorage());
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageScreen(store: store),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('add-location-button')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('添一处归处'), findsOneWidget);
    expect(find.byKey(const Key('storage-location-icon-book')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('storage-location-name-field')),
      '健身角',
    );
    await tester.tap(find.byKey(const Key('storage-location-icon-garage')));
    final submit = find.byKey(const Key('storage-location-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(store.storageLocations, contains('健身角'));
    expect(store.storageLocationIconKey('健身角'), 'garage');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StorageSpaceCard(
              location: '健身角',
              iconKey: store.storageLocationIconKey('健身角'),
              items: const [],
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('重命名归处使用底部弹窗且删除按钮没有图标', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _storeWithItems();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageLocationScreen(location: '书房', store: store),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    final page = find.byKey(const Key('storage-location-footer'));
    final deleteButton = find.byKey(const Key('delete-location-button'));
    expect(page, findsOneWidget);
    expect(deleteButton, findsOneWidget);
    expect(tester.widget(deleteButton), isA<OutlinedButton>());
    expect(
      tester.getSize(deleteButton).width,
      closeTo(tester.getSize(page).width, 0.1),
    );
    expect(
      tester.getBottomLeft(page).dy - tester.getBottomLeft(deleteButton).dy,
      closeTo(12, 0.1),
    );
    final deleteStyle = tester.widget<OutlinedButton>(deleteButton).style;
    expect(
      deleteStyle?.side?.resolve({}),
      isA<BorderSide>().having((side) => side.width, 'width', greaterThan(0)),
    );
    expect(
      find.descendant(of: deleteButton, matching: find.byType(Icon)),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('rename-location-button')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('重命名归处'), findsWidgets);
    expect(find.text('图标'), findsOneWidget);
    expect(find.text('选择图标'), findsNothing);
    expect(find.byKey(const Key('storage-location-icon-bed')), findsOneWidget);
    expect(
      find.byKey(const Key('storage-location-icon-luggage')),
      findsOneWidget,
    );
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('storage-location-name-field')),
    );
    expect(nameField.autofocus, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const Key('storage-location-icon-bed')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('storage-location-name-field')),
      '阅读角',
    );
    await tester.tap(find.byKey(const Key('storage-location-icon-bed')));
    final submit = find.byKey(const Key('storage-location-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(store.storageLocations, contains('阅读角'));
    expect(store.storageLocations, isNot(contains('书房')));
    expect(store.storageLocationIconKey('阅读角'), 'bed');
    expect(store.itemById('camera')?.storageLocation, '阅读角');
    expect(tester.takeException(), isNull);
  });

  testWidgets('归处详情页最小高度排除顶部刘海安全区', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _storeWithItems();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: const Size(390, 844),
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: child!,
        ),
        home: StorageLocationScreen(location: '书房', store: store),
      ),
    );
    await tester.pump();

    final safeArea = find.byType(SafeArea).first;
    final safeContent = find
        .descendant(of: safeArea, matching: find.byType(Column))
        .first;
    expect(tester.getSize(safeContent).height, closeTo(800, 0.1));
    expect(
      tester.getBottomLeft(find.byKey(const Key('delete-location-button'))).dy,
      lessThanOrEqualTo(810.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('归处物品卡的长名称使用省略号且不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longName = '陪伴很多年仍然非常喜欢的限量版复古机械键盘';
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(_item(id: 'long', name: longName, location: '书房'));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StorageLocationScreen(location: '书房', store: store),
      ),
    );
    await tester.pump();

    final name = tester.widget<Text>(find.text(longName));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
