import 'dart:math';

const tenjoCenterLat = 4.8672;
const tenjoCenterLng = -74.1447;
const maxDeliveryRadiusMeters = 3000;

// Zoom por debajo del cual el mapa mostraria mas alla del radio de cobertura + 3 km de margen.
const workingAreaMinZoom = 14.0;

// Zoom mas alla del cual las calles ya no se distinguen mejor, solo se acerca de mas.
const workingAreaMaxZoom = 18.0;

// Sin {s}: OSM ya no reparte por subdominio, y usarlo rompe la cache de tiles precargados.
const osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Convierte coordenadas a la tile "slippy map" que las contiene, para un zoom dado.
({int x, int y}) latLngToTile(double lat, double lng, int zoom) {
  final n = (1 << zoom).toDouble();
  final x = ((lng + 180) / 360 * n).floor();
  final latRad = _degToRad(lat);
  final tanLat = tan(latRad);
  final asinhValue = log(tanLat + sqrt(tanLat * tanLat + 1));
  final y = ((1 - asinhValue / pi) / 2 * n).floor();
  return (x: x, y: y);
}

String osmTileUrl({required int x, required int y, required int zoom}) => osmTileUrlTemplate
    .replaceAll('{z}', '$zoom')
    .replaceAll('{x}', '$x')
    .replaceAll('{y}', '$y');

double distanceInMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusMeters * c;
}

bool isWithinDeliveryArea(double lat, double lng) {
  return distanceInMeters(tenjoCenterLat, tenjoCenterLng, lat, lng) <= maxDeliveryRadiusMeters;
}

double _degToRad(double deg) => deg * pi / 180;
