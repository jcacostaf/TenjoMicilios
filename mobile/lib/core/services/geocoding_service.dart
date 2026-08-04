import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

class GeocodingService {
  Future<String?> suggestAddress(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$latitude&lon=$longitude&addressdetails=1&zoom=18',
    );

    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'TenjoMicilios/1.0'},
      );
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<ll.LatLng?> geocodeAddress(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=json&limit=1&q=${Uri.encodeQueryComponent('$query, Tenjo, Cundinamarca, Colombia')}',
    );

    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'TenjoMicilios/1.0'},
      );
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as List<dynamic>;
      if (data.isEmpty) return null;

      final result = data.first as Map<String, dynamic>;
      final lat = double.tryParse(result['lat'] as String);
      final lon = double.tryParse(result['lon'] as String);
      if (lat == null || lon == null) return null;
      return ll.LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }
}
