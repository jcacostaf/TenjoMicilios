import 'package:shared_preferences/shared_preferences.dart';

class OrderTrackingService {
  static const _currentOrderIdKey = 'consumer_current_order_id';

  Future<int?> getCurrentOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentOrderIdKey);
  }

  Future<void> setCurrentOrderId(int? orderId) async {
    final prefs = await SharedPreferences.getInstance();
    if (orderId == null) {
      await prefs.remove(_currentOrderIdKey);
    } else {
      await prefs.setInt(_currentOrderIdKey, orderId);
    }
  }
}
