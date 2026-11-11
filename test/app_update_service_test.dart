import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/app_update_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('版本号按数字段比较', () {
    expect(AppUpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(AppUpdateService.compareVersions('v2.0', '2.0.0'), 0);
    expect(AppUpdateService.compareVersions('1.0.0', '1.0.1'), lessThan(0));
  });

  test('iOS 更新配置会解析强制更新和说明', () {
    final info = AppUpdateService.parseUpdateInfo(
      {
        'iosAppVersion': '2.3.0',
        'iosAppDownloadUrl': 'https://example.com/app',
        'iosUpdateType': '2',
        'iosUpdateContent': '修复问题\n优化体验',
      },
      currentVersion: '2.2.9',
      isIOS: true,
    );

    expect(info, isNotNull);
    expect(info!.version, '2.3.0');
    expect(info.force, isTrue);
    expect(info.notes, contains('优化体验'));
  });

  test('关闭更新或版本不高于当前版本时不提示', () {
    expect(
      AppUpdateService.parseUpdateInfo(
        {'androidVersion': '3.0.0', 'androidUpdateType': '0'},
        currentVersion: '1.0.0',
        isIOS: false,
      ),
      isNull,
    );
    expect(
      AppUpdateService.parseUpdateInfo(
        {'androidVersion': '1.0.0'},
        currentVersion: '1.0.0',
        isIOS: false,
      ),
      isNull,
    );
  });

  testWidgets('可选更新弹窗展示版本、内容和稍后按钮', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: '花拾归匣',
      packageName: 'com.hsgx.hsgx',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    final service = AppUpdateService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': '00000',
            'data': {
              'androidVersion': '1.1.0',
              'androidUpdateType': '1',
              'androidAppDownloadUrl': 'https://example.com/app',
              'androidVersionDesc': '优化物品列表布局\n修复已知问题',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    Future<void>? check;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => check = service.checkAndShow(context),
              child: const Text('检查更新'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-update-dialog')), findsOneWidget);
    expect(find.byKey(const Key('app-update-icon')), findsOneWidget);
    expect(find.text('当前版本'), findsOneWidget);
    expect(find.text('最新版本'), findsOneWidget);
    expect(find.text('1.1.0'), findsOneWidget);
    expect(find.textContaining('优化物品列表布局'), findsOneWidget);
    expect(find.text('稍后'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);

    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    await check;

    expect(find.byKey(const Key('app-update-dialog')), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('hsgx.appUpdate.skipped'),
      startsWith('1.1.0|'),
    );
  });

  testWidgets('强制更新只限制操作而不展示额外说明', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: '花拾归匣',
      packageName: 'com.hsgx.hsgx',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    final service = AppUpdateService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': '00000',
            'data': {
              'androidVersion': '1.2.0',
              'androidUpdateType': '2',
              'androidAppDownloadUrl': 'https://example.com/app',
              'androidVersionDesc': '必要安全更新',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    Future<void>? check;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => check = service.checkAndShow(context),
              child: const Text('检查强制更新'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('检查强制更新'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-update-icon')), findsOneWidget);
    expect(find.text('强制更新'), findsNothing);
    expect(find.textContaining('完成更新后才能继续使用'), findsNothing);
    expect(find.text('稍后'), findsNothing);
    expect(find.text('立即更新'), findsOneWidget);

    Navigator.of(tester.element(find.byType(Dialog))).pop();
    await tester.pumpAndSettle();
    await check;
  });
}
