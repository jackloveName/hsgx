import 'package:shared_preferences/shared_preferences.dart';

class PrivacyConsentStore {
  static const currentVersion = 1;
  static const _key = 'hsgx.privacy.agreedVersion';

  static Future<bool> hasCurrentConsent() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_key) == currentVersion;
  }

  static Future<void> accept() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_key, currentVersion);
  }
}
