import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/components/item_tag_chip.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/item_form_screen.dart';
import 'package:hsgx/widgets.dart';

void main() {
  test('物品金额与日均成本按数量计算', () {
    final item = InventoryItem(
      id: 'test',
      name: '测试物品',
      purchasePrice: 1000,
      currentValue: 600,
      purchaseDate: formatDate(
        DateTime.now().subtract(const Duration(days: 9)),
      ),
      createdAt: DateTime.now().toIso8601String(),
      quantity: 2,
    );

    expect(item.purchaseTotal, 2000);
    expect(item.currentTotal, 1200);
    expect(item.ownedDays, 10);
    expect(item.ownedDailyCost, 200);
  });

  test('物品序列化后保留标签与状态历史', () {
    final item = InventoryItem(
      id: 'round-trip',
      name: '耳机',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      tags: const ['通勤', '常用'],
      statusHistory: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
      ],
      favorite: true,
      favoriteAt: '2026-02-03T10:20:00.000',
    );

    final restored = InventoryItem.fromJson(item.toJson());
    expect(restored.name, '耳机');
    expect(restored.tags, ['通勤', '常用']);
    expect(restored.statusHistory.single.status, 'inuse');
    expect(restored.favoriteAt, '2026-02-03T10:20:00.000');
  });

  test('心愿序列化后保留购买动机并兼容旧数据', () {
    final wish = WishEntry(
      id: 'wish',
      name: '相机',
      createdAt: '2026-01-01T00:00:00.000',
      desireType: 'long-term',
      status: 'achieved',
      achievedAt: '2026-02-03T14:25:00.000',
    );
    final restored = WishEntry.fromJson(wish.toJson());
    final legacy = WishEntry.fromJson({
      'id': 'legacy',
      'name': '旧心愿',
      'createdAt': '2026-01-01T00:00:00.000',
    });

    expect(restored.desireType, 'long-term');
    expect(restored.achievedAt, '2026-02-03T14:25:00.000');
    expect(legacy.desireType, isEmpty);
    expect(legacy.achievedAt, isEmpty);
  });

  test('物品序列化后保留多图、币种、关联和完整生命周期信息', () {
    final item = InventoryItem(
      id: 'full-round-trip',
      name: '相机组合',
      purchaseCurrency: 'USD',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      imagePaths: const ['/a.jpg', '/b.jpg'],
      relatedItemIds: const ['lens'],
      idleReason: '暂时收纳',
      repairPlatform: '品牌官方',
      repairDays: 7,
      repairContactName: '维修员',
      repairContactPhone: '13800138000',
      disposalMethod: '转卖',
      disposalPlatform: '闲鱼',
      disposalContact: '买家',
      disposalPrice: 500,
      disposalCost: 50,
      processDate: '2026-10-01',
    );

    final restored = InventoryItem.fromJson(item.toJson());
    expect(restored.purchaseCurrency, 'USD');
    expect(restored.currencySymbol, '\$');
    expect(restored.imagePaths, ['/a.jpg', '/b.jpg']);
    expect(restored.relatedItemIds, ['lens']);
    expect(restored.repairPlatform, '品牌官方');
    expect(restored.repairDays, 7);
    expect(restored.disposalPlatform, '闲鱼');
    expect(restored.disposalContact, '买家');
    expect(restored.disposalCost, 50);
    expect(restored.cashRecoveredAmount, 450);
    expect(restored.processDate, '2026-10-01');
  });

  test('闲置回血计划字段可以完整序列化', () {
    final item = InventoryItem(
      id: 'recovery-plan',
      name: '旧相机',
      status: 'idle',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      recoveryMethod: '转卖',
      recoveryTargetPrice: 800,
      recoveryDeadline: '2026-12-01',
      recoveryPlatform: '闲鱼',
      recoveryNote: '先清洁镜头',
    );

    final restored = InventoryItem.fromJson(item.toJson());
    expect(restored.hasRecoveryPlan, isTrue);
    expect(restored.recoveryMethod, '转卖');
    expect(restored.recoveryTargetPrice, 800);
    expect(restored.recoveryDeadline, '2026-12-01');
    expect(restored.recoveryPlatform, '闲鱼');
    expect(restored.recoveryNote, '先清洁镜头');
  });

  test('旧目标使用天数字段会迁移为带单位的通用目标值', () {
    final manual = InventoryItem.fromJson({
      'id': 'legacy-manual-target',
      'name': '旧手动物品',
      'usageMode': 'manual',
      'targetUseDays': 42,
    });
    final automatic = InventoryItem.fromJson({
      'id': 'legacy-auto-target',
      'name': '旧自动物品',
      'usageMode': 'auto',
      'targetUseDays': 365,
    });

    expect(manual.targetUsageValue, 42);
    expect(manual.targetUsageUnit, 'count');
    expect(manual.effectiveTargetValue, 42);
    expect(automatic.targetUsageValue, 365);
    expect(automatic.targetUsageUnit, 'day');
    expect(manual.toJson()['targetUsageValue'], 42);
    expect(manual.toJson()['targetUsageUnit'], 'count');
  });

  testWidgets('下拉字段从底部弹出并回传选择结果', (tester) async {
    String selected = 'digital';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: BottomSelectField<String>(
              label: '生活分类',
              value: selected,
              options: const [
                BottomSelectOption(value: 'digital', label: '数码产品'),
                BottomSelectOption(value: 'clothing', label: '服饰箱包'),
              ],
              onChanged: (value) => selected = value ?? '',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BottomSelectField<String>));
    await tester.pumpAndSettle();

    expect(find.text('生活分类'), findsWidgets);
    expect(find.text('服饰箱包'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('服饰箱包'));
    await tester.pumpAndSettle();

    expect(selected, 'clothing');
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('空状态在左对齐容器中仍占满可用宽度', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmptyState(
                  title: '心愿匣还是空的',
                  description: '把想买的东西先放进来，让时间帮你判断。',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    final emptyStateWidth = tester.getSize(find.byType(EmptyState)).width;
    expect(emptyStateWidth, screenWidth - 40);
  });

  testWidgets('日期选择器从底部弹出并只显示一组月份切换', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  picked = await showAppDatePicker(
                    context,
                    initialDate: DateTime(2026, 11, 4),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    title: '选择日期',
                  );
                },
                child: const Text('打开日期'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开日期'));
    await tester.pumpAndSettle();

    expect(find.text('选择日期'), findsOneWidget);
    expect(find.text('选择后点击下方按钮确认'), findsNothing);
    expect(find.text('取消'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.textContaining('2026年'), findsWidgets);
    expect(find.byTooltip('上个月'), findsOneWidget);
    final pickerTop = tester.getTopLeft(find.byType(CalendarDatePicker)).dy;
    expect(
      pickerTop,
      greaterThan(tester.getSize(find.byType(Scaffold)).height / 3),
    );

    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 11, 10));
  });

  testWidgets('物品数量使用加减步进器且最小值为1', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItemFormScreen()));
    await tester.pump();

    String quantity() =>
        tester.widget<Text>(find.byKey(const Key('quantity-value'))).data!;
    expect(quantity(), '1');

    await tester.ensureVisible(find.byKey(const Key('quantity-minus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quantity-minus')));
    await tester.pump();
    expect(quantity(), '1');

    await tester.ensureVisible(find.byKey(const Key('quantity-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quantity-plus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quantity-plus')));
    await tester.pump();
    expect(quantity(), '3');

    await tester.tap(find.byKey(const Key('quantity-minus')));
    await tester.pump();
    expect(quantity(), '2');
  });

  testWidgets('手动计次使用目标使用次数，购入价为必填项', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItemFormScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('手动记次数'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手动记次数'));
    await tester.pumpAndSettle();

    expect(find.text('目标使用次数（选填）'), findsOneWidget);
    expect(find.text('目标使用天数（选填）'), findsNothing);

    await tester.ensureVisible(find.text('放入匣中'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('放入匣中'));
    await tester.pumpAndSettle();

    expect(find.text('请输入购入价'), findsOneWidget);
  });

  testWidgets('物品编辑页不再绕过状态处理流程', (tester) async {
    final item = InventoryItem(
      id: 'idle-item',
      name: '闲置物品',
      purchasePrice: 100,
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      status: 'idle',
      idleReason: '暂时不用',
      statusHistory: [
        StatusEvent(status: 'idle', at: '2026-01-01T00:00:00.000'),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: ItemFormScreen(initial: item)));
    await tester.pump();

    expect(find.text('状态与处理信息请在一物一页中更改'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '已处理'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, '维修中'), findsNothing);
  });

  testWidgets('新建物品只展示使用方式和默认使用中提示', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItemFormScreen()));
    await tester.pump();

    expect(find.text('使用方式'), findsOneWidget);
    expect(find.text('状态与使用'), findsNothing);
    expect(find.text('当前状态'), findsNothing);
    expect(find.text('新物品将记录为使用中，保存后可在一物一页更改状态。'), findsOneWidget);
  });

  testWidgets('购入价验证错误时同行字段顶部保持对齐', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ItemFormScreen()));
    await tester.pump();

    final save = find.text('放入匣中');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('请输入购入价'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('purchase-price-field'))).dy,
      closeTo(
        tester.getTopLeft(find.byKey(const Key('current-value-field'))).dy,
        0.01,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('拾一件使用与一物一页一致的彩色标签样式', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItemFormScreen()));
    await tester.pump();

    final tagField = find.widgetWithText(TextField, '添加标签');
    await tester.enterText(tagField, '通勤');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.byType(ItemTagChip), findsOneWidget);
    expect(find.text('通勤'), findsOneWidget);

    final deleteTag = find.byTooltip('删除标签');
    await tester.ensureVisible(deleteTag);
    await tester.pumpAndSettle();
    await tester.tap(deleteTag);
    await tester.pump();
    expect(find.byType(ItemTagChip), findsNothing);
  });
}
