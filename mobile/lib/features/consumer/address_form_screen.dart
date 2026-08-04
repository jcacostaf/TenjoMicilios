import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/models/consumer_address.dart';
import '../../core/services/address_storage_service.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/utils/geo.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = AddressStorageService();
  final _geocoding = GeocodingService();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  ll.LatLng? _pickedLocation;
  bool _outsideArea = false;
  bool _saving = false;
  bool _loadingSuggestion = false;
  HousingType _housingType = HousingType.casa;

  Future<void> _onMapTap(ll.LatLng point) async {
    setState(() {
      _pickedLocation = point;
      _outsideArea = !isWithinDeliveryArea(point.latitude, point.longitude);
    });

    if (_outsideArea) return;

    setState(() => _loadingSuggestion = true);
    final suggestion = await _geocoding.suggestAddress(point.latitude, point.longitude);
    if (!mounted || _pickedLocation != point) return;

    setState(() {
      _loadingSuggestion = false;
      if (suggestion != null) _addressController.text = suggestion;
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
      housingType: _housingType,
      additionalInfo: _additionalInfoController.text.isEmpty ? null : _additionalInfoController.text,
    );
    await _storage.addAddress(address);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva dirección')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Toca el mapa para elegir tu dirección (zona urbana y rural, hasta 3 km del pueblo).',
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
                      minZoom: workingAreaMinZoom,
                      onTap: (_, point) => unawaited(_onMapTap(point)),
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
                  'Esa ubicación queda fuera del área de cobertura (max. 3 km del pueblo). Elige otro punto.',
                  style: TextStyle(color: Colors.red),
                )
              else if (_pickedLocation != null)
                const Text(
                  'Ubicación dentro del área de cobertura.',
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
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  helperText: _loadingSuggestion ? 'Buscando dirección sugerida...' : 'Puedes editarla',
                  suffixIcon: _loadingSuggestion
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              const Text('Tipo de vivienda'),
              const SizedBox(height: 4),
              SegmentedButton<HousingType>(
                segments: const [
                  ButtonSegment(
                    value: HousingType.casa,
                    label: Text('Casa'),
                    icon: Icon(Icons.house_outlined),
                  ),
                  ButtonSegment(
                    value: HousingType.apartamento,
                    label: Text('Apartamento'),
                    icon: Icon(Icons.apartment_outlined),
                  ),
                ],
                selected: {_housingType},
                onSelectionChanged: (selection) => setState(() => _housingType = selection.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Información complementaria (opcional)',
                  helperText: 'Ej. Torre 3 apto 402, porton azul, cerca a la tienda X',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_pickedLocation == null || _outsideArea || _saving) ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar dirección'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
