import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../theme/app_theme.dart';

const _black = Color(0xFF000000);

class MapaScreen extends StatefulWidget {
  final AppMode mode;
  const MapaScreen({super.key, required this.mode});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  double? _distanceKm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  Future<void> _loadDistance() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _distanceKm = 2.3;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return SizedBox(width: w, height: h, child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
              _header(w, h, t),
              _body(w, h, t),
            ],
          ));
        },
      )),
    );
  }

  Widget _header(double w, double h, ThemeSet t) {
    final barH = h * 0.07;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: t.d,
              border: Border.all(color: t.d, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(children: [
          TapTile(
            onTap: () { HapticFeedback.heavyImpact(); Navigator.of(context).pop(); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_back, color: t.dark, size: 28),
            ),
          ),
          Expanded(child: Center(
            child: Text('MAPA', style: TextStyle(color: t.dark, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(width: 50),
        ]),
      ),
    ));
  }

  Widget _body(double w, double h, ThemeSet t) {
    final top = h * 0.07 + h * 0.02;
    final pad = w * 0.04;
    final identity = AppState.identity ?? 'Yo';
    final partner = identity == 'Facu' ? 'Rocio' : 'Facu';

    return Positioned(
      left: pad, top: top, width: w - pad * 2, height: h - top - pad,
      child: Column(children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: t.mid,
          border: Border.all(color: t.d, width: 4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(6, 6), blurRadius: 0)],
              ),
              child: Stack(children: [
                Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.map, color: t.d, size: 80),
                    const SizedBox(height: 12),
                    Text('Mapa en desarrollo', style: TextStyle(color: t.light.withValues(alpha: 0.5), fontFamily: 'monospace', fontSize: 14)),
                  ]),
                ),
                Positioned(
                  top: 20, left: pad,
                  child: Icon(Icons.person_pin, color: t.a, size: 36),
                ),
                Positioned(
                  bottom: 20, right: pad,
                  child: Icon(Icons.person_pin, color: t.e, size: 36),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.d,
              border: Border.all(color: _black, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Column(children: [
              Text('Distancia entre $identity y $partner', style: TextStyle(color: t.dark, fontFamily: 'monospace', fontSize: 12)),
              const SizedBox(height: 8),
              if (_loading)
                CircularProgressIndicator(color: t.dark)
              else ...[
                Text('${_distanceKm?.toStringAsFixed(1) ?? '--'} km', style: TextStyle(color: t.dark, fontFamily: 'monospace', fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.location_on, color: t.e, size: 20),
                  const SizedBox(width: 4),
                  Text(identity, style: TextStyle(color: t.dark, fontFamily: 'monospace', fontSize: 13)),
                  const SizedBox(width: 20),
                  Container(width: 60, height: 3, color: t.dark),
                  const SizedBox(width: 20),
                  Icon(Icons.location_on, color: t.a, size: 20),
                  const SizedBox(width: 4),
                  Text(partner, style: TextStyle(color: t.dark, fontFamily: 'monospace', fontSize: 13)),
                ]),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 12),
        TapTile(
          onTap: () { HapticFeedback.heavyImpact(); _loadDistance(); },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: t.e,
                border: Border.all(color: t.e, width: 4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
              ),
              child: Center(child: Text('Actualizar ubicacion', style: TextStyle(color: t.light, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ]),
    );
  }
}
