import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import '../../core/models/product.dart';
import '../../core/models/store.dart';
import '../../core/services/api_service.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

class OrdersScreen extends StatefulWidget {
  final Store store;

  const OrdersScreen({super.key, required this.store});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _api = ApiService();
  late Future<List<StoreOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _api.getStoreOrders(widget.store.id);
    });
  }

  Future<void> _confirm(StoreOrder order) async {
    try {
      await _api.confirmOrder(order.id);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _markReady(StoreOrder order) async {
    try {
      await _api.markOrderReady(order.id);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openCreateOrderSheet() async {
    final products = await _api.getProducts(widget.store.id);
    final activeProducts = products.where((p) => p.isActive).toList();
    if (!mounted) return;
    if (activeProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos activos en el catalogo')),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateOrderSheet(storeId: widget.store.id, products: activeProducts, api: _api),
    );
    if (created == true) {
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedidos - ${widget.store.name}')),
      body: FutureBuilder<List<StoreOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error cargando pedidos: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Todavia no hay pedidos'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pedido #${order.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _StatusBadge(status: order.status),
                        ],
                      ),
                      if (order.deliveryAddressText != null)
                        Text(
                          'Entregar en: ${order.deliveryAddressText}'
                          '${order.recipientName != null ? ' (${order.recipientName})' : ''}',
                        ),
                      if (order.note != null)
                        Text('Nota: ${order.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 6),
                      ...order.items.map((item) => Text('${item.quantity}x ${item.productName}')),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_currencyFormat.format(order.total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (order.status == OrderStatus.pendiente) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _confirm(order),
                          child: const Text('Confirmar pedido'),
                        ),
                      ],
                      if (order.status == OrderStatus.preparando) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _markReady(order),
                          child: const Text('Marcar listo'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateOrderSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      OrderStatus.pendiente => ('Pendiente', Colors.orange),
      OrderStatus.preparando => ('Preparando', Colors.blue),
      OrderStatus.listo => ('Listo', Colors.purple),
      OrderStatus.enCamino => ('En camino', Colors.teal),
      OrderStatus.entregado => ('Entregado', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OrderStatus.preparando) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CreateOrderSheet extends StatefulWidget {
  final int storeId;
  final List<Product> products;
  final ApiService api;

  const _CreateOrderSheet({required this.storeId, required this.products, required this.api});

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final _addressController = TextEditingController();
  final _recipientController = TextEditingController();
  final _noteController = TextEditingController();
  late Map<int, int> _quantities;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantities = {for (final p in widget.products) p.id: 0};
  }

  double get _total =>
      widget.products.fold(0.0, (sum, p) => sum + p.price * (_quantities[p.id] ?? 0));

  Future<void> _submit() async {
    final items = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) => OrderItemInput(productId: e.key, quantity: e.value))
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.api.createOrder(
        widget.storeId,
        deliveryAddressText: _addressController.text.isEmpty ? null : _addressController.text,
        recipientName: _recipientController.text.isEmpty ? null : _recipientController.text,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        items: items,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo pedido de prueba', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Todavia no existe el carrito del consumidor, asi que el restaurante '
              'puede simular un pedido eligiendo productos del catalogo.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...widget.products.map(
              (product) => Row(
                children: [
                  Expanded(child: Text(product.name)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: (_quantities[product.id] ?? 0) > 0
                        ? () => setState(() => _quantities[product.id] = _quantities[product.id]! - 1)
                        : null,
                  ),
                  Text('${_quantities[product.id]}'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        setState(() => _quantities[product.id] = (_quantities[product.id] ?? 0) + 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Direccion de entrega (opcional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(labelText: 'Nombre de quien recibe (opcional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${_currencyFormat.format(_total)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Creando...' : 'Crear pedido'),
            ),
          ],
        ),
      ),
    );
  }
}
