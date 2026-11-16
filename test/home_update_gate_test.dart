import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/screens/home_screen.dart';
import 'package:hsgx/services/auth_service.dart';
import 'package:hsgx/storage/app_state_storage.dart';

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
  testWidgets('每次进入首页都重新获取用户 borrowFlag 后再判断更新', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = AppStore(storage: _MemoryStorage())
      ..authMode = 'account'
      ..accountPhone = '13800138000'
      ..accountName = '测试账号'
      ..sessionToken = 'token';

    var profileRequests = 0;
    var updateChecks = 0;
    var serverBorrowFlag = false;
    final homeKey = GlobalKey<HomeScreenState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            key: homeKey,
            store: store,
            userProfileLoader: (_) async {
              profileRequests += 1;
              return UserProfile(
                name: '测试账号',
                phone: '13800138000',
                borrowFlagEnabled: serverBorrowFlag,
              );
            },
            updateChecker: (_) async {
              updateChecks += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(profileRequests, 1);
    expect(store.borrowFlagEnabled, isFalse);
    expect(updateChecks, 0);

    serverBorrowFlag = true;
    await homeKey.currentState!.refreshUserAndCheckUpdate();
    await tester.pump();

    expect(profileRequests, 2);
    expect(store.borrowFlagEnabled, isTrue);
    expect(updateChecks, 1);

    serverBorrowFlag = false;
    await homeKey.currentState!.refreshUserAndCheckUpdate();
    await tester.pump();

    expect(profileRequests, 3);
    expect(store.borrowFlagEnabled, isFalse);
    expect(updateChecks, 1);
  });
}
