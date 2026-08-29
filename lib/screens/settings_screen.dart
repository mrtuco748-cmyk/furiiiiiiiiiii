import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../router.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';

/// Configuración estilo "Nosotros": botones-icono gigantes (cambiar sesión /
/// sonido + personalización visual) en mosaico, sin texto a simple vista.
class SettingsScreen extends StatefulWidget {
  final AppMode mode;
  const SettingsScreen({super.key, required this.mode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlaySwap = false;
  double _blockWeight = 1.0;
  bool _zenMode = false;
  double _bgVolume = 0.5;
  double _sfxVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _autoPlaySwap = Provider.of<SettingsService>(context, listen: false).autoPlaySwap;
    _blockWeight = 1.0;
    _zenMode = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = appThemes[widget.mode]!;
    final settings = context.watch<SettingsService>();
    final entries = [
      // Cambiar sesión
      LocaEntry(
        icon: Icons.swap_horiz,
        color: const Color(0xFFFF5757),
        label: 'Cambiar sesión',
        onTap: () async {
          HapticFeedback.heavyImpact();
          await AppState.clearSession();
          if (context.mounted) context.go(RouterRoutes.login);
        },
      ),
      // Selector de tema: ciclo por modos F.U.R.I
      LocaEntry(
        icon: Icons.palette,
        color: t.a,
        label: 'Tema',
        onTap: () {
          final current = widget.mode;
          final all = AppMode.values;
          final nextIdx = all.indexOf(current) + 1;
          final nextMode = nextIdx < all.length ? all[nextIdx] : AppMode.values.first;
          if (context.mounted) {
            context.goNamed(RouterRoutes.settings, extra: nextMode);
          }
        },
      ),
      // Volumen música (toggle between 0.0 and 1.0)
      LocaEntry(
        icon: Icons.volume_up,
        color: t.c,
        label: 'Vol. Música: ${settings.bgVolume.toStringAsFixed(1)}',
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _bgVolume = settings.bgVolume <= 0.3 ? 0.5 : 0.0;
          });
          settings.setBgVolume(_bgVolume);
        },
      ),
      // Volumen SFX (toggle between 0.0 and 1.0)
      LocaEntry(
        icon: Icons.volume_up,
        color: t.d,
        label: 'Vol. Efectos: ${settings.sfxVolume.toStringAsFixed(1)}',
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _sfxVolume = settings.sfxVolume <= 0.3 ? 1.0 : 0.0;
          });
          settings.setSfxVolume(_sfxVolume);
        },
      ),
      // Háptics / sonido toggle
      LocaEntry(
        icon: Icons.volume_off,
        color: t.e,
        label: settings.enableSound ? 'Háptics on' : 'Háptics off',
        onTap: () {
          HapticFeedback.lightImpact();
          settings.setEnableSound(!settings.enableSound);
        },
      ),
      // Notificaciones de tareas → pantalla de notificaciones
      LocaEntry(
        icon: Icons.notifications_none,
        color: t.b,
        label: 'Notif. Tareas',
        onTap: () {
          HapticFeedback.lightImpact();
          if (context.mounted) context.push(RouterRoutes.notifications);
        },
      ),
      // Notificaciones de favoritos → pantalla de favoritos
      LocaEntry(
        icon: Icons.favorite,
        color: t.e,
        label: 'Notif. Favoritos',
        onTap: () {
          HapticFeedback.lightImpact();
          if (context.mounted) context.push(RouterRoutes.favoritos);
        },
      ),
      // Modo Zen: ocultar balances/rachas
      LocaEntry(
        icon: Icons.zoom_out,
        color: t.a,
        label: _zenMode ? 'Zen ON' : 'Modo Zen',
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _zenMode = !_zenMode;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_zenMode ? 'Modo Zen activado' : 'Modo Zen desactivado',
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
              backgroundColor: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
      // Swap automático
      LocaEntry(
        icon: _autoPlaySwap ? Icons.stop : Icons.autorenew,
        color: t.c,
        label: _autoPlaySwap ? 'Swap desactivado' : 'Swap automático',
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _autoPlaySwap = !_autoPlaySwap;
          });
          settings.setAutoPlaySwap(_autoPlaySwap);
        },
        autoPlaySwap: _autoPlaySwap,
        iconDuration: Duration(milliseconds: _autoPlaySwap ? 200 : 700),
        swapDuration: Duration(milliseconds: _autoPlaySwap ? 200 : 700),
      ),
      // Tamaño de bloques
      LocaEntry(
        icon: Icons.format_size,
        color: t.d,
        label: 'Tamaño bloque: $_blockWeight',
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _blockWeight = _blockWeight >= 2.0 ? 0.5 : _blockWeight + 0.5;
          });
        },
      ),
    ];
    return LocaScreen(seed: 43, theme: t, entries: entries);
  }
}