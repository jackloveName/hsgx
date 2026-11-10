import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/components/item_image_carousel.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('多张物品图片会全宽展示并自动循环切换', (tester) async {
    final item = InventoryItem(
      id: 'gallery',
      name: '相机',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      imagePaths: const ['/missing-a.jpg', '/missing-b.jpg'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(width: 390, child: ItemImageCarousel(item: item)),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('2 / 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
