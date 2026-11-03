import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AppStateStorage {
  Future<String?> read(String key);

  Future<bool> write(String key, String value);
}

class SharedPreferencesAppStateStorage implements AppStateStorage {
  @override
  Future<String?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<bool> write(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(key, value);
  }
}
