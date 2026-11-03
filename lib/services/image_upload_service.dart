import 'dart:typed_data';

import '../config/app_config.dart';
import 'api/api_client.dart';
import 'local_file_source.dart';

class ImageUploadService {
  ImageUploadService(this._api);

  final ApiClient _api;

  Future<String> uploadLocalPath(String path, {required String token}) async {
    final bytes = await LocalFileSource.readIfExists(path);
    if (bytes == null) throw StateError('本地图片不存在');
    return uploadBytes(
      bytes,
      fileName: LocalFileSource.fileName(path),
      token: token,
    );
  }

  Future<String> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    required String token,
  }) async {
    final signResult = await _api.get(
      '/mall_biz/ua/oss/get_batch_pre_sign_url'
      '?fileNames=${Uri.encodeQueryComponent(fileName)}',
      token: token,
    );
    final signed = _firstSignedFile(signResult);
    final presignUrl = signed?['preSignUrl']?.toString() ?? '';
    if (presignUrl.isEmpty) throw const FormatException('获取图片上传地址失败');

    final remoteName = signed!['fileName']?.toString() ?? fileName;
    final directory = signed['dir']?.toString() ?? '';
    final extension = fileName.split('.').last.toLowerCase();
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    await _api.putExternal(presignUrl, bytes: bytes, contentType: contentType);

    final remotePath = '/${directory.trim()}/$remoteName'.replaceAll(
      RegExp(r'/+'),
      '/',
    );
    await _api.post(
      '/mall_biz/attach_file/save_to_platform',
      token: token,
      body: [
        {
          'type': 1,
          'fileType': extension == 'png' ? 'png' : 'jpg',
          'fileName': remoteName,
          'filePath': remotePath,
          'fileSize': bytes.length,
        },
      ],
    );
    return '${AppConfig.resourceBaseUrl}$remotePath';
  }

  Map<String, Object?>? _firstSignedFile(Object? value) {
    final unwrapped = _unwrapData(value);
    Object? candidate = unwrapped;
    if (candidate is List && candidate.isNotEmpty) candidate = candidate.first;
    if (candidate is Map && candidate['list'] is List) {
      final list = candidate['list'] as List;
      candidate = list.isEmpty ? null : list.first;
    }
    if (candidate is! Map) return null;
    return candidate.map((key, value) => MapEntry(key.toString(), value));
  }

  Object? _unwrapData(Object? value) {
    var current = value;
    for (var index = 0; index < 5; index++) {
      if (current is Map) {
        final map = current.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (map['data'] != null) {
          current = map['data'];
          continue;
        }
      }
      break;
    }
    return current;
  }
}
