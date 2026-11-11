import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/components/home_asset_summary.dart';
import 'package:hsgx/components/home_daily_hero.dart';
import 'package:hsgx/components/home_today_actions.dart';
import 'package:hsgx/components/item_summary_card.dart';
import 'package:hsgx/components/recent_item_shelf.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/theme.dart';
import 'package:hsgx/widgets.dart';

InventoryItem _item() {
  return InventoryItem(
    id: 'lamp',
    name: '客厅灯',
    category: 'furniture',
    purchaseDate: formatDate(DateTime.now().subtract(const Duration(days: 99))),
    createdAt: DateTime.now().toIso8601String(),
    statusHistory: [
      StatusEvent(
        status: 'inuse',
        at: DateTime.now().subtract(const Duration(days: 99)).toIso8601String(),
      ),
    ],
  );
}

void main() {
  testWidgets('空首页展示三步引导而不是零值资产卡', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: HomeDailyHero(
                item: null,
                title: '从第一件美好开始',
                message: '选一件每天都会用到的东西。',
                actionLabel: '记录第一件物品',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('从第一件美好开始'), findsOneWidget);
    expect(find.text('选一件每天都会用到的东西。', skipOffstage: false), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
    expect(find.textContaining('¥0'), findsNothing);
  });

  testWidgets('今日一物展示物品、使用天数和主要动作', (tester) async {
    final item = _item();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: HomeDailyHero(
                item: item,
                title: item.name,
                message: '已累计使用 100 天，是收藏匣里的高频伙伴。',
                actionLabel: '看看它',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('客厅灯'), findsOneWidget);
    expect(find.text('相伴 100 天'), findsOneWidget);
    expect(find.text('已累计使用 100 天，是收藏匣里的高频伙伴。'), findsOneWidget);
    expect(find.text('看看它'), findsOneWidget);
    expect(find.text('使用中'), findsOneWidget);
    expect(find.text('家具 · 使用中'), findsNothing);
    expect(find.byType(ItemPhoto), findsNothing);
    expect(find.byKey(const Key('home-daily-backdrop')), findsOneWidget);
    expect(
      tester.getSize(find.byType(HomeDailyHero)).height,
      closeTo(280, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('照片主场在 320px 小屏和长标题下不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final item = _item().copyWith(name: '这是一件名字很长但每天都在使用的限量版复古客厅落地灯');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: HomeDailyHero(
              item: item,
              title: item.name,
              message: '已累计使用 100 天，是收藏匣里的高频伙伴。',
              actionLabel: '看看它',
              onAction: () {},
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(
      find.text(item.name, skipOffstage: false),
    );
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有照片时的今日一物高度保持紧凑', (tester) async {
    final item = _item().copyWith(imagePath: 'missing-photo.jpg');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: HomeDailyHero(
                item: item,
                title: item.name,
                message: '已累计使用 100 天，是收藏匣里的高频伙伴。',
                actionLabel: '看看它',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ItemPhoto), findsNothing);
    expect(find.byKey(const Key('home-daily-backdrop')), findsOneWidget);
    expect(
      tester.getSize(find.byType(HomeDailyHero)).height,
      closeTo(280, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('紧凑生活数据和横向物品架在小屏下不溢出', (tester) async {
    final item = _item();
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                HomeAssetSummary(
                  totalValue: 1299,
                  ownedDailyCost: 12.99,
                  totalCount: 1,
                  inUseCount: 1,
                  monthUsageDays: 30,
                  onStatusTap: (_) {},
                ),
                const SizedBox(height: 16),
                RecentItemShelf(items: [item], onTap: (_) {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('¥1,299'), findsOneWidget);
    expect(find.text('本月使用'), findsOneWidget);
    expect(find.text('客厅灯'), findsOneWidget);
    expect(find.text('使用中'), findsOneWidget);
    expect(find.text('家具 · 待安放'), findsOneWidget);
    expect(find.textContaining('最近使用：'), findsNothing);
    expect(
      tester.widget<ItemSummaryCard>(find.byType(ItemSummaryCard)).onLongPress,
      isNull,
    );
    expect(
      tester.getTopLeft(find.text('使用中')).dx,
      lessThan(tester.getTopLeft(find.text('客厅灯')).dx),
    );
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页行动卡只展示标题和说明', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: HomeTodayActions(
            actions: [
              HomeActionItem(
                label: '闲置回看',
                title: '1 件物品正在等待决定',
                message: '用一次或回血，都比继续放着更有答案。',
                icon: Icons.recycling_rounded,
                color: buildAppTheme().colorScheme.primary,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('闲置回看'), findsNothing);
    expect(find.text('1 件物品正在等待决定'), findsOneWidget);
    expect(find.text('用一次或回血，都比继续放着更有答案。'), findsOneWidget);
  });
}
