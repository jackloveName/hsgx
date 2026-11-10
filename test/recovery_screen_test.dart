import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/recovery_screen.dart';
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

void main() {
  testWidgets('待决定物品按名称、价格区间和右侧按钮横向排列', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'idle-chair',
        name: '旧办公椅',
        purchasePrice: 300,
        currentValue: 100,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        status: 'idle',
        statusHistory: [
          StatusEvent(status: 'idle', at: '2026-11-01T00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RecoveryScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('参考回血区间'), findsNothing);
    expect(find.text('旧办公椅'), findsOneWidget);
    expect(find.text('购入价 ¥300 · 参考回血 ¥60–¥80'), findsOneWidget);

    final nameLeft = tester.getTopLeft(find.text('旧办公椅')).dx;
    final detailLeft = tester
        .getTopLeft(find.text('购入价 ¥300 · 参考回血 ¥60–¥80'))
        .dx;
    final button = find.byKey(const Key('recovery-plan-idle-chair'));
    expect(nameLeft, closeTo(detailLeft, 0.01));
    expect(
      tester.getCenter(button).dx,
      greaterThan(tester.getCenter(find.text('旧办公椅')).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('创建回血计划后物品从待决定进入计划处理', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'idle-lamp',
        name: '旧台灯',
        purchasePrice: 300,
        currentValue: 100,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        status: 'idle',
        statusHistory: [
          StatusEvent(status: 'idle', at: '2026-11-01T00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RecoveryScreen(store: store),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('recovery-plan-idle-lamp')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '计划平台'), '闲鱼');
    await tester.tap(find.text('创建计划'));
    await tester.pumpAndSettle();

    final planned = store.itemById('idle-lamp')!;
    expect(planned.hasRecoveryPlan, isTrue);
    expect(planned.recoveryMethod, '转卖');
    expect(planned.recoveryTargetPrice, 70);
    expect(planned.recoveryPlatform, '闲鱼');
    expect(find.text('计划处理'), findsOneWidget);
    final methodBadge = find.byKey(const Key('recovery-method-idle-lamp'));
    expect(methodBadge, findsOneWidget);
    expect(find.text('转卖'), findsOneWidget);
    expect(find.text('购入价 ¥300'), findsOneWidget);
    expect(find.text('目标 ¥70'), findsOneWidget);
    expect(find.textContaining('计划完成'), findsNothing);
    expect(find.text('调整'), findsNothing);
    expect(find.text('取消计划'), findsNothing);
    final completeButton = find.widgetWithText(FilledButton, '完成');
    expect(completeButton, findsOneWidget);
    expect(find.text('完成处理'), findsNothing);
    expect(
      tester.getTopLeft(methodBadge).dx,
      lessThan(tester.getTopLeft(find.text('旧台灯')).dx),
    );
    expect(
      tester.getCenter(completeButton).dx,
      greaterThan(tester.getCenter(find.text('旧台灯')).dx),
    );

    await tester.tap(find.text('旧台灯'));
    await tester.pumpAndSettle();
    expect(find.text('调整回血计划'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const Key('planned-recovery-idle-lamp')),
      const Offset(-700, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('取消惜物计划'), findsOneWidget);
  });
}
