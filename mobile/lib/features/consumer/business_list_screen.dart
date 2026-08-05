import 'package:flutter/material.dart';
import '../../core/models/order.dart';
import '../../core/models/store.dart';
import '../../core/services/api_service.dart';
import '../../core/services/order_tracking_service.dart';
import 'address_list_screen.dart';
import 'order_tracking_screen.dart';
import 'store_menu_screen.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  final _api = ApiService();
  final _tracking = OrderTrackingService();

  bool _loading = true;
  String? _error;
  List<Store> _stores = [];
  String? _selectedCategory;
  OrderDetail? _activeOrder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stores = await _api.getStores();
      final activeOrderId = await _tracking.getCurrentOrderId();
      OrderDetail? activeOrder;
      if (activeOrderId != null) {
        activeOrder = await _api.getOrder(activeOrderId);
        if (activeOrder == null || activeOrder.status == OrderStatus.entregado) {
          await _tracking.setCurrentOrderId(null);
          activeOrder = null;
        }
      }
      setState(() {
        _stores = stores;
        _activeOrder = activeOrder;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando negocios: $e';
        _loading = false;
      });
    }
  }

  List<String> get _categories {
    final categories = _stores
        .map((s) => s.category)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<Store> get _filteredStores {
    final category = _selectedCategory;
    if (category == null) return _stores;
    return _stores.where((s) => s.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negocios en Tenjo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Mis direcciones',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressListScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_activeOrder != null) _buildActiveOrderCard(_activeOrder!),
                      if (_categories.isNotEmpty) ...[
                        _buildCategoryChips(),
                        const SizedBox(height: 16),
                      ],
                      if (_filteredStores.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Center(child: Text('No hay negocios en esta categoria todavia.')),
                        ),
                      ..._filteredStores.map(_buildStoreCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildActiveOrderCard(OrderDetail order) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text('Pedido activo en ${order.storeName}'),
        subtitle: Text(_statusLabel(order.status)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
          ).then((_) => _load());
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() => _selectedCategory = null),
          ),
          for (final category in _categories) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (_) => setState(() => _selectedCategory = category),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreCard(Store store) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.storefront),
        title: Text(store.name),
        subtitle: Text(store.category != null ? '${store.category} · ${store.address}' : store.address),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StoreMenuScreen(store: store)),
          );
        },
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendiente:
        return 'Esperando confirmacion del negocio';
      case OrderStatus.preparando:
        return 'Preparando tu pedido';
      case OrderStatus.listo:
        return 'Listo, esperando repartidor';
      case OrderStatus.enCamino:
        return 'En camino';
      case OrderStatus.entregado:
        return 'Entregado';
    }
  }
}
