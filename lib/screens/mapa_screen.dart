import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';

const _black = Color(0xFF000000);

/// Mapa/Distancia estilo "Nosotros": botón-icono gigante de mapa que swapea a
/// la distancia en vivo y abre un panel con el detalle; botón GPS para
/// actualizar la propia ubicación.
class MapaScreen extends StatefulWidget {
  final AppMode mode;
  const MapaScreen({super.key, required this.mode});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
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
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _manualDialog();
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      await lpv.updateMyLocation(pos.latitude, pos.longitude);
    } catch (e) {
      _manualDialog();
    }
  }

  Future<void> _manualDialog() async {
    final lpv = context.read<LocationProvider>();
    final mine = lpv.myLocation;
    final latCtrl = TextEditingController(text: mine?.lat.toString() ?? '');
    final lngCtrl = TextEditingController(text: mine?.lng.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Consumer<LocationProvider>(
      builder: (context, lpv, _) {
        final hasData = lpv.myLocation != null && lpv.partnerLocation != null;
        final distance = lpv.coupleDistanceKm;
        final entries = [
          LocaEntry(
            icon: Icons.map,
            color: t.d,
            iconColor: t.dark,
            label: 'Distancia',
            panel: 0,
            swapBuilder: hasData ? (_) => _distanceSwap(distance) : null,
            autoPlaySwap: hasData,
          ),
          LocaEntry(
            icon: Icons.my_location,
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
        child: Text('${distance.toStringAsFixed(1)} km',
          style: GoogleFonts.bangers(color: _black, fontSize: 48, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _mapPanel(ThemeSet t, VoidCallback close, LocationProvider lpv) {
    final identity = AppState.identity ?? 'Yo';
    final partner = identity == 'Facu' ? 'Rocio' : 'Facu';
    final hasData = lpv.myLocation != null && lpv.partnerLocation != null;
    final distance = lpv.coupleDistanceKm;
    final me = lpv.myLocation;
    final p2 = lpv.partnerLocation;
    return LocaScreen.panel(color: t.mid, borderColor: t.d, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.map, color: t.d, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, t.d, Icons.close),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(hasData ? '$identity y $partner conectados' : 'Comparti tu ubicacion para ver la distancia',
            style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.6), fontSize: 13)),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(children: [
            Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.map, color: t.d.withValues(alpha: 0.5), size: 90),
                const SizedBox(height: 10),
                Text(hasData ? '${distance.toStringAsFixed(1)} km' : '-- km',
                  style: GoogleFonts.bangers(fontWeight: FontWeight.w900, color: t.light, fontSize: 40)),
              ]),
            ),
            if (me != null) Positioned(top: 12, left: 8, child: Icon(Icons.person_pin, color: t.a, size: 34)),
            if (p2 != null) Positioned(bottom: 12, right: 8, child: Icon(Icons.person_pin, color: t.e, size: 34)),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_on, color: t.e, size: 20),
          const SizedBox(width: 4),
          Text(identity, style: GoogleFonts.bangers(color: t.light, fontSize: 14)),
          const SizedBox(width: 20),
          Container(width: 60, height: 3, color: t.d),
          const SizedBox(width: 20),
          Icon(Icons.location_on, color: t.a, size: 20),
          const SizedBox(width: 4),
          Text(partner, style: GoogleFonts.bangers(color: t.light, fontSize: 14)),
        ]),
      ),
      if (!hasData)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            me == null ? 'Tu ubicacion no esta compartida' : 'La pareja aun no compartio ubicacion',
            style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.6), fontSize: 11)),
        ),
    ]));
  }
}