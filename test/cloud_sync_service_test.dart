import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/services/api/api_client.dart';
import 'package:hsgx/services/cloud_sync_service.dart';
import 'package:http/http.dart' as http;

class FakeHttpClient extends http.BaseClient {
  final List<http.BaseRequest> requests = [];
  bool failSave = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    Object response;
    final isSave = request.method == 'POST';
    if (isSave && failSave) {
      response = {'code': 'A00001', 'msg': '同步失败'};
    } else if (request.method == 'GET' &&
        request.url.path.contains('sys_config')) {
      response = {'code': '00000', 'data': null};
    } else {
      response = {'code': '00000', 'data': true};
    }
    final bytes = utf8.encode(jsonEncode(response));
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  test('游客数据合并后会写入账号的云配置', () async {
    final client = FakeHttpClient();
    final service = CloudSyncService(client: client);
    final item = InventoryItem(
      id: 'guest-item',
      name: '游客物品',
      purchaseDate: '2026-11-01',
      createdAt: '2026-11-01T00:00:00.000',
    );

    final result = await service.syncGuestData(
      phone: '13800138000',
      token: 'token',
      guest: GuestCloudData(
        items: [item],
        wishlist: const [],
        storageLocations: const ['书房'],
      ),
    );

    expect(result.items.single.id, 'guest-item');
    expect(
      client.requests.where((request) => request.method == 'POST'),
      hasLength(3),
    );
    final saveBodies = client.requests
        .whereType<http.Request>()
        .where((request) => request.method == 'POST')
        .map((request) => jsonDecode(request.body) as Map)
        .toList();
    expect(
      saveBodies.map((body) => body['paramKey']),
      containsAll([
        '13800138000ItemData',
        '13800138000WishListData',
        '13800138000StorageLocations',
      ]),
    );
  });

  test('云端写入失败时抛出错误，调用方可以保留游客数据', () async {
    final client = FakeHttpClient()..failSave = true;
    final service = CloudSyncService(client: client);

    await expectLater(
      service.syncGuestData(
        phone: '13800138000',
        token: 'token',
        guest: const GuestCloudData(
          items: [],
          wishlist: [],
          storageLocations: [],
        ),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
