import 'dart:convert';
import 'package:http/http.dart' as http;

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
}
