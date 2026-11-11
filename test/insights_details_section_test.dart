import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/domain/insights_summary.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/insights_screen.dart';
import 'package:hsgx/theme.dart';

InventoryItem _item({
  required String id,
  required String category,
  required String purchaseDate,
  required double value,
}) {
  return InventoryItem(
    id: id,
    name: '物品 $id',
    purchaseDate: purchaseDate,
    createdAt: '${purchaseDate}T08:00:00.000',
    category: category,
    currentValue: value,
    purchasePrice: value,
    statusHistory: [
      StatusEvent(status: 'inuse', at: '${purchaseDate}T08:00:00.000'),
    ],
  );
}

void main() {
  testWidgets('深入洞察使用资产饼图和持有时间柱图', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final snapshot = InsightsSnapshot.build(
      [
        _item(
          id: 'camera',
          category: 'digital',
          purchaseDate: '2026-10-01',
          value: 5000,
        ),
        _item(
          id: 'chair',
          category: 'furniture',
          purchaseDate: '2025-08-01',
          value: 2600,
        ),
        _item(
          id: 'books',
          category: 'book',
          purchaseDate: '2024-02-01',
          value: 1200,
        ),
        _item(
          id: 'jacket',
          category: 'clothing',
          purchaseDate: '2020-01-01',
          value: 800,
        ),
      ],
      period: InsightsPeriod.sixMonths,
      now: DateTime(2026, 11, 11),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: InsightsDetailsSection(snapshot: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insights-asset-pie')), findsOneWidget);
    expect(find.byKey(const Key('insights-holding-chart')), findsOneWidget);
    expect(find.text('资产分布与持有结构'), findsNothing);
    expect(find.text('分类、持有时间和分类日均成本'), findsNothing);
    expect(find.text('分类拥有日均'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
