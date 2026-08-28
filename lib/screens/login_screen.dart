import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../router.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';

const _loginTheme = ThemeSet(
  a: Color(0xFFFF5757),
  b: Color(0xFF7000FF),
  c: Color(0xFFFFFFFF),
  d: Color(0xFF7000FF),
  e: Color(0xFFFF5757),
  dark: Color(0xFF0A0A0A),
  light: Color(0xFFFFFFFF),
  mid: Color(0xFF1A1A1A),
);

/// Login estilo "Nosotros": dos bloques-icono gigantes (Facu rojo / Rocio
/// violeta) que ocupan toda la pantalla; sin texto a simple vista.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      LocaEntry(
        icon: Icons.favorite,
        color: const Color(0xFFFF5757),
        label: 'Facu',
        onTapAsync: (context) => _login(context, 'Facu'),
      ),
      LocaEntry(
        icon: Icons.local_florist,
        color: const Color(0xFF7000FF),
        label: 'Rocio',
        onTapAsync: (context) => _login(context, 'Rocio'),
      ),
    ];
    return LocaScreen(
      seed: 5,
      theme: _loginTheme,
      entries: entries,
      showBack: false,
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
      context.go(RouterRoutes.home);
    }
  }
}