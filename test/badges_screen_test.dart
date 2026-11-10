import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/screens/badges_screen.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('徽章卡片在小屏下使用紧凑布局且不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const BadgesScreen()),
    );
    await tester.pump();

    expect(find.text('匣光'), findsOneWidget);
    expect(find.text('收藏成长'), findsOneWidget);
    expect(find.text('收藏匣一点点变满'), findsNothing);
    expect(find.text('第一枚星光正等你拾起'), findsOneWidget);
    expect(find.textContaining('匣中已经亮起'), findsNothing);
    expect(find.text('已点亮'), findsNothing);
    expect(find.text('待发现'), findsNothing);
    expect(find.byKey(const Key('next-badge-card')), findsOneWidget);
    expect(find.byKey(const Key('badge-cabinet-收藏成长')), findsOneWidget);
    expect(find.byKey(const Key('top-badge-star')), findsOneWidget);
    expect(find.byKey(const Key('badge-medal-first')), findsOneWidget);
    expect(find.byKey(const Key('badge-star-first')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('badge-box-progress')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('badge-progress-collector')))
          .data,
      '0/10',
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
