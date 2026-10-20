import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../router.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';
import '../widgets/theme_color_customizer_sheet.dart';
import 'settings/helpers/settings_avatar_helper.dart';
import 'settings/widgets/settings_music_volume_sheet.dart';

/// Configuración estilo "Nosotros": botones-icono gigantes (cambiar sesión /
/// sonido + personalización visual) en mosaico, sin texto a simple vista.
class SettingsScreen extends StatelessWidget {
  final AppMode mode;
  const SettingsScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final t = getTheme(mode);
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
      // Foto de perfil
      LocaEntry(
        icon: Icons.account_circle,
        color: const Color(0xFF00D4FF),
        label: 'Foto de perfil',
        onTap: () {
          HapticFeedback.lightImpact();
          SettingsAvatarHelper.pickAndSetAvatar(context);
        },
      ),
      // Selector de tema: ciclo por modos F.U.R.I + persistencia
      LocaEntry(
        icon: Icons.palette,
        color: t.a,
        label: 'Tema: ${mode.name}',
        onTap: () {
          HapticFeedback.heavyImpact();
          final current = mode;
          final all = AppMode.values;
          final nextIdx = all.indexOf(current) + 1;
          final nextMode =
              nextIdx < all.length ? all[nextIdx] : AppMode.values.first;
          settings.setAppMode(nextMode);
          if (context.mounted) {
            context.go(RouterRoutes.settings, extra: nextMode);
          }
        },
      ),
      // Personalizar colores de cada bloque por tema
      LocaEntry(
        icon: Icons.palette_outlined,
        color: t.b,
        label: 'Colores de Bloques',
        onTap: () {
          HapticFeedback.lightImpact();
          ThemeColorCustomizerSheet.show(context, mode: mode);
        },
      ),
      // Volumen música deslizante (slider táctil y modal ampliado)
      LocaEntry(
        icon: settings.bgVolume == 0 ? Icons.volume_off : Icons.volume_up,
        color: t.c,
        label: 'Vol. Música: ${(settings.bgVolume * 100).round()}%',
        onTap: () {
          HapticFeedback.lightImpact();
          SettingsMusicVolumeSheet.show(context, settings, t);
        },
        childBuilder: (ctx) {
          final pct = (settings.bgVolume * 100).round();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      settings.bgVolume == 0
                          ? Icons.volume_off
                          : Icons.music_note,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Música: $pct%',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
                    thumbColor: Colors.white,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: settings.bgVolume.clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      settings.setBgVolume(val);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Volumen efectos (cicla entre 0.0 / 0.5 / 1.0)
      LocaEntry(
        icon: Icons.record_voice_over,
        color: t.d,
        label: 'Vol. Efectos: ${settings.sfxVolume.toStringAsFixed(1)}',
        onTap: () {
          HapticFeedback.lightImpact();
          final next = settings.sfxVolume <= 0.1
              ? 0.5
              : settings.sfxVolume <= 0.5
                  ? 1.0
                  : 0.0;
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
          final next = !settings.enableSound;
          settings.setEnableSound(next);
          if (next) {
            SoundService().startBackgroundMusic();
          } else {
            SoundService().stopBackgroundMusic();
          }
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
          final next =
              settings.blockWeight >= 1.8 ? 0.5 : settings.blockWeight + 0.5;
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
