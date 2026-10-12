import 'dart:math' as math;

/// Jarak dua titik di permukaan bumi (rumus haversine), dalam meter.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000;
  final double dLat = _rad(lat2 - lat1);
  final double dLon = _rad(lon2 - lon1);
  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(a)));
}

double _rad(double degrees) => degrees * math.pi / 180;