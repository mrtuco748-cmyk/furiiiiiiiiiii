import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';
import '../router.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';

/// Configuración estilo "Nosotros": botones-icono gigantes (cambiar sesión /
/// sonido) en mosaico, sin texto a simple vista.
class SettingsScreen extends StatefulWidget {
  final AppMode mode;
  const SettingsScreen({super.key, required this.mode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundOn;

  @override
  void initState() {
    super.initState();
    _soundOn = SettingsService().enableSound;
  }

  @override
  Widget build(BuildContext context) {
    final t = appThemes[widget.mode]!;
    final entries = [
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
      LocaEntry(
        icon: _soundOn ? Icons.volume_up : Icons.volume_off,
        color: t.mid,
        iconColor: t.light,
        label: _soundOn ? 'Sonido encendido' : 'Sonido apagado',
        swapBuilder: (context) => Center(
          child: Icon(
            _soundOn ? Icons.volume_up : Icons.volume_off,
            color: t.light,
            size: 56,
          ),
        ),
        autoPlaySwap: false,
        onTap: () async {
          HapticFeedback.heavyImpact();
          _soundOn = !_soundOn;
          await SettingsService().setEnableSound(_soundOn);
          if (mounted) setState(() {});
          if (_soundOn) {
            SoundService().success();
            SoundService().startBackgroundMusic();
          } else {
            SoundService().stopBackgroundMusic();
          }
        },
      ),
    ];
    return LocaScreen(seed: 43, theme: t, entries: entries);
  }
}