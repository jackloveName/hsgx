import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SessionTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

class SecureSessionTokenStore implements SessionTokenStore {
  const SecureSessionTokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'hsgx.sessionToken';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) {
    return _storage.write(key: _key, value: token);
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
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
