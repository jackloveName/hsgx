import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/components/collection/collection_item_card.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/collection_screen.dart';
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
    var favoriteTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 150,
              child: CollectionItemCard(
                item: item,
                onFavoriteTap: () => favoriteTapped = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ItemPhoto), findsOneWidget);
    expect(find.text('旅行相机'), findsOneWidget);
    expect(find.textContaining('NO.'), findsNothing);
    expect(find.text('数码产品 · 书房'), findsOneWidget);
    expect(find.text('珍藏于 2026.01.01'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('collection-favorite-toggle-favorite')),
    );
    expect(favoriteTapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击珍爱爱心需要确认后才取消珍爱', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'favorite-confirm',
        name: '旅行相机',
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        favorite: true,
        favoriteAt: '2026-01-02T00:00:00.000',
        statusHistory: [
          StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CollectionScreen(store: store),
      ),
    );
    await tester.pump();

    final heart = find.byKey(
      const Key('collection-favorite-toggle-favorite-confirm'),
    );
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(find.text('取消珍爱？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(store.itemById('favorite-confirm')?.favorite, isTrue);

    await tester.tap(heart);
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消珍爱'));
    await tester.pumpAndSettle();

    expect(store.itemById('favorite-confirm'), isNotNull);
    expect(store.itemById('favorite-confirm')?.favorite, isFalse);
    expect(find.text('旅行相机'), findsNothing);
  });

  testWidgets('珍爱卡片的长物品名称使用省略号', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longName = '陪伴很多年仍然非常喜欢的限量版复古机械键盘纪念收藏款';
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      InventoryItem(
        id: 'long-favorite',
        name: longName,
        purchaseDate: '2026-01-01',
        createdAt: '2026-01-01T00:00:00.000',
        favorite: true,
        favoriteAt: '2026-01-02T00:00:00.000',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CollectionScreen(store: store),
      ),
    );
    await tester.pump();

    final name = tester.widget<Text>(find.text(longName));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
