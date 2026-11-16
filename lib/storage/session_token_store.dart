import 'app_state_storage.dart';

abstract class SessionTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

class LocalSessionTokenStore implements SessionTokenStore {
  const LocalSessionTokenStore(this._storage);

  static const _key = 'hsgx.sessionToken.local';

  final AppStateStorage _storage;

  @override
  Future<String?> read() async {
    final value = await _storage.read(_key);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> write(String token) async {
    if (!await _storage.write(_key, token)) {
      throw StateError('登录凭证写入本地存储失败');
    }
  }

  @override
  Future<void> clear() async {
    if (!await _storage.write(_key, '')) {
      throw StateError('登录凭证清理本地存储失败');
    }
  }
}

class MemorySessionTokenStore implements SessionTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
