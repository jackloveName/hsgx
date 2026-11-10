import '../../config/app_config.dart';

abstract final class ApiSettings {
  static const baseUrl = AppConfig.apiBaseUrl;
  static const appBrand = AppConfig.appBrand;
  static const defaultTimeout = Duration(seconds: 10);
  static const configTimeout = Duration(seconds: 20);
  static const privacyProtocolKey = 'ZD_PRIVACY_PROTOC';
  static const registerProtocolKey = 'ZD_REGISTER_PROTOC';
}
