import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/api/api_client.dart';
import 'package:hsgx/services/image_upload_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('OSS 预签名、二进制上传和附件登记使用指南接口', () async {
    final requests = <http.Request>[];
    final service = ImageUploadService(
      ApiClient(
        baseUrl: 'https://example.com',
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'code': '00000',
                'data': {
                  'preSignUrl': 'https://bucket.oss-cn-beijing.aliyuncs.com/mall/photo.png?sign=1',
                  'fileName': 'photo.png',
                  'dir': 'mall',
                },
              }),
              200,
            );
          }
          if (request.url.host == 'bucket.oss-cn-beijing.aliyuncs.com') {
            return http.Response('', 200);
          }
          return http.Response(
            jsonEncode({'code': '00000', 'data': true}),
            200,
          );
        }),
      ),
    );

    await service.uploadBytes(
      Uint8List.fromList([1, 2, 3]),
      fileName: 'photo.png',
      token: 'token',
    );

    expect(requests[0].url.path, '/mall_biz/ua/oss/get_batch_pre_sign_url');
    expect(requests[0].url.queryParameters['fileNames'], 'photo.png');
    expect(requests[0].headers['Authorization'], 'token');
    expect(requests[1].method, 'PUT');
    expect(requests[1].headers['Content-Type'], 'image/png');
    expect(requests[2].url.path, '/mall_biz/attach_file/save_to_platform');
    final body = jsonDecode(requests[2].body) as List;
    expect((body.single as Map)['filePath'], '/mall/photo.png');
  });

  test('远端附件删除只提交资源域名下的文件路径', () async {
    late http.Request captured;
    final service = ImageUploadService(
      ApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'code': '00000', 'data': true}),
            200,
          );
        }),
      ),
    );

    await service.deleteRemoteImages([
      'https://mizhenhl.oss-cn-beijing.aliyuncs.com/mall/photo-a.jpg',
      '/mall/photo-b.jpg',
      '/private/local-photo.jpg',
      'https://other.example.com/photo-c.jpg',
    ], token: 'token');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/mall_biz/attach_file/delete');
    expect(captured.headers['Authorization'], 'token');
    final body = jsonDecode(captured.body) as Map;
    expect(body['filePaths'], ['/mall/photo-a.jpg', '/mall/photo-b.jpg']);
  });
}
