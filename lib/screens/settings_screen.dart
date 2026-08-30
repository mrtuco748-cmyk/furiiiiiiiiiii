import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
      // Selector de tema: ciclo por modos F.U.R.I + persistencia
      LocaEntry(
        icon: Icons.palette,
        color: t.a,
        label: 'Tema: ${widget.mode.name}',
        onTap: () {
          HapticFeedback.heavyImpact();
          final current = widget.mode;
          final all = AppMode.values;
          final nextIdx = all.indexOf(current) + 1;
          final nextMode = nextIdx < all.length ? all[nextIdx] : AppMode.values.first;
          settings.setAppMode(nextMode);
          if (context.mounted) {
            context.goNamed(RouterRoutes.settings, extra: nextMode);
          }
        },
      ),
      // Volumen música (cicla entre 0.0 / 0.5 / 1.0)
      LocaEntry(
        icon: Icons.volume_up,
        color: t.c,
        label: 'Vol. Música: ${settings.bgVolume.toStringAsFixed(1)}',
        onTap: () {
          HapticFeedback.lightImpact();
          final next = settings.bgVolume <= 0.1 ? 0.5
              : settings.bgVolume <= 0.5 ? 1.0 : 0.0;
          settings.setBgVolume(next);
        },
      ),
      // Volumen efectos (cicla entre 0.0 / 0.5 / 1.0)
      LocaEntry(
        icon: Icons.record_voice_over,
        color: t.d,
        label: 'Vol. Efectos: ${settings.sfxVolume.toStringAsFixed(1)}',
        onTap: () {
          HapticFeedback.lightImpact();
          final next = settings.sfxVolume <= 0.1 ? 0.5
              : settings.sfxVolume <= 0.5 ? 1.0 : 0.0;
          settings.setSfxVolume(next);
        },
      ),
      // Sonidos on/off (persistido)
      LocaEntry(
        icon: settings.enableSound ? Icons.volume_up : Icons.volume_off,
        color: t.e,
        label: settings.enableSound ? 'Sonidos on' : 'Sonidos off',
        onTap: () {
          HapticFeedback.lightImpact();
          settings.setEnableSound(!settings.enableSound);
        },
      ),
      // Notificaciones → pantalla de notificaciones
      LocaEntry(
        icon: Icons.notifications_none,
        color: t.b,
        label: 'Notificaciones',
        onTap: () {
          HapticFeedback.lightImpact();
          if (context.mounted) context.push(RouterRoutes.notifications);
        },
      ),
      // Favoritos → pantalla de favoritos
      LocaEntry(
        icon: Icons.favorite,
        color: t.e,
        label: 'Favoritos',
        onTap: () {
          HapticFeedback.lightImpact();
          if (context.mounted) context.push(RouterRoutes.favoritos);
        },
      ),
      // Modo Zen: ocultar balances/rachas (persistido)
      LocaEntry(
        icon: settings.zenMode ? Icons.zoom_in : Icons.zoom_out,
        color: t.a,
        label: settings.zenMode ? 'Zen ON' : 'Modo Zen',
        onTap: () {
          HapticFeedback.heavyImpact();
          settings.setZenMode(!settings.zenMode);
        },
      ),
      // Swap automático (persistido)
      LocaEntry(
        icon: settings.autoPlaySwap ? Icons.stop : Icons.autorenew,
        color: t.c,
        label: settings.autoPlaySwap ? 'Swap auto ON' : 'Swap automático',
        onTap: () {
          HapticFeedback.lightImpact();
          settings.setAutoPlaySwap(!settings.autoPlaySwap);
        },
        autoPlaySwap: settings.autoPlaySwap,
        iconDuration: Duration(milliseconds: settings.autoPlaySwap ? 200 : 700),
        swapDuration: Duration(milliseconds: settings.autoPlaySwap ? 200 : 700),
      ),
      // Tamaño de bloques (persistido)
      LocaEntry(
        icon: Icons.format_size,
        color: t.d,
        label: 'Bloques: ${settings.blockWeight.toStringAsFixed(1)}',
        onTap: () {
          HapticFeedback.lightImpact();
          final next = settings.blockWeight >= 1.8 ? 0.5 : settings.blockWeight + 0.5;
          settings.setBlockWeight(next);
        },
      ),
    ];
    return LocaScreen(
      seed: 43,
      theme: t,
      entries: entries,
      blockWeight: settings.blockWeight,
    );
  }
}
