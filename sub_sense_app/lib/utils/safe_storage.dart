import 'storage/storage_stub.dart'
    if (dart.library.html) 'storage/storage_web.dart';

class SafeStorage {
  static Future<void> setString(String key, String value) async {
    await StorageHelper.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    return await StorageHelper.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await StorageHelper.setString(key, value.toString());
  }

  static Future<bool?> getBool(String key) async {
    final str = await StorageHelper.getString(key);
    if (str != null) {
      return str == 'true';
    }
    return null;
  }

  static Future<void> setDouble(String key, double value) async {
    await StorageHelper.setString(key, value.toString());
  }

  static Future<double?> getDouble(String key) async {
    final str = await StorageHelper.getString(key);
    if (str != null) {
      return double.tryParse(str);
    }
    return null;
  }

  static Future<void> remove(String key) async {
    await StorageHelper.remove(key);
  }
}
