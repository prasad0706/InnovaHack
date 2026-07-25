// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class StorageHelper {
  static final Map<String, String> _memoryCache = {};

  static Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static Future<String?> getString(String key) async {
    try {
      final val = html.window.localStorage[key];
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _memoryCache[key];
  }

  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}
