import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/driver_profile.dart';

class ApiService {
  Future<List<Store>> getStores() async {
    final res = await http.get(Uri.parse('$apiBaseUrl/api/stores'));
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => Store.fromJson(json)).toList();
  }

  Future<List<Product>> getProducts(int storeId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/stores/$storeId/products'),
    );
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> createProduct(int storeId, Product product) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/stores/$storeId/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
    return Product.fromJson(jsonDecode(res.body));
  }

  Future<void> updateProduct(Product product) async {
    await http.put(
      Uri.parse('$apiBaseUrl/api/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
  }

  Future<void> uploadProductPhoto(int productId, Uint8List bytes, String fileName) async {
    final uri = Uri.parse('$apiBaseUrl/api/products/$productId/photo');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    await request.send();
  }

  Future<void> createOrder(
    int storeId, {
    String? deliveryAddressText,
    String? recipientName,
    String? note,
    required List<OrderItemInput> items,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/stores/$storeId/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deliveryAddressText': deliveryAddressText,
        'recipientName': recipientName,
        'note': note,
        'items': items.map((i) => i.toJson()).toList(),
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception(_errorDetail(res.body) ?? 'No se pudo crear el pedido');
    }
  }

  Future<List<StoreOrder>> getStoreOrders(int storeId) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/api/stores/$storeId/orders'));
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => StoreOrder.fromJson(json)).toList();
  }

  Future<DriverProfile> createDriver(String name) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/drivers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    return DriverProfile.fromJson(jsonDecode(res.body));
  }

  Future<void> updateDriverLocation(int driverId, double latitude, double longitude) async {
    await http.post(
      Uri.parse('$apiBaseUrl/api/drivers/$driverId/location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': latitude, 'longitude': longitude, 'name': null}),
    );
  }

  Future<List<AvailableOrder>> getAvailableOrders(int driverId) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/api/drivers/$driverId/available-orders'));
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => AvailableOrder.fromJson(json)).toList();
  }

  Future<ActiveOrder?> getActiveOrder(int driverId) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/api/drivers/$driverId/active-order'));
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return ActiveOrder.fromJson(jsonDecode(res.body));
  }

  Future<void> acceptOrder(int orderId, int driverId) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/orders/$orderId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'driverId': driverId}),
    );
    if (res.statusCode >= 400) {
      throw Exception(_errorDetail(res.body) ?? 'No se pudo aceptar el pedido');
    }
  }

  Future<void> completeOrder(int orderId, int driverId) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/orders/$orderId/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'driverId': driverId}),
    );
    if (res.statusCode >= 400) {
      throw Exception(_errorDetail(res.body) ?? 'No se pudo marcar como entregado');
    }
  }

  String? _errorDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail'] as String?;
    } catch (_) {
      return null;
    }
  }
}
