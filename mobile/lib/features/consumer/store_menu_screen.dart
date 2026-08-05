import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_config.dart';
import '../../core/models/cart_item.dart';
import '../../core/models/product.dart';
import '../../core/models/store.dart';
import '../../core/services/api_service.dart';
import 'checkout_screen.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

class StoreMenuScreen extends StatefulWidget {
  final Store store;

  const StoreMenuScreen({super.key, required this.store});

  @override
  State<StoreMenuScreen> createState() => _StoreMenuScreenState();
}

class _StoreMenuScreenState extends State<StoreMenuScreen> {
  final _api = ApiService();
  late Future<List<Product>> _productsFuture;
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = _api.getProducts(widget.store.id);
  }

  void _setQuantity(Product product, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _quantities.remove(product.id);
      } else {
        _quantities[product.id] = quantity;
      }
    });
  }

  List<CartItem> _buildCart(List<Product> products) {
    final result = <CartItem>[];
    for (final entry in _quantities.entries) {
      final matches = products.where((p) => p.id == entry.key);
      if (matches.isNotEmpty) {
        result.add(CartItem(product: matches.first, quantity: entry.value));
      }
    }
    return result;
  }

  double _cartTotal(List<Product> products) =>
      _buildCart(products).fold(0, (sum, item) => sum + item.subtotal);

  int get _cartCount => _quantities.values.fold(0, (sum, q) => sum + q);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.store.name)),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error cargando el menu: ${snapshot.error}'));
          }
          final products = (snapshot.data ?? []).where((p) => p.isActive).toList();
          if (products.isEmpty) {
            return const Center(child: Text('Esta tienda todavia no tiene productos.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final quantity = _quantities[product.id] ?? 0;
              return ListTile(
                leading: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          '$apiBaseUrl${product.imageUrl}',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.fastfood),
                title: Text(product.name),
                subtitle: Text(
                  '${_currencyFormat.format(product.price)}'
                  '${product.description != null ? ' - ${product.description}' : ''}',
                ),
                trailing: quantity == 0
                    ? OutlinedButton(
                        onPressed: () => _setQuantity(product, 1),
                        child: const Text('Agregar'),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _setQuantity(product, quantity - 1),
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _setQuantity(product, quantity + 1),
                          ),
                        ],
                      ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _cartCount == 0
          ? null
          : FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                final cart = _buildCart(products);
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: cart.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    storeId: widget.store.id,
                                    storeName: widget.store.name,
                                    cart: cart,
                                  ),
                                ),
                              );
                            },
                      child: Text('Ver pedido ($_cartCount) · ${_currencyFormat.format(_cartTotal(products))}'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
