import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';
import 'image_upload_service.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.phone,
    required this.userName,
  });

  final String token;
  final String phone;
  final String userName;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    this.avatarPath = '',
    this.birthday = '',
    this.gender = '',
  });

  final String name;
  final String phone;
  final String avatarPath;
  final String birthday;
  final String gender;
}

class AuthService {
  AuthService({
    http.Client? client,
    ApiClient? apiClient,
    void Function()? onUnauthorized,
  }) : _api =
           apiClient ??
           ApiClient(client: client, onUnauthorized: onUnauthorized) {
    _imageUploader = ImageUploadService(_api);
  }

  final ApiClient _api;
  late final ImageUploadService _imageUploader;
  static const _passwordSecret = String.fromEnvironment(
    'LOGIN_PASSWORD_SECRET',
    defaultValue: '-mall--password-',
  );

  Future<void> sendLoginCode(String phone) async {
    await _api.put(
      '/mall_biz/ua/sms/verification_code/login_whocode',
      body: {'mobile': phone},
      timeout: ApiSettings.configTimeout,
      silent: true,
    );
  }

  Future<AuthSession> loginWithCode({
    required String phone,
    required String code,
  }) async {
    final result = await _api.post(
      '/mall_auth/ua/login_with_code',
      body: {
        ..._baseLoginPayload(phone, loginStatus: 1),
        'mobile': phone,
        'validCode': code,
      },
    );
    return _sessionFromResponse(result, phone);
  }

  Future<AuthSession> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final encrypted = _encryptPassword(
      '${DateTime.now().millisecondsSinceEpoch}$password',
    );
    final result = await _api.post(
      '/mall_auth/ua/login',
      body: {
        ..._baseLoginPayload(phone, loginStatus: 2),
        'passWord': encrypted,
      },
    );
    return _sessionFromResponse(result, phone);
  }

  Future<String> getUserName(String token, String fallbackPhone) async {
    final profile = await getUserProfile(token, fallbackPhone: fallbackPhone);
    return profile.name;
  }

  Future<UserProfile> getUserProfile(
    String token, {
    required String fallbackPhone,
  }) async {
    try {
      final result = await _api.get(
        '/mall_user/user/ma/user_detail_info',
        token: token,
      );
      final user = _unwrapUser(result);
      return UserProfile(
        name:
            (user['nickName'] ??
                    user['nickname'] ??
                    user['userName'] ??
                    user['name'] ??
                    user['phone'] ??
                    fallbackPhone)
                .toString(),
        phone: (user['phone'] ?? user['mobile'] ?? fallbackPhone).toString(),
        avatarPath: _resolveAvatarPath(
          (user['pic'] ??
                  user['avatar'] ??
                  user['avatarUrl'] ??
                  user['headImg'] ??
                  user['headImgUrl'] ??
                  user['userPic'] ??
                  '')
              .toString(),
        ),
        birthday: (user['birthDate'] ?? user['birthday'] ?? '').toString(),
        gender: (user['sex'] ?? user['gender'] ?? '').toString(),
      );
    } on Object {
      return UserProfile(name: fallbackPhone, phone: fallbackPhone);
    }
  }

  Future<UserProfile> updateUserProfile({
    required String token,
    required String name,
    required String avatarPath,
    required String birthday,
    required String gender,
  }) async {
    await _api.put(
      '/mall_user/user/set_user_info',
      token: token,
      body: {
        'nickName': name,
        'pic': avatarPath,
        'sex': gender,
        'birthDate': birthday,
      },
    );
    return UserProfile(
      name: name,
      phone: '',
      avatarPath: avatarPath,
      birthday: birthday,
      gender: gender,
    );
  }

  Future<String> uploadAvatar({
    required String token,
    required String localPath,
  }) {
    return _imageUploader.uploadLocalPath(localPath, token: token);
  }

  Future<void> logout(String token) async {
    await _api.post('/mall_auth/ma/login_out', token: token);
  }

  Future<void> destroyAccount(String token, {bool forceDestroy = false}) async {
    await _api.get(
      '/mall_user/user/destroy_user?forceDestroy=$forceDestroy',
      token: token,
    );
  }

  void close() => _api.close();

  AuthSession _sessionFromResponse(Object? result, String phone) {
    if (result is! Map) throw const FormatException('登录响应格式错误');
    final token = result['accessToken']?.toString().trim();
    if (token == null || token.isEmpty) {
      throw const FormatException('登录响应中缺少访问凭证');
    }
    return AuthSession(token: token, phone: phone, userName: phone);
  }

  Map<String, Object?> _baseLoginPayload(
    String phone, {
    required int loginStatus,
  }) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return {
      'sysType': 0,
      'socialType': switch (defaultTargetPlatform) {
        TargetPlatform.android => 5,
        TargetPlatform.iOS => 6,
        _ => 4,
      },
      'tempUid': '',
      'userName': phone,
      'appBrand': ApiSettings.appBrand,
      'osName': isIOS ? 'iOS' : defaultTargetPlatform.name,
      'loginStatus': loginStatus,
    };
  }

  String _encryptPassword(String value) {
    final encrypter = Encrypter(
      AES(Key.fromUtf8(_passwordSecret), mode: AESMode.ecb),
    );
    return encrypter.encrypt(value, iv: IV.fromLength(0)).base64;
  }

  String _resolveAvatarPath(String value) {
    final path = value.trim();
    if (path.startsWith('/') && !path.startsWith('//')) {
      return '${AppConfig.resourceBaseUrl}$path';
    }
    return path;
  }

  Map<String, Object?> _unwrapUser(Object? value) {
    var current = value;
    for (var index = 0; index < 4; index++) {
      if (current is! Map) break;
      final map = current.map((key, value) => MapEntry(key.toString(), value));
      current = map['userInfo'] ?? map['user'] ?? map['data'] ?? map;
      if (identical(current, map)) return map;
    }
    return current is Map
        ? current.map((key, value) => MapEntry(key.toString(), value))
        : const {};
  }
}
