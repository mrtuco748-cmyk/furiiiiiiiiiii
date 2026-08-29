import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _autoPlaySwap = false; // Swap desactivado por defecto en brutalista
    _blockWeight = 1.0; // Peso base para bloques
  }

  @override
  Widget build(BuildContext context) {
    final t = appThemes[widget.mode]!;
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
          // Cycle through AppMode values
          final current = widget.mode;
          final all = AppMode.values;
          final nextIdx = all.indexOf(current) + 1;
          final nextMode = nextIdx < all.length ? all[nextIdx] : AppMode.values.first;
          if (context.mounted) {
            context.goNamed(
              RouterRoutes.settings,
              extra: nextMode,
            );
          }
        },
      ),
      // Volumen música (controlado por SettingsService bgVolume)
      LocaEntry(
        icon: Icons.volume_up,
        color: t.c,
        label: 'Vol. Música',
        onTap: () {},
        // Note: volumen se ajusta en SettingsService y se refleja en el mosaico
      ),
      // Volumen SFX (controlado por SettingsService sfxVolume)
      LocaEntry(
        icon: Icons.volume_up,
        color: t.d,
        label: 'Vol. Efectos',
        onTap: () {},
      ),
      // Haptics toggle: siempre activado por regla brutalista,
      // pero con interruptor guardado para preferencia del usuario
      LocaEntry(
        icon: Icons.volume_off,
        color: t.e,
        label: _buildHapticsLabel(),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _autoPlaySwap = !_autoPlaySwap;
          });
          // Guardar preferencia: setEnableSound alterna el sonido global
          // Las haptics siguen siempre activadas en la app brutalista
          SettingsService().setEnableSound(!SettingsService().enableSound);
        },
      ),
      // Mutear categorías de notificación (bot WhatsApp)
      LocaEntry(
        icon: Icons.notifications_none,
        color: t.b,
        label: 'Notif. Tareas',
        onTap: () {
          HapticFeedback.lightImpact();
        },
      ),
      LocaEntry(
        icon: Icons.favorite,
        color: t.e,
        label: 'Notif. Favoritos',
        onTap: () {
          HapticFeedback.lightImpact();
        },
      ),
      // Modo Zen: ocultar balances/rachas de la vista
      LocaEntry(
        icon: Icons.zoom_out,
        color: t.a,
        label: 'Modo Zen',
        onTap: () {
          HapticFeedback.lightImpact();
          // Logic to hide balances/streaks would go here
        },
      ),
      // Atajos rápidos configurables
      LocaEntry(
        icon: Icons.menu_book,
        color: t.d,
        label: 'Atajos rápidos',
        onTap: () {
          HapticFeedback.lightImpact();
        },
      ),
      // --- NUEVA OPCIÓN: Velocidad de swap ---
      LocaEntry(
        icon: _autoPlaySwap ? Icons.stop : Icons.autorenew,
        color: t.c,
        label: _autoPlaySwap ? 'Swap desactivado' : 'Swap automático',
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _autoPlaySwap = !_autoPlaySwap;
          });
        },
        autoPlaySwap: _autoPlaySwap,
        iconDuration: Duration(milliseconds: _autoPlaySwap ? 200 : 700),
        swapDuration: Duration(milliseconds: _autoPlaySwap ? 200 : 700),
      ),
      // --- NUEVA OPCIÓN: Peso de bloques (tamaño) ---
      // Usa el parámetro 'weight' de LocaEntry: más texto = bloque más grande
      LocaEntry(
        icon: Icons.format_size,
        color: t.d,
        label: 'Tamaño bloque: $_blockWeight',
        onTap: () {
          HapticFeedback.lightImpact();
          // Cycle weight values: 0.5, 1.0, 1.5, 2.0
          setState(() {
            _blockWeight = _blockWeight >= 2.0 ? 0.5 : _blockWeight + 0.5;
          });
        },
        // El peso afecta: label largo → bloque más grande
        // Valores: 0.5 (pequeño), 1.0 (normal), 1.5 (grande), 2.0 (muy grande)
      ),
    ];
    return LocaScreen(seed: 43, theme: t, entries: entries);
  }

  // Helper para label de haptics basado en estado actual
  String _buildHapticsLabel() {
    // Las haptics siempre están on en F.U.R.i brutalista;
    // el toggle guarda preferencia pero no las desactiva nunca.
    return SettingsService().enableSound ? 'Háptics on' : 'Háptics off';
  }
}