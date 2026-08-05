import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/cart_item.dart';
import '../../core/models/consumer_address.dart';
import '../../core/models/order.dart';
import '../../core/services/address_storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/order_tracking_service.dart';
import 'address_list_screen.dart';
import 'order_tracking_screen.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

class CheckoutScreen extends StatefulWidget {
  final int storeId;
  final String storeName;
  final List<CartItem> cart;

  const CheckoutScreen({super.key, required this.storeId, required this.storeName, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _api = ApiService();
  final _addressStorage = AddressStorageService();
  final _tracking = OrderTrackingService();
  final _recipientController = TextEditingController();
  final _noteController = TextEditingController();

  bool _loadingAddress = true;
  ConsumerAddress? _selectedAddress;
  bool _placing = false;

  double get _total => widget.cart.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    setState(() => _loadingAddress = true);
    final addresses = await _addressStorage.getAddresses();
    final selectedId = await _addressStorage.getSelectedAddressId();
    final matching = addresses.where((a) => a.id == selectedId);
    setState(() {
      _selectedAddress = matching.isNotEmpty ? matching.first : (addresses.isNotEmpty ? addresses.first : null);
      _loadingAddress = false;
    });
  }

  Future<void> _pickAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressListScreen()),
    );
    _loadAddress();
  }

  Future<void> _placeOrder() async {
    final address = _selectedAddress;
    if (address == null) return;

    setState(() => _placing = true);
    try {
      final orderId = await _api.createOrder(
        widget.storeId,
        deliveryAddressText: address.addressText,
        recipientName: _recipientController.text.isEmpty ? null : _recipientController.text,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        items: widget.cart
            .map((item) => OrderItemInput(productId: item.product.id, quantity: item.quantity))
            .toList(),
      );
      await _tracking.setCurrentOrderId(orderId);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _placing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.storeName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Direccion de entrega', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _loadingAddress
              ? const Center(child: CircularProgressIndicator())
              : Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(_selectedAddress?.label ?? 'Elige una direccion'),
                    subtitle: Text(_selectedAddress?.addressText ?? 'No tienes direcciones guardadas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickAddress,
                  ),
                ),
          const SizedBox(height: 16),
          TextField(
            controller: _recipientController,
            decoration: const InputDecoration(labelText: 'Quien recibe (opcional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Nota para el pedido (opcional)'),
          ),
          const SizedBox(height: 16),
          Text('Resumen', style: Theme.of(context).textTheme.titleSmall),
          const Divider(),
          ...widget.cart.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}x ${item.product.name}'),
                  Text(_currencyFormat.format(item.subtotal)),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_currencyFormat.format(_total), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_selectedAddress == null || _placing) ? null : _placeOrder,
            child: Text(_placing ? 'Enviando...' : 'Confirmar pedido'),
          ),
        ],
      ),
    );
  }
}
