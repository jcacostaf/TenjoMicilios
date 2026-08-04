import 'package:flutter/material.dart';
import '../../core/models/store.dart';
import '../../core/models/product.dart';
import '../../core/services/api_service.dart';
import 'product_form_screen.dart';

class CatalogScreen extends StatefulWidget {
  final Store store;

  const CatalogScreen({super.key, required this.store});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _api = ApiService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _api.getProducts(widget.store.id);
    });
  }

  Future<void> _toggleActive(Product product) async {
    final updated = Product(
      id: product.id,
      storeId: product.storeId,
      name: product.name,
      description: product.description,
      price: product.price,
      isActive: !product.isActive,
      createdAt: product.createdAt,
    );
    await _api.updateProduct(updated);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catalogo - ${widget.store.name}')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error cargando productos: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('Todavia no hay productos, agrega el primero'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(
                  '\$${product.price.toStringAsFixed(0)}'
                  '${product.description != null ? ' - ${product.description}' : ''}\n'
                  'Creado: ${_formatDate(product.createdAt)}',
                ),
                isThreeLine: true,
                trailing: Switch(
                  value: product.isActive,
                  onChanged: (_) => _toggleActive(product),
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(
                        storeId: widget.store.id,
                        product: product,
                      ),
                    ),
                  );
                  _loadProducts();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductFormScreen(storeId: widget.store.id),
            ),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
