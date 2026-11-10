import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/storage_screen.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('位置较多时更改位置弹层可以滚动且不会溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final item = InventoryItem(
      id: 'item',
      name: '测试物品',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      storageLocation: '位置 1',
    );
    final locations = [for (var index = 1; index <= 24; index++) '位置 $index'];
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  selected = await showLocationPicker(
                    context,
                    item,
                    locations: locations,
                  );
                },
                child: const Text('更改位置'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('更改位置'));
    await tester.pumpAndSettle();

    expect(find.text('更改「测试物品」的位置'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('位置 24'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('位置 24'));
    await tester.pumpAndSettle();

    expect(selected, '位置 24');
    expect(tester.takeException(), isNull);
  });
}
