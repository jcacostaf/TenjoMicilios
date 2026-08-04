import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

class RouteResult {
  final List<ll.LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RouteResult({required this.points, required this.distanceMeters, required this.durationSeconds});
}

class RoutingService {
  Future<RouteResult?> getRoute(ll.LatLng from, ll.LatLng to) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = (geometry['coordinates'] as List<dynamic>)
          .map((c) => ll.LatLng(((c as List<dynamic>)[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      return RouteResult(
        points: coords,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
