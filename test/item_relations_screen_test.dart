import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/item_relations_screen.dart';
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

InventoryItem _item(String id, String name, {int usage = 1}) {
  return InventoryItem(
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
  );
}

void main() {
  testWidgets('关联物品按行展示状态、名称和日均次均', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(_item('main', '组合主物品'));
    await store.addItem(_item('camera', '旅行相机', usage: 4));
    await store.addItem(_item('lens', '备用镜头', usage: 2));
    await store.setRelatedItems('main', ['camera', 'lens']);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemRelationsScreen(itemId: 'main', store: store),
      ),
    );
    await tester.pump();

    final cameraRow = find.byKey(const Key('related-item-camera'));
    final lensRow = find.byKey(const Key('related-item-lens'));
    expect(cameraRow, findsOneWidget);
    expect(lensRow, findsOneWidget);
    expect(
      tester.getTopLeft(cameraRow).dy,
      isNot(equals(tester.getTopLeft(lensRow).dy)),
    );
    expect(
      tester
          .getCenter(
            find.descendant(of: cameraRow, matching: find.byType(StatusPill)),
          )
          .dx,
      lessThan(
        tester
            .getCenter(
              find.descendant(of: cameraRow, matching: find.text('旅行相机')),
            )
            .dx,
      ),
    );
    expect(
      find.descendant(of: cameraRow, matching: find.text('¥25/次')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cameraRow, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.descendant(of: cameraRow, matching: find.byTooltip('移除关联')),
      findsNothing,
    );

    final candidate = find.byKey(const Key('relation-candidate-camera'));
    expect(
      tester
          .getCenter(
            find.descendant(of: candidate, matching: find.byType(StatusPill)),
          )
          .dx,
      lessThan(
        tester
            .getCenter(
              find.descendant(of: candidate, matching: find.text('旅行相机')),
            )
            .dx,
      ),
    );
    expect(
      tester
          .getCenter(
            find.descendant(of: candidate, matching: find.text('¥25/次')),
          )
          .dx,
      lessThan(
        tester
            .getCenter(
              find.descendant(of: candidate, matching: find.byType(Checkbox)),
            )
            .dx,
      ),
    );
    expect(find.text('数码产品'), findsNothing);

    final saveButton = find.widgetWithText(FilledButton, '保存');
    expect(
      find.descendant(
        of: saveButton,
        matching: find.byIcon(Icons.link_rounded),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('关联列表的长物品名称使用省略号', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longName = '陪伴很多年仍然非常喜欢的限量版复古机械键盘';
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(_item('main-long', '组合主物品'));
    await store.addItem(_item('candidate-long', longName, usage: 4));
    await store.setRelatedItems('main-long', ['candidate-long']);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ItemRelationsScreen(itemId: 'main-long', store: store),
      ),
    );
    await tester.pump();

    final names = tester.widgetList<Text>(find.text(longName)).toList();
    expect(names, isNotEmpty);
    expect(names.every((name) => name.maxLines == 1), isTrue);
    expect(
      names.every((name) => name.overflow == TextOverflow.ellipsis),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
