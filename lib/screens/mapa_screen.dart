import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';

const _black = Color(0xFF000000);

/// Mapa y Distancia en vivo para F.U.R.I.
/// Incluye mapa interactivo real (OpenStreetMap/CartoDB) con marcadores
/// de Facu y Rocío, trazado en línea recta con guiones/puntos y cálculo
/// dinámico de distancia en kilómetros.
class MapaScreen extends StatefulWidget {
  final AppMode mode;
  const MapaScreen({super.key, required this.mode});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  bool _updatingGps = false;
  bool _hasFittedCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().load();
    });
  }

  Future<void> _shareLocation() async {
    HapticFeedback.heavyImpact();
    final lpv = context.read<LocationProvider>();
    setState(() => _updatingGps = true);

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF222222),
              content: Text(
                'Por favor activa el GPS / Ubicación en tu teléfono',
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _manualDialog();
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF222222),
              content: Text(
                'Permiso de ubicación denegado. Puedes ingresar tus coordenadas manualmente.',
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _manualDialog();
        return;
      }

      // 1. Obtener última posición conocida de inmediato
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await lpv.updateMyLocation(lastKnown.latitude, lastKnown.longitude);
      }

      // 2. Obtener posición GPS actual refinada (máximo 8s)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      final ok = await lpv.updateMyLocation(pos.latitude, pos.longitude);

      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF39FF14),
            content: Text(
              '¡Ubicación compartida con éxito!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        _fitMapCamera(lpv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF222222),
            content: Text(
              'No se pudo obtener el GPS: $e',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _manualDialog();
    } finally {
      if (mounted) {
        setState(() => _updatingGps = false);
      }
    }
  }

  Future<void> _manualDialog() async {
    final lpv = context.read<LocationProvider>();
    final mine = lpv.effectiveMyLocation;
    final latCtrl = TextEditingController(text: mine.lat.toString());
    final lngCtrl = TextEditingController(text: mine.lng.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        title: const Icon(Icons.my_location, color: Colors.white, size: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitud'),
            ),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitud'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
    );
    final lat = double.tryParse(latCtrl.text);
    final lng = double.tryParse(lngCtrl.text);
    if (ok == true && lat != null && lng != null) {
      await lpv.updateMyLocation(lat, lng);
      _fitMapCamera(lpv);
    }
  }

  void _fitMapCamera(LocationProvider lpv) {
    try {
      final me = lpv.effectiveMyLocation;
      final partner = lpv.effectivePartnerLocation;
      final p1 = LatLng(me.lat, me.lng);
      final p2 = LatLng(partner.lat, partner.lng);

      final bounds = LatLngBounds(p1, p2);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Consumer<LocationProvider>(
      builder: (context, lpv, _) {
        final distance = lpv.coupleDistanceKm;
        final entries = [
          LocaEntry(
            icon: Icons.map,
            color: t.d,
            iconColor: t.dark,
            label: 'Mapa',
            panel: 0,
            swapBuilder: (_) => _distanceSwap(distance),
            autoPlaySwap: true,
          ),
          LocaEntry(
            icon: _updatingGps ? Icons.refresh : Icons.my_location,
            color: t.e,
            label: 'Mi ubicación',
            onTap: _shareLocation,
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 41,
          theme: t,
          entries: entries,
          panels: [(_, close) => _mapPanel(t, close, lpv)],
        );
      },
    );
  }

  Widget _distanceSwap(double distance) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: GoogleFonts.bangers(
                  color: _black,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'DISTANCIA',
                style: GoogleFonts.bangers(
                  color: _black.withValues(alpha: 0.7),
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapPanel(ThemeSet t, VoidCallback close, LocationProvider lpv) {
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

    if (!_hasFittedCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasFittedCamera = true;
        _fitMapCamera(lpv);
      });
    }

    return LocaScreen.panel(
      color: const Color(0xFF141414),
      borderColor: t.d,
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
                    color: t.d,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.map, color: t.dark, size: 20),
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
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerPoint,
                    initialZoom: 8.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Capa de Mapa OpenStreetMap
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.furi.app',
                      maxZoom: 19,
                    ),

                    // Trazado de línea recta con guiones entre ambos
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

                    // Marcadores de ambos usuarios
                    MarkerLayer(
                      markers: [
                        // Marcador de Facu
                        Marker(
                          point: isFacu ? myLatLng : partnerLatLng,
                          width: 80,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: _buildUserMarker(
                            name: 'Facu',
                            color: const Color(0xFFFF5757),
                            icon: Icons.person,
                            isMe: isFacu,
                          ),
                        ),
                        // Marcador de Rocío
                        Marker(
                          point: isFacu ? partnerLatLng : myLatLng,
                          width: 80,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: _buildUserMarker(
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

                // Controles flotantes sobre el mapa (Zoom y recentrar)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Column(
                    children: [
                      _buildMapBtn(
                        icon: Icons.add,
                        onTap: () {
                          final z = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, z + 1);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMapBtn(
                        icon: Icons.remove,
                        onTap: () {
                          final z = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, z - 1);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMapBtn(
                        icon: Icons.crop_free,
                        tooltip: 'Enfocar ambos',
                        onTap: () => _fitMapCamera(lpv),
                      ),
                    ],
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
                  onTap: _shareLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.e,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _updatingGps ? Icons.refresh : Icons.my_location,
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

  Widget _buildUserMarker({
    required String name,
    required Color color,
    required IconData icon,
    required bool isMe,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                name,
                style: GoogleFonts.bangers(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Triángulo apuntando hacia la coordenada exacta
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePointer(color: color),
        ),
      ],
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _TrianglePointer extends CustomPainter {
  final Color color;
  const _TrianglePointer({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointer oldDelegate) =>
      oldDelegate.color != color;
}