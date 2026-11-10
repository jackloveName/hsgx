abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dmjz.makcabxa02y.icu',
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

  /// 后端协议正文中的运营方占位符由构建环境提供。
  static const agreementOperatorName = String.fromEnvironment(
    'AGREEMENT_OPERATOR_NAME',
    defaultValue: '',
  );
  static const agreementContactEmail = String.fromEnvironment(
    'AGREEMENT_CONTACT_EMAIL',
    defaultValue: '',
  );
}
