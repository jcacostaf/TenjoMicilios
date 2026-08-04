import 'package:flutter/material.dart';
import '../../core/models/store.dart';
import '../../core/services/api_service.dart';
import 'catalog_screen.dart';

class StoreSelectorScreen extends StatefulWidget {
  const StoreSelectorScreen({super.key});

  @override
  State<StoreSelectorScreen> createState() => _StoreSelectorScreenState();
}

class _StoreSelectorScreenState extends State<StoreSelectorScreen> {
  final _api = ApiService();
  late Future<List<Store>> _storesFuture;

  @override
  void initState() {
    super.initState();
    _storesFuture = _api.getStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu tienda')),
      body: FutureBuilder<List<Store>>(
        future: _storesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error cargando tiendas: ${snapshot.error}'));
          }
          final stores = snapshot.data ?? [];
          if (stores.isEmpty) {
            return const Center(child: Text('No hay tiendas registradas todavia'));
          }
          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(store.name),
                subtitle: Text(store.address),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CatalogScreen(store: store),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
