import 'package:shared_preferences/shared_preferences.dart';

class ManifestSettingsRepository {
  static const _manifestUrlKey = 'manifest_url_v1';

  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_manifestUrlKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> save(String manifestUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manifestUrlKey, manifestUrl);
  }
}
