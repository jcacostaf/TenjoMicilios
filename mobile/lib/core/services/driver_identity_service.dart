import 'package:shared_preferences/shared_preferences.dart';

class DriverIdentityService {
  static const _idKey = 'driver_id';
  static const _nameKey = 'driver_name';

  Future<int?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_idKey);
  }

  Future<String?> getDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> save(int id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, id);
    await prefs.setString(_nameKey, name);
  }
}
