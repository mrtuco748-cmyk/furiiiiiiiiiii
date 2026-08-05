import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppMode mode;
  const SettingsScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final t = appThemes[mode]!;
    return Scaffold(
      backgroundColor: t.dark,
      body: ResponsiveWrapper(builder: (context, w, h) {
          return SizedBox(width: w, height: h, child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
            _header(w, h, t, context),
            _sessionBlock(w, h, t, context),
            _soundBlock(w, h, t),
          ]));
        },
      ),
    );
  }

  Widget _header(double w, double h, ThemeSet t, BuildContext context) {
    return Positioned(left: w * 0.03, top: h * 0.01, width: w * 0.94, height: h * 0.07,
      child: ClipRRect(borderRadius: BorderRadius.circular(18),
        child: Container(decoration: BoxDecoration(color: t.a, border: Border.all(color: t.a, width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
          child: Row(children: [
            TapTile(onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(context); }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_back, color: t.light, size: 28))),
            Expanded(child: Center(child: Text('AJUSTES', style: TextStyle(color: t.light, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 18)))),
            const SizedBox(width: 48),
          ]),
        ),
      ),
    );
  }

  Widget _sessionBlock(double w, double h, ThemeSet t, BuildContext context) {
    return Positioned(left: w * 0.05, top: h * 0.20, width: w * 0.90, height: h * 0.12,
      child: TapTile(
        onTap: () async {
          HapticFeedback.heavyImpact();
          await AppState.clearSession();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          }
        },
        child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Container(decoration: BoxDecoration(color: const Color(0xFFFF5757), border: Border.all(color: const Color(0xFFFF5757), width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.swap_horiz, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Text('Cambiar sesión', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _soundBlock(double w, double h, ThemeSet t) {
    return Positioned(left: w * 0.05, top: h * 0.35, width: w * 0.90, height: h * 0.12,
      child: ClipRRect(borderRadius: BorderRadius.circular(18),
        child: Container(decoration: BoxDecoration(color: t.mid, border: Border.all(color: t.mid, width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.volume_up, color: t.light, size: 30),
            const SizedBox(width: 12),
            Text('Sonidos activados', style: TextStyle(color: t.light, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}
