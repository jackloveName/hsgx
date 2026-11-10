import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/collection_screen.dart';
import 'package:hsgx/theme.dart';
import 'package:hsgx/widgets.dart';

void main() {
  testWidgets('收藏馆卡片以照片为主体且在小屏下不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final item = InventoryItem(
      id: 'favorite',
      name: '旅行相机',
      category: 'digital',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      currentValue: 1999,
      storageLocation: '书房',
      favorite: true,
      statusHistory: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 150,
              child: CollectionItemCard(item: item, index: 0, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ItemPhoto), findsOneWidget);
    expect(find.text('旅行相机'), findsOneWidget);
    expect(find.text('NO.01'), findsOneWidget);
    expect(find.text('数码产品 · 书房'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
