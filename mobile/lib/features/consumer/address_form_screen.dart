import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/models/consumer_address.dart';
import '../../core/services/address_storage_service.dart';
import '../../core/utils/geo.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = AddressStorageService();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();

  ll.LatLng? _pickedLocation;
  bool _outsideArea = false;
  bool _saving = false;

  void _onMapTap(ll.LatLng point) {
    setState(() {
      _pickedLocation = point;
      _outsideArea = !isWithinDeliveryArea(point.latitude, point.longitude);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null || _outsideArea) return;

    setState(() => _saving = true);

    final address = ConsumerAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text,
      addressText: _addressController.text,
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
    );
    await _storage.addAddress(address);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva direccion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Toca el mapa para elegir tu direccion (zona urbana y rural, hasta 3 km del pueblo).',
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: const ll.LatLng(tenjoCenterLat, tenjoCenterLng),
                      initialZoom: 13,
                      onTap: (_, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: const ll.LatLng(tenjoCenterLat, tenjoCenterLng),
                            radius: maxDeliveryRadiusMeters.toDouble(),
                            useRadiusInMeter: true,
                            color: Colors.deepOrange.withValues(alpha: 0.1),
                            borderColor: Colors.deepOrange,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      if (_pickedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation!,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_pin,
                                color: _outsideArea ? Colors.red : Colors.deepOrange,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_outsideArea)
                const Text(
                  'Esa ubicacion queda fuera del area de cobertura (max. 3 km del pueblo). Elige otro punto.',
                  style: TextStyle(color: Colors.red),
                )
              else if (_pickedLocation != null)
                const Text(
                  'Ubicacion dentro del area de cobertura.',
                  style: TextStyle(color: Colors.green),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Casa, Trabajo)'),
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Direccion'),
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_pickedLocation == null || _outsideArea || _saving) ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar direccion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
