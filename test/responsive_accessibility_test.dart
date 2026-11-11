import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/components/item_summary_card.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/items_screen.dart';
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

InventoryItem _item({
  required String id,
  required String name,
  required String usageMode,
  int manualUsageCount = 0,
}) {
  return InventoryItem(
    id: id,
    name: name,
    purchaseDate: '2026-01-01',
    createdAt: '2026-01-01T00:00:00.000',
    currentValue: 9999.99,
    purchasePrice: 12999.99,
    usageMode: usageMode,
    manualUsageCount: manualUsageCount,
    usageRecords: manualUsageCount > 0
        ? List.filled(manualUsageCount, '2026-11-07T00:00:00.000')
        : const [],
    statusHistory: [
      StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
    ],
  );
}

Widget _scaledApp(Widget home) {
  return MaterialApp(
    theme: buildAppTheme(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      );
    },
    home: home,
  );
}

void main() {
  testWidgets('统一物品摘要卡在小屏和大字体下不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final manual = _item(
      id: 'manual',
      name: '这是一个很长的手动计次物品名称',
      usageMode: 'manual',
      manualUsageCount: 12,
    );

    await tester.pumpWidget(
      _scaledApp(
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: ItemSummaryCard(
              item: manual,
              onTap: () {},
              onUsageChanged: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(manual.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('物品三个视图支持小屏、大字体和计次语义', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      _item(
        id: 'manual',
        name: '超长名称的手动计次物品用于检查布局',
        usageMode: 'manual',
        manualUsageCount: 12,
      ),
    );
    await store.addItem(
      _item(id: 'automatic', name: '自动计次物品', usageMode: 'auto'),
    );

    await tester.pumpWidget(
      _scaledApp(Scaffold(body: ItemsScreen(store: store))),
    );
    await tester.pump();

    final increment = find.byKey(const Key('manual-usage-increment-manual'));
    expect(
      tester
          .getSize(find.byKey(const Key('gallery-manual-stepper-manual')))
          .width,
      closeTo(
        tester
            .getSize(
              find.descendant(
                of: find
                    .ancestor(
                      of: find.text('超长名称的手动计次物品用于检查布局'),
                      matching: find.byType(SoftCard),
                    )
                    .first,
                matching: find.byType(ItemPhoto),
              ),
            )
            .width,
        0.01,
      ),
    );
    final incrementSemantics = tester.getSemantics(increment);
    expect(incrementSemantics.label, '增加一次使用');
    expect(
      incrementSemantics.getSemanticsData().flagsCollection.isButton,
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('台账'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const Key('ledger-manual-stepper-manual')))
          .width,
      84,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('收纳'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const Key('location-manual-stepper-manual')))
          .width,
      84,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('只有使用中的手动计次物品显示增减控件', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    final idle =
        _item(
          id: 'idle-manual',
          name: '闲置手动计次物品',
          usageMode: 'manual',
          manualUsageCount: 3,
        ).copyWith(
          status: 'idle',
          statusHistory: [
            StatusEvent(status: 'idle', at: '2026-11-01T00:00:00.000'),
          ],
        );
    await store.addItem(idle);

    await tester.pumpWidget(
      _scaledApp(Scaffold(body: ItemsScreen(store: store))),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('manual-usage-increment-idle-manual')),
      findsNothing,
    );
    await tester.tap(find.text('台账'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('ledger-manual-stepper-idle-manual')),
      findsNothing,
    );
    await tester.tap(find.text('收纳'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('location-manual-panel-idle-manual')),
      findsNothing,
    );

    await store.incrementUsage(idle.id, 1);
    expect(store.itemById(idle.id)?.manualUsageCount, 3);
    expect(tester.takeException(), isNull);
  });
}
