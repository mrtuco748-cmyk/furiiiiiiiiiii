import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../services/notification_service.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import 'home_screen.dart';

const _red = Color(0xFFFF5757);
const _purple = Color(0xFF7000FF);
const _dark = Color(0xFF000000);

Widget fillIcon(IconData icon, Color color) {
  return FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          ResponsiveWrapper(builder: (context, w, h) {
              return SizedBox(width: w, height: h, child: Stack(children: [
                _titleBlock(w, h),
                _facuBlock(context, w, h),
                _rocioBlock(context, w, h),
              ]));
            },
          ),
        ],
      ),
    );
  }

  Widget _titleBlock(double w, double h) {
    return Positioned(
      left: w * 0.15, top: h * 0.10, width: w * 0.70, height: h * 0.10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _dark,
            border: Border.all(color: _dark, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: Center(child: Text('¿Quién eres?', style: GoogleFonts.bangers(color: Colors.white, fontSize: w * 0.06, fontWeight: FontWeight.w900))),
        ),
      ),
    );
  }

  Widget _facuBlock(BuildContext context, double w, double h) {
    return Positioned(
      left: w * 0.10, top: h * 0.30, width: w * 0.35, height: h * 0.35,
      child: TapTile(
        onTap: () => _login(context, 'Facu'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: _red,
              border: Border.all(color: _red, width: 5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(8, 8), blurRadius: 0)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person, color: Colors.white, size: 80),
              const SizedBox(height: 12),
              Text('Facu', style: GoogleFonts.bangers(color: Colors.white, fontSize: w * 0.05, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _rocioBlock(BuildContext context, double w, double h) {
    return Positioned(
      left: w * 0.55, top: h * 0.30, width: w * 0.35, height: h * 0.35,
      child: TapTile(
        onTap: () => _login(context, 'Rocio'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: _purple,
              border: Border.all(color: _purple, width: 5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(8, 8), blurRadius: 0)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person, color: Colors.white, size: 80),
              const SizedBox(height: 12),
              Text('Rocio', style: GoogleFonts.bangers(color: Colors.white, fontSize: w * 0.05, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context, String identity) async {
    HapticFeedback.heavyImpact();
    AppState.identity = identity;
    try {
      final res = await SupabaseConfig.client
          .from('profiles')
          .select('id, name, partner_id')
          .eq('name', identity)
          .maybeSingle();
      if (res != null) {
        AppState.myId = res['id'] as String;
        AppState.myName = res['name'] as String;
        AppState.partnerId = res['partner_id'] as String?;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    if (AppState.myId == null) {
      await AppState.loadSession();
    }
    await AppState.saveSession();
    NotificationService.registerTokenAfterLogin();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}
