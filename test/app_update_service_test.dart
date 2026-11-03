import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/app_update_service.dart';

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
}
