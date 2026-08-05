import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/models/order.dart';
import '../../core/services/api_service.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/services/routing_service.dart';
import '../../core/utils/geo.dart';

class DriverNavigationScreen extends StatefulWidget {
  final ActiveOrder initialOrder;
  final int driverId;

  const DriverNavigationScreen({super.key, required this.initialOrder, required this.driverId});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final _api = ApiService();
  final _geocoding = GeocodingService();
  final _routing = RoutingService();
  final _mapController = MapController();

  late ActiveOrder _order;
  StreamSubscription<Position>? _positionSub;
  ll.LatLng? _currentPosition;
  ll.LatLng? _destination;
  bool _resolvingDestination = false;
  bool _submitting = false;
  bool _mapReady = false;
  Timer? _statusPollTimer;
  OrderStatus? _destinationResolvedForStatus;

  List<ll.LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _fetchingRoute = false;
  DateTime? _lastRouteFetch;
  bool _hasFitBounds = false;
  bool _hasFitRoute = false;
  ll.LatLng? _lastRecenteredPosition;

  static const _recenterThresholdMeters = 15.0;
  static const _maxAcceptableAccuracyMeters = 50.0;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    unawaited(_resolveDestination());
    _startTracking();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _reloadOrder());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolveDestination() async {
    if (_destinationResolvedForStatus == _order.status) return;
    _destinationResolvedForStatus = _order.status;
    _routePoints = [];
    _routeDistanceMeters = null;
    _routeDurationSeconds = null;
    _hasFitBounds = false;
    _hasFitRoute = false;
    _lastRecenteredPosition = null;

    if (_order.status == OrderStatus.enCamino) {
      final address = _order.deliveryAddressText;
      if (address == null || address.trim().isEmpty) {
        setState(() => _destination = null);
        return;
      }
      setState(() => _resolvingDestination = true);
      final point = await _geocoding.geocodeAddress(address);
      if (!mounted) return;
      setState(() {
        _destination = point;
        _resolvingDestination = false;
      });
    } else {
      final lat = _order.storeLatitude;
      final lng = _order.storeLongitude;
      setState(() => _destination = (lat != null && lng != null) ? ll.LatLng(lat, lng) : null);
    }
    unawaited(_maybeFetchRoute(force: true));
    _maybeFitBounds();
  }

  void _maybeFitBounds() {
    if (_hasFitBounds || !_mapReady) return;
    final origin = _currentPosition;
    final dest = _destination;
    if (origin == null || dest == null) return;

    _hasFitBounds = true;
    _lastRecenteredPosition = origin;
    _fitToCoordinates([origin, dest]);
  }

  void _maybeFitRoute() {
    if (_hasFitRoute || !_mapReady || _routePoints.isEmpty) return;
    _hasFitRoute = true;
    if (_currentPosition != null) _lastRecenteredPosition = _currentPosition;
    _fitToCoordinates(_routePoints);
  }

  void _fitToCoordinates(List<ll.LatLng> points) {
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 180),
        maxZoom: workingAreaMaxZoom,
      ),
    );
  }

  Future<void> _maybeFetchRoute({bool force = false}) async {
    final origin = _currentPosition;
    final dest = _destination;
    if (origin == null || dest == null || _fetchingRoute) return;
    if (!force &&
        _lastRouteFetch != null &&
        DateTime.now().difference(_lastRouteFetch!) < const Duration(seconds: 15)) {
      return;
    }

    _fetchingRoute = true;
    _lastRouteFetch = DateTime.now();
    final result = await _routing.getRoute(origin, dest);
    _fetchingRoute = false;
    if (!mounted || result == null) return;
    setState(() {
      _routePoints = result.points;
      _routeDistanceMeters = result.distanceMeters;
      _routeDurationSeconds = result.durationSeconds;
    });
    _maybeFitRoute();
  }

  void _startTracking() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      final point = ll.LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _currentPosition = point);
      unawaited(_api.updateDriverLocation(widget.driverId, position.latitude, position.longitude));
      unawaited(_maybeFetchRoute());
      if (_mapReady) {
        if (_hasFitBounds) {
          final last = _lastRecenteredPosition;
          final accurateEnough = position.accuracy <= _maxAcceptableAccuracyMeters;
          final moved = accurateEnough &&
              (last == null ||
                  distanceInMeters(last.latitude, last.longitude, point.latitude, point.longitude) >
                      _recenterThresholdMeters);
          if (moved) {
            _lastRecenteredPosition = point;
            _mapController.move(point, _mapController.camera.zoom);
          }
        } else {
          _maybeFitBounds();
        }
      }
    });
  }

  Future<void> _pickUp() async {
    setState(() => _submitting = true);
    try {
      await _api.pickUpOrder(_order.orderId, widget.driverId);
      await _reloadOrder();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _submitting = true);
    try {
      await _api.completeOrder(_order.orderId, widget.driverId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _reloadOrder() async {
    try {
      final active = await _api.getActiveOrder(widget.driverId);
      if (!mounted) return;
      if (active == null) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _order = active);
      await _resolveDestination();
    } catch (_) {
      // fallo silencioso: el proximo ciclo de sondeo lo reintenta
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? _destination ?? const ll.LatLng(tenjoCenterLat, tenjoCenterLng);
    final distance = (_currentPosition != null && _destination != null)
        ? distanceInMeters(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _destination!.latitude,
            _destination!.longitude,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_order.status == OrderStatus.enCamino ? 'Yendo a entregar' : 'Yendo a recoger'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              minZoom: workingAreaMinZoom,
              maxZoom: workingAreaMaxZoom,
              onMapReady: () {
                _mapReady = true;
                _maybeFitBounds();
              },
            ),
            children: [
              TileLayer(urlTemplate: osmTileUrlTemplate),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, color: Colors.deepOrange, strokeWidth: 4),
                  ],
                )
              else if (_currentPosition != null && _destination != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentPosition!, _destination!],
                      color: Colors.deepOrange,
                      strokeWidth: 3,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.navigation, color: Colors.blue, size: 32),
                    ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        _order.status == OrderStatus.enCamino ? Icons.flag : Icons.storefront,
                        color: Colors.deepOrange,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel(distance)),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(double? distance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _order.status == OrderStatus.enCamino
                ? 'Entregar en: ${_order.deliveryAddressText ?? "sin direccion"}'
                    '${_order.recipientName != null ? " (${_order.recipientName})" : ""}'
                : _order.storeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (_resolvingDestination)
            const Text('Buscando la ubicacion en el mapa...', style: TextStyle(color: Colors.grey))
          else if (_destination == null)
            const Text('No se pudo ubicar el destino en el mapa.', style: TextStyle(color: Colors.grey))
          else if (_routeDistanceMeters != null && _routeDurationSeconds != null)
            Text(
              _formatRoute(_routeDistanceMeters!, _routeDurationSeconds!),
              style: const TextStyle(color: Colors.grey),
            )
          else if (distance != null)
            Text(_formatDistance(distance), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_order.status) {
      case OrderStatus.preparando:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Esperando que el restaurante lo prepare', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        );
      case OrderStatus.listo:
        return ElevatedButton(
          onPressed: _submitting ? null : _pickUp,
          child: Text(_submitting ? 'Confirmando...' : 'Recogido, en camino'),
        );
      case OrderStatus.enCamino:
        return ElevatedButton(
          onPressed: _submitting ? null : _complete,
          child: Text(_submitting ? 'Confirmando...' : 'Entregado'),
        );
      case OrderStatus.pendiente:
      case OrderStatus.entregado:
        return const SizedBox.shrink();
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m de distancia';
    return '${(meters / 1000).toStringAsFixed(1)} km de distancia';
  }

  String _formatRoute(double meters, double seconds) {
    final distText = meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
    final minutes = (seconds / 60).ceil();
    return '$distText · $minutes min';
  }
}
