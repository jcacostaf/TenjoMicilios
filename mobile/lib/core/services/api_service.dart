import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/store.dart';
import '../models/product.dart';

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

  Future<void> createProduct(int storeId, Product product) async {
    await http.post(
      Uri.parse('$apiBaseUrl/api/stores/$storeId/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
  }

  Future<void> updateProduct(Product product) async {
    await http.put(
      Uri.parse('$apiBaseUrl/api/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
  }
}
