import 'dart:math';

/// Ubicación (última conocida) de un miembro de la pareja, persistida en
/// Supabase `couple_locations` con realtime.
class CoupleLocation {
  final String userId;
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  const CoupleLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        if (updatedAt != null)
          'updated_at': updatedAt!.toUtc().toIso8601String(),
      };

  factory CoupleLocation.fromMap(Map<String, dynamic> m) {
    final lat = m['lat'];
    final lng = m['lng'];
    return CoupleLocation(
      userId: m['user_id']?.toString() ?? '',
      lat: lat is num ? lat.toDouble() : 0,
      lng: lng is num ? lng.toDouble() : 0,
      updatedAt: m['updated_at'] is String
          ? DateTime.tryParse(m['updated_at'] as String)
          : null,
    );
  }
}

/// Distancia en kilómetros entre dos coordenadas (fórmula de haversine).
/// Valor 0 cuando falta una de las ubicaciones.
double distanceKm(num? lat1, num? lng1, num? lat2, num? lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return 0;
  const double r = 6371.0; // radio medio de la Tierra en km.
  final dLat = _rad(lat2.toDouble() - lat1.toDouble());
  final dLng = _rad(lng2.toDouble() - lng1.toDouble());
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1.toDouble())) *
          cos(_rad(lat2.toDouble())) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * pi / 180;