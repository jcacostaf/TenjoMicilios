import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import '../../core/services/api_service.dart';
import '../../core/services/driver_identity_service.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  final _api = ApiService();
  final _identity = DriverIdentityService();
  final _nameController = TextEditingController();

  int? _driverId;
  String? _driverName;
  bool _loadingIdentity = true;
  bool _registering = false;

  bool _loadingLocation = false;
  String? _locationError;

  bool _loadingOrders = false;
  String? _ordersError;
  ActiveOrder? _activeOrder;
  List<AvailableOrder> _availableOrders = [];

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final id = await _identity.getDriverId();
    final name = await _identity.getDriverName();
    setState(() {
      _driverId = id;
      _driverName = name;
      _loadingIdentity = false;
    });
    if (id != null) {
      unawaited(_refresh());
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _registering = true);
    final driver = await _api.createDriver(name);
    await _identity.save(driver.id, driver.name);
    setState(() {
      _driverId = driver.id;
      _driverName = driver.name;
      _registering = false;
    });
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final driverId = _driverId;
    if (driverId == null) return;

    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final position = await _getCurrentPosition();
      await _api.updateDriverLocation(driverId, position.latitude, position.longitude);
    } catch (e) {
      setState(() => _locationError = 'No se pudo obtener tu ubicacion: $e');
    } finally {
      setState(() => _loadingLocation = false);
    }

    setState(() {
      _loadingOrders = true;
      _ordersError = null;
    });
    try {
      final active = await _api.getActiveOrder(driverId);
      final available = active == null ? await _api.getAvailableOrders(driverId) : <AvailableOrder>[];
      setState(() {
        _activeOrder = active;
        _availableOrders = available;
      });
    } catch (e) {
      setState(() => _ordersError = 'Error cargando pedidos: $e');
    } finally {
      setState(() => _loadingOrders = false);
    }
  }

  Future<Position> _getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('permiso de ubicacion denegado');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('activa el GPS del celular');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _accept(AvailableOrder order) async {
    final driverId = _driverId;
    if (driverId == null) return;
    try {
      await _api.acceptOrder(order.orderId, driverId);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _complete() async {
    final driverId = _driverId;
    final order = _activeOrder;
    if (driverId == null || order == null) return;
    try {
      await _api.completeOrder(order.orderId, driverId);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingIdentity) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_driverId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Soy repartidor')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Antes de empezar, dinos tu nombre.'),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registering ? null : _register,
                child: Text(_registering ? 'Creando...' : 'Continuar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $_driverName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_loadingLocation || _loadingOrders) ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_locationError!, style: const TextStyle(color: Colors.red)),
              ),
            if (_loadingLocation || _loadingOrders)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (_ordersError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_ordersError!, style: const TextStyle(color: Colors.red)),
              ),
            if (_activeOrder != null) ...[
              Text('Tu pedido activo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _activeOrder!.storeName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildOrderDetails(
                        deliverTo: _activeOrder!.deliveryAddressText,
                        recipient: _activeOrder!.recipientName,
                        note: _activeOrder!.note,
                        items: _activeOrder!.items,
                        total: _activeOrder!.total,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _complete,
                        child: const Text('Entregado'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No puedes aceptar otro pedido hasta entregar este.',
                style: TextStyle(color: Colors.grey),
              ),
            ] else ...[
              Text('Entregas disponibles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_availableOrders.isEmpty && !_loadingOrders)
                const Text('No hay pedidos pendientes por ahora.'),
              ..._availableOrders.map(
                (order) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.storeName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              order.distanceMeters != null
                                  ? _formatDistance(order.distanceMeters!)
                                  : 'distancia desconocida',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildOrderDetails(
                          deliverTo: order.deliveryAddressText,
                          recipient: order.recipientName,
                          note: order.note,
                          items: order.items,
                          total: order.total,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _accept(order),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildOrderDetails({
    required String? deliverTo,
    required String? recipient,
    required String? note,
    required List<OrderItemLine> items,
    required double total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deliverTo != null)
          Text('Entregar en: $deliverTo${recipient != null ? ' ($recipient)' : ''}'),
        if (note != null) Text('Nota: $note', style: const TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Text('${item.quantity}x ${item.productName} - ${_currencyFormat.format(item.unitPrice)}'),
        ),
        const SizedBox(height: 4),
        Text('Total: ${_currencyFormat.format(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
