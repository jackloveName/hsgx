import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/items_screen.dart';
import 'package:hsgx/storage/app_state_storage.dart';
import 'package:hsgx/theme.dart';

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

InventoryItem _item(String id) {
  return InventoryItem(
    id: id,
    name: '物品$id',
    purchaseDate: '2026-01-01',
    createdAt: '2026-01-01T00:00:00.000',
  );
}

void main() {
  testWidgets('新增物品后物品页自动回到顶部显示新记录', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final items = [for (var index = 0; index < 12; index++) _item('$index')];
    final storage = _MemoryStorage();
    storage.values['hsgx_flutter_state_v1'] = jsonEncode({
      'version': 7,
      'items': items.map((item) => item.toJson()).toList(),
      'wishlist': <Object?>[],
      'storageLocations': ['书房'],
      'authMode': 'guest',
      'guestAddCount': 0,
      'guestStartedAt': DateTime.now().toIso8601String(),
    });
    final store = AppStore(storage: storage);
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ItemsScreen(store: store)),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));

    await store.addItem(_item('new'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(scrollable.position.pixels, 0);
    expect(find.text('物品new'), findsOneWidget);
  });
}
