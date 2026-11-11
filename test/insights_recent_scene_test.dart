import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/domain/insights_summary.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/insights_screen.dart';
import 'package:hsgx/theme.dart';

InventoryItem _item(String id, String month, double value) {
  final purchaseDate = '2026-$month-01';
  return InventoryItem(
    id: id,
    name: '物品 $id',
    purchaseDate: purchaseDate,
    createdAt: '${purchaseDate}T08:00:00.000',
    currentValue: value,
    purchasePrice: value,
    usageRecords: ['2026-11-05T08:00:00.000', '2026-11-06T08:00:00.000'],
    statusHistory: [
      StatusEvent(status: 'inuse', at: '${purchaseDate}T08:00:00.000'),
    ],
  );
}

void main() {
  testWidgets('最近光景使用环形使用率和三块生活数据', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final snapshot = InsightsSnapshot.build(
      [
        _item('camera', '10', 5000),
        _item('chair', '08', 2600),
        _item('books', '02', 1200),
      ],
      period: InsightsPeriod.last30,
      now: DateTime(2026, 11, 11),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(appSkins.length - 1),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: InsightsRecentSceneCard(snapshot: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insights-recent-scene')), findsOneWidget);
    expect(find.byKey(const Key('insights-usage-ring')), findsOneWidget);
    expect(find.text('正在使用'), findsOneWidget);
    expect(find.text('本期使用'), findsOneWidget);
    expect(find.text('闲置占用'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
