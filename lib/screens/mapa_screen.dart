import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';
import 'mapa/widgets/manual_location_dialog.dart';
import 'mapa/widgets/mapa_panel_view.dart';

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
        _openManualDialog();
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
        _openManualDialog();
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await lpv.updateMyLocation(lastKnown.latitude, lastKnown.longitude);
      }

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
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
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
      _openManualDialog();
    } finally {
      if (mounted) {
        setState(() => _updatingGps = false);
      }
    }
  }

  void _openManualDialog() {
    ManualLocationDialog.show(
      context,
      context.read<LocationProvider>(),
      () => _fitMapCamera(context.read<LocationProvider>()),
    );
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

        if (!_hasFittedCamera) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _hasFittedCamera = true;
            _fitMapCamera(lpv);
          });
        }

        return LocaScreen(
          seed: 41,
          theme: t,
          entries: entries,
          panels: [
            (_, close) => MapaPanelView(
                  theme: t,
                  close: close,
                  lpv: lpv,
                  mapController: _mapController,
                  updatingGps: _updatingGps,
                  onShareLocation: _shareLocation,
                  onFitMapCamera: () => _fitMapCamera(lpv),
                ),
          ],
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
}
