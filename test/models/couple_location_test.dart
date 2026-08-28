import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/couple_location.dart';

void main() {
  group('distanceKm (haversine)', () {
    test('la misma ubicación da 0 km', () {
      expect(distanceKm(-34.6, -58.4, -34.6, -58.4), closeTo(0, 0.001));
    });

    test('Buenos Aires → Córdoba ≈ 647 km (línea recta)', () {
      final d = distanceKm(-34.6037, -58.3816, -31.4201, -64.1888);
      expect(d, greaterThan(630));
      expect(d, lessThan(665));
    });

    test('falta una ubicación → 0', () {
      expect(distanceKm(null, -58.4, -31.4, -64.2), 0);
      expect(distanceKm(-34.6, -58.4, null, null), 0);
    });
  });

  group('CoupleLocation', () {
    test('fromMap/toMap round-trip', () {
      final l = CoupleLocation(userId: 'facu-uuid', lat: -34.6, lng: -58.4);
      final m = l.toMap();
      final back = CoupleLocation.fromMap(m);
      expect(back.userId, 'facu-uuid');
      expect(back.lat, -34.6);
      expect(back.lng, -58.4);
    });

    test('tolerante a una fecha ausente', () {
      final l = CoupleLocation.fromMap({'user_id': 'x', 'lat': 1, 'lng': 2});
      expect(l.updatedAt, isNull);
    });
  });
}