import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/api/api_client.dart';
import 'package:hsgx/services/api/config_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('系统配置接口按指南发送公共、用户和保存请求', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'code': '00000', 'data': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final config = ConfigApi(client);

    await config.readPublic('ZD_PRIVACY_PROTOC');
    await config.readUser('13800138000ItemData', 'token');
    await config.saveUser(
      key: '13800138000ItemData',
      value: const [1, 2],
      remark: '物品数据',
      token: 'token',
    );

    expect(
      requests[0].url.path,
      '/mall_admin/ua/app/sys_config/get/value/config/ZD_PRIVACY_PROTOC',
    );
    expect(requests[0].headers['Authorization'], isNull);
    expect(
      requests[1].url.path,
      '/mall_admin/ua/app/sys_config/get/other/value/config/13800138000ItemData',
    );
    expect(requests[1].headers['Authorization'], 'token');
    expect(requests[2].method, 'POST');
    expect(requests[2].url.path, '/mall_admin/p/sys_config/ua/other/save');
    expect(requests[2].headers['Authorization'], 'token');
    final body = jsonDecode(requests[2].body) as Map;
    expect(body['paramKey'], '13800138000ItemData');
    expect(body['paramValue'], '[1,2]');
    expect(body['remark'], '物品数据');
  });
}
