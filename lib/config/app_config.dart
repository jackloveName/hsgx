import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hsgx.makcabxa02y.icu',
  );

  /// 对象存储的公开访问前缀（首次上传时会按预签名地址自动校正）
  static const resourceBaseUrl = String.fromEnvironment(
    'RESOURCE_BASE_URL',
    defaultValue: 'https://mizhenhl.oss-cn-beijing.aliyuncs.com',
  );

  /// 登录与公共配置使用的后端应用标识。
  static const String appBrand = String.fromEnvironment(
    'APP_BRAND',
    defaultValue: '花拾归匣',
  );

  /// iOS 协议网页地址；未配置时自动回退到 App 原生协议页。
  static const agreementPageUrl = String.fromEnvironment(
    'AGREEMENT_PAGE_URL',
    defaultValue: '',
  );

  /// 可选全局覆盖；Android 和 iOS 默认使用下方的平台独立值。
  static const _agreementOperatorOverride = String.fromEnvironment(
    'AGREEMENT_OPERATOR_NAME',
    defaultValue: '',
  );
  static const _agreementContactEmailOverride = String.fromEnvironment(
    'AGREEMENT_CONTACT_EMAIL',
    defaultValue: '',
  );
  static const _androidOperatorName = String.fromEnvironment(
    'ANDROID_AGREEMENT_OPERATOR_NAME',
    defaultValue: '深圳市亮任网络科技有限公司',
  );
  static const _androidContactEmail = String.fromEnvironment(
    'ANDROID_AGREEMENT_CONTACT_EMAIL',
    defaultValue: 'williamchavez6095@outlook.com',
  );
  static const _iosOperatorName = String.fromEnvironment(
    'IOS_AGREEMENT_OPERATOR_NAME',
    defaultValue: 'Grant Alston Remington',
  );
  static const _iosContactEmail = String.fromEnvironment(
    'IOS_AGREEMENT_CONTACT_EMAIL',
    defaultValue: 'BarncastleFarquer34@outlook.com',
  );

  static ({String operatorName, String contactEmail}) agreementIdentityFor(
    TargetPlatform platform,
  ) {
    return (
      operatorName: _agreementOperatorOverride.isNotEmpty
          ? _agreementOperatorOverride
          : platform == TargetPlatform.iOS
          ? _iosOperatorName
          : _androidOperatorName,
      contactEmail: _agreementContactEmailOverride.isNotEmpty
          ? _agreementContactEmailOverride
          : platform == TargetPlatform.iOS
          ? _iosContactEmail
          : _androidContactEmail,
    );
  }

  static String get agreementOperatorName =>
      agreementIdentityFor(defaultTargetPlatform).operatorName;

  static String get agreementContactEmail =>
      agreementIdentityFor(defaultTargetPlatform).contactEmail;
}
