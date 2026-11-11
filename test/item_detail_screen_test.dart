import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/item_detail_screen.dart';
import 'package:hsgx/storage/app_state_storage.dart';
import 'package:hsgx/theme.dart';
import 'package:hsgx/widgets.dart';

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

void main() {
  testWidgets('物品详情按数量展示总购入价和总估值', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'quantity-item',
        name: '成对座椅',
        purchasePrice: 100,
        currentValue: 80,
        quantity: 2,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        statusHistory: [
          StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'quantity-item', store: store),
      ),
    );
    await tester.pump();

    expect(find.text('购入总价'), findsOneWidget);
    expect(find.text('¥200'), findsOneWidget);
    expect(find.text('当前总估值'), findsOneWidget);
    expect(find.text('¥160'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(FilledButton, '更改状态'),
        matching: find.byIcon(Icons.swap_horiz_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(FilledButton, '编辑'),
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('delete-item-button')),
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
      findsNothing,
    );
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('删除这件物品'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('生命轨迹节点对齐并分行展示收入与维修信息', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'timeline-item',
        name: '等待维修的相机',
        purchasePrice: 1000,
        currentValue: 800,
        purchaseDate: '2026-11-11',
        createdAt: '2026-11-11T10:00:00.000',
        status: 'repairing',
        repairPlatform: '品牌官方',
        repairDays: 3,
        repairContactName: '维修联系人',
        repairContactPhone: '13800138000',
        statusHistory: [
          StatusEvent(
            status: 'inuse',
            at: '2026-11-11T10:00:00.000',
            note: '物品初始状态',
          ),
          StatusEvent(
            status: 'repairing',
            at: '2026-11-12T10:00:00.000',
            note: '品牌官方 · 预计 3 天',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'timeline-item', store: store),
      ),
    );
    await tester.pump();

    expect(find.text('2026年11月11号收入匣中'), findsOneWidget);
    expect(find.text('维修平台：品牌官方'), findsOneWidget);
    expect(find.text('预计维修时间：3天'), findsOneWidget);
    expect(find.text('维修联系人：维修联系人'), findsOneWidget);
    expect(find.text('联系电话：13800138000'), findsOneWidget);
    expect(find.text('品牌官方 · 预计 3 天'), findsNothing);
    expect(
      tester.getCenter(find.byKey(const Key('timeline-node-0'))).dy,
      closeTo(
        tester.getCenter(find.byKey(const Key('timeline-status-0'))).dy,
        0.01,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('记录处理结果不再要求填写运费和手续费成本', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'processed-item',
        name: '准备处理的物品',
        purchasePrice: 100,
        currentValue: 80,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        statusHistory: [
          StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'processed-item', store: store),
      ),
    );
    await tester.pump();

    final changeStatus = find.text('更改状态');
    await tester.ensureVisible(changeStatus);
    await tester.pumpAndSettle();
    await tester.tap(changeStatus);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '已处理'));
    await tester.pumpAndSettle();

    expect(find.text('记录处理结果'), findsOneWidget);
    expect(find.text('运费、手续费等成本'), findsNothing);
    expect(find.text('购入价格'), findsOneWidget);
    expect(find.text('¥100'), findsWidgets);
    expect(find.widgetWithText(TextField, '购入价格'), findsNothing);
    expect(find.text('处理日期(购买日-至今)'), findsOneWidget);
    expect(find.textContaining('可选范围：'), findsNothing);

    final confirmUpdate = find.text('确认更新');
    await tester.ensureVisible(confirmUpdate);
    await tester.tap(confirmUpdate);
    await tester.pump();
    expect(find.text('请选择转卖平台'), findsOneWidget);

    final platformField = find.byKey(const Key('processing-platform-field'));
    await tester.ensureVisible(platformField);
    await tester.pumpAndSettle();
    await tester.tap(platformField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('闲鱼').last);
    await tester.pumpAndSettle();
    await tester.tap(confirmUpdate);
    await tester.pump();
    expect(find.text('请输入实际回血金额'), findsOneWidget);

    final datePicker = find.byKey(const Key('process-date-picker'));
    await tester.ensureVisible(datePicker);
    await tester.pumpAndSettle();
    await tester.tap(datePicker);
    await tester.pumpAndSettle();
    expect(find.text('选择处理日期'), findsOneWidget);
    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendar.firstDate, DateTime(2026, 1, 1));
    expect(calendar.lastDate, DateUtils.dateOnly(DateTime.now()));
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('确定处理日期'));
    await tester.pumpAndSettle();
    final selectedDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      10,
    );
    expect(find.text(formatDate(selectedDate)), findsOneWidget);

    final methodField = find.byKey(const Key('processing-method-field'));
    await tester.ensureVisible(methodField);
    await tester.pumpAndSettle();
    await tester.tap(methodField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('回收').last);
    await tester.pumpAndSettle();
    expect(find.text('回收平台'), findsOneWidget);
    expect(find.text('实际回血金额'), findsOneWidget);
    expect(find.text('运费、手续费等成本'), findsNothing);
  });

  testWidgets('物品退役需要二次确认且退役后只能删除', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'retiring-item',
        name: '准备退役的物品',
        purchasePrice: 100,
        currentValue: 80,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        statusHistory: [
          StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'retiring-item', store: store),
      ),
    );
    await tester.pump();

    final changeStatus = find.text('更改状态');
    await tester.ensureVisible(changeStatus);
    await tester.pumpAndSettle();
    await tester.tap(changeStatus);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '已退役'));
    await tester.pumpAndSettle();

    final confirmUpdate = find.text('确认更新');
    await tester.ensureVisible(confirmUpdate);
    await tester.tap(confirmUpdate);
    await tester.pumpAndSettle();
    expect(find.text('确认退役？'), findsOneWidget);
    await tester.tap(find.text('确认退役'));
    await tester.pumpAndSettle();

    expect(store.itemById('retiring-item')?.status, 'retired');
    expect(find.text('更改状态'), findsNothing);
    expect(find.text('编辑'), findsNothing);
    expect(find.byKey(const Key('delete-item-button')), findsOneWidget);
    await expectLater(
      store.changeStatus('retiring-item', 'inuse'),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('相伴之物每件一行并显示状态名称与日均次均', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    for (final (id, name, usage) in [
      ('main', '组合主物品', 1),
      ('camera', '旅行相机', 4),
      ('lens', '备用镜头', 2),
    ]) {
      await store.addItem(
        InventoryItem(
          id: id,
          name: name,
          purchasePrice: 100,
          purchaseDate: '2026-01-01',
          createdAt: '2026-01-01T00:00:00.000',
          usageMode: 'manual',
          manualUsageCount: usage,
          statusHistory: [
            StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
          ],
        ),
      );
    }
    await store.setRelatedItems('main', ['camera', 'lens']);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'main', store: store),
      ),
    );
    await tester.pump();

    final camera = find.byKey(const Key('detail-related-camera'));
    final lens = find.byKey(const Key('detail-related-lens'));
    expect(camera, findsOneWidget);
    expect(lens, findsOneWidget);
    expect(
      tester.getTopLeft(camera).dy,
      isNot(equals(tester.getTopLeft(lens).dy)),
    );
    expect(
      tester
          .getCenter(
            find.descendant(of: camera, matching: find.byType(StatusPill)),
          )
          .dx,
      lessThan(
        tester
            .getCenter(find.descendant(of: camera, matching: find.text('旅行相机')))
            .dx,
      ),
    );
    expect(
      find.descendant(of: camera, matching: find.text('¥25/次')),
      findsOneWidget,
    );
  });

  testWidgets('已处理物品隐藏操作且维修弹窗默认选中当前状态', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'processed-hidden',
        name: '已经处理的物品',
        purchasePrice: 100,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        status: 'processed',
        disposalMethod: '转卖',
        disposalPlatform: '闲鱼',
        disposalPrice: 80,
        processDate: '2026-11-10',
        statusHistory: [
          StatusEvent(status: 'processed', at: '2026-11-10T00:00:00.000'),
        ],
      ),
    );
    await store.addItem(
      InventoryItem(
        id: 'repairing-current',
        name: '正在维修的物品',
        purchasePrice: 100,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        status: 'repairing',
        repairPlatform: '品牌官方',
        repairDays: 3,
        statusHistory: [
          StatusEvent(status: 'repairing', at: '2026-11-01T00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'processed-hidden', store: store),
      ),
    );
    await tester.pump();
    expect(find.text('更改状态'), findsNothing);
    expect(find.text('编辑'), findsNothing);
    expect(find.byKey(const Key('delete-item-button')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemDetailScreen(itemId: 'repairing-current', store: store),
      ),
    );
    await tester.pump();
    final changeStatus = find.text('更改状态');
    await tester.ensureVisible(changeStatus);
    await tester.pumpAndSettle();
    await tester.tap(changeStatus);
    await tester.pumpAndSettle();

    final repairingChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '维修中'),
    );
    expect(repairingChip.selected, isTrue);
  });
}
