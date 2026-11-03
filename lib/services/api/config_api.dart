import 'dart:convert';

import 'api_client.dart';
import 'api_settings.dart';

class ConfigApi {
  const ConfigApi(this._client);

  final ApiClient _client;

  Future<Object?> readPublic(String key) {
    return _client.get(
      '/mall_admin/ua/app/sys_config/get/value/config/${Uri.encodeComponent(key)}',
      timeout: ApiSettings.configTimeout,
      silent: true,
    );
  }

  Future<Object?> readUser(String key, String token) {
    return _client.get(
      '/mall_admin/ua/app/sys_config/get/other/value/config/${Uri.encodeComponent(key)}',
      token: token,
    );
  }

  Future<void> saveUser({
    required String key,
    required Object value,
    required String remark,
    required String token,
  }) async {
    await _client.post(
      '/mall_admin/p/sys_config/ua/other/save',
      token: token,
      body: {
        'paramKey': key,
        'paramValue': value is String ? value : jsonEncode(value),
        'remark': remark,
      },
    );
  }
}
