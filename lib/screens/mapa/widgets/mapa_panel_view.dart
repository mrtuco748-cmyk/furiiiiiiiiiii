import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../app_state.dart';
import '../../../providers/location_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/loca_screen.dart';
import 'map_controls.dart';
import 'map_marker.dart';

class MapaPanelView extends StatelessWidget {
  final ThemeSet theme;
  final VoidCallback close;
  final LocationProvider lpv;
  final MapController mapController;
  final bool updatingGps;
  final VoidCallback onShareLocation;
  final VoidCallback onFitMapCamera;

  const MapaPanelView({
    super.key,
    required this.theme,
    required this.close,
    required this.lpv,
    required this.mapController,
    required this.updatingGps,
    required this.onShareLocation,
    required this.onFitMapCamera,
  });

  @override
  Widget build(BuildContext context) {
    final identity = AppState.identity ?? 'Facu';
    final isFacu = identity == 'Facu';
    final partnerName = isFacu ? 'Rocio' : 'Facu';

    final me = lpv.effectiveMyLocation;
    final partner = lpv.effectivePartnerLocation;
    final distance = lpv.coupleDistanceKm;

    final myLatLng = LatLng(me.lat, me.lng);
    final partnerLatLng = LatLng(partner.lat, partner.lng);

    final centerLat = (me.lat + partner.lat) / 2;
    final centerLng = (me.lng + partner.lng) / 2;
    final centerPoint = LatLng(centerLat, centerLng);

    return LocaScreen.panel(
      color: const Color(0xFF141414),
      borderColor: theme.d,
      child: Column(
        children: [
          // Header del Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.d,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.map, color: theme.dark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${distance.toStringAsFixed(1)} KM DE DISTANCIA',
                        style: GoogleFonts.bangers(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Línea recta entre $identity y $partnerName',
                        style: GoogleFonts.bangers(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                LocaScreen.closeIcon(close, Colors.white, Icons.close),
              ],
            ),
          ),

          // Mapa Interactivo Real
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: centerPoint,
                    initialZoom: 8.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.furi.app',
                      maxZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [myLatLng, partnerLatLng],
                          color: const Color(0xFF00D4FF),
                          strokeWidth: 4.5,
                          pattern: StrokePattern.dashed(
                            segments: const [12, 8],
                          ),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: isFacu ? myLatLng : partnerLatLng,
                          width: 80,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: UserMapMarker(
                            name: 'Facu',
                            color: const Color(0xFFFF5757),
                            icon: Icons.person,
                            isMe: isFacu,
                          ),
                        ),
                        Marker(
                          point: isFacu ? partnerLatLng : myLatLng,
                          width: 80,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: UserMapMarker(
                            name: 'Rocio',
                            color: const Color(0xFF7000FF),
                            icon: Icons.favorite,
                            isMe: !isFacu,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: MapZoomControls(
                    onZoomIn: () {
                      final z = mapController.camera.zoom;
                      mapController.move(mapController.camera.center, z + 1);
                    },
                    onZoomOut: () {
                      final z = mapController.camera.zoom;
                      mapController.move(mapController.camera.center, z - 1);
                    },
                    onFitBounds: onFitMapCamera,
                  ),
                ),
              ],
            ),
          ),

          // Barra Inferior con detalles de coordenadas y botón GPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF39FF14),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tu ubicación: ${me.lat.toStringAsFixed(4)}, ${me.lng.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pareja: ${partner.lat.toStringAsFixed(4)}, ${partner.lng.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onShareLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.e,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          updatingGps ? Icons.refresh : Icons.my_location,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Actualizar GPS',
                          style: GoogleFonts.bangers(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
