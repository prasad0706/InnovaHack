class StorageHelper {
  static final Map<String, String> _memoryCache = {};

  static Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
  }

  static Future<String?> getString(String key) async {
    return _memoryCache[key];
  }

  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
  }
}
