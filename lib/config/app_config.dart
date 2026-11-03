abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ogw.whdly.cn',
  );

  static const resourceBaseUrl =
      'https://huaxiaoy.oss-cn-hangzhou.aliyuncs.com';
}
