import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:furi_app/app_state.dart';
import 'package:furi_app/providers/location_provider.dart';
import 'package:furi_app/theme/app_theme.dart';
import 'package:furi_app/screens/mapa_screen.dart';

void main() {
  setUp(() {
    AppState.identity = 'Facu';
    AppState.myId = LocationProvider.facuId;
    AppState.partnerId = LocationProvider.rocioId;
  });

  test('flutter_map types and API check', () {
    const p1 = LatLng(-27.510067, -56.741267);
    const p2 = LatLng(-27.3671, -55.8961);

    final poly = Polyline(
      points: [p1, p2],
      color: Colors.cyan,
      strokeWidth: 4.0,
      pattern: StrokePattern.dashed(segments: const [10, 8]),
    );
    expect(poly.points.length, 2);

    final polyDotted = Polyline(
      points: [p1, p2],
      color: Colors.cyan,
      strokeWidth: 4.0,
      pattern: const StrokePattern.dotted(),
    );
    expect(polyDotted.points.length, 2);

    final marker1 = Marker(
      point: p1,
      width: 44,
      height: 44,
      child: const Icon(Icons.location_on),
    );
    expect(marker1.point, p1);

    final tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'furi_app',
    );
    expect(tileLayer.urlTemplate, contains('openstreetmap'));

    final bounds = LatLngBounds(p1, p2);
    final fit = CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50));
    expect(fit, isNotNull);

    final options = MapOptions(
      initialCenter: p1,
      initialZoom: 10,
    );
    expect(options.initialCenter, p1);
  });

  test('LocationProvider IDs and effective distance calculation', () {
    final lpv = LocationProvider();
    expect(lpv.myId, LocationProvider.facuId);
    expect(lpv.partnerId, LocationProvider.rocioId);

    // Distance between Ituzaingó (-27.510067, -56.741267) and Posadas (-27.3671, -55.8961)
    expect(lpv.coupleDistanceKm, greaterThan(80));
    expect(lpv.coupleDistanceKm, lessThan(90));

    // When identity is Rocio
    AppState.identity = 'Rocio';
    AppState.myId = null;
    AppState.partnerId = null;
    expect(lpv.myId, LocationProvider.rocioId);
    expect(lpv.partnerId, LocationProvider.facuId);
    expect(lpv.coupleDistanceKm, greaterThan(80));
    expect(lpv.coupleDistanceKm, lessThan(90));
  });

  testWidgets('MapaScreen renders with distance badge and GPS entry', (tester) async {
    final lpv = LocationProvider();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LocationProvider>.value(
          value: lpv,
          child: const MapaScreen(mode: AppMode.dark),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MapaScreen), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.text('Mi ubicación'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });
}
