import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import '../../core/services/api_service.dart';
import '../../core/services/order_tracking_service.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _api = ApiService();
  final _tracking = OrderTrackingService();

  static const _steps = [
    OrderStatus.pendiente,
    OrderStatus.preparando,
    OrderStatus.listo,
    OrderStatus.enCamino,
    OrderStatus.entregado,
  ];

  static const _stepLabels = {
    OrderStatus.pendiente: 'Pedido enviado',
    OrderStatus.preparando: 'Preparando',
    OrderStatus.listo: 'Listo para recoger',
    OrderStatus.enCamino: 'En camino',
    OrderStatus.entregado: 'Entregado',
  };

  OrderDetail? _order;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await _api.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      if (order != null && order.status == OrderStatus.entregado) {
        final current = await _tracking.getCurrentOrderId();
        if (current == widget.orderId) {
          await _tracking.setCurrentOrderId(null);
        }
      }
    } catch (_) {
      // fallo silencioso: el proximo ciclo de sondeo lo reintenta
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu pedido')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text('No se encontro el pedido.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(order.storeName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    if (order.deliveryAddressText != null)
                      Text(
                        'Entregar en: ${order.deliveryAddressText}'
                        '${order.recipientName != null ? " (${order.recipientName})" : ""}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 24),
                    _buildStepper(order.status),
                    const SizedBox(height: 24),
                    const Divider(),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.quantity}x ${item.productName}'),
                            Text(_currencyFormat.format(item.unitPrice * item.quantity)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_currencyFormat.format(order.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildStepper(OrderStatus status) {
    final currentIndex = _steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  i <= currentIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: i <= currentIndex ? Colors.deepOrange : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  _stepLabels[_steps[i]]!,
                  style: TextStyle(
                    fontWeight: i == currentIndex ? FontWeight.bold : FontWeight.normal,
                    color: i <= currentIndex ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
