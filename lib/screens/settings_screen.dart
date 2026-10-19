import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../providers/chat_provider.dart';
import '../router.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';
import '../widgets/theme_color_customizer_sheet.dart';

/// Configuración estilo "Nosotros": botones-icono gigantes (cambiar sesión /
/// sonido + personalización visual) en mosaico, sin texto a simple vista.
class SettingsScreen extends StatefulWidget {
  final AppMode mode;
  const SettingsScreen({super.key, required this.mode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _picker = ImagePicker();

  Future<void> _pickAndSetAvatar(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Foto de perfil (${AppState.myName ?? AppState.identity ?? "Yo"})',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00D4FF)),
                title: Text(
                  'Elegir de la galería',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00D4FF)),
                title: Text(
                  'Tomar foto con la cámara',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
      );
      if (picked == null || !context.mounted) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!context.mounted) return;
      await context.read<ChatProvider>().updateMyAvatar(base64Image);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Foto de perfil actualizada!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF25D366),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error actualizando foto de perfil en settings: $e');
    }
  }

  void _showMusicVolumeSheet(BuildContext context, SettingsService settings, ThemeSet t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final vol = settings.bgVolume;
            final pct = (vol * 100).round();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E24),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: t.c,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            vol == 0 ? Icons.volume_off : Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VOLUMEN DE MÚSICA',
                                style: GoogleFonts.bangers(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Música de fondo en loop (por defecto 10%)',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.c,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pct%',
                            style: GoogleFonts.bangers(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 8,
                        activeTrackColor: t.c,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                        overlayColor: t.c.withValues(alpha: 0.2),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      ),
                      child: Slider(
                        value: vol.clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          setModalState(() {});
                          settings.setBgVolume(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _presetVolButton('Silencio (0%)', 0.0, vol, settings, setModalState),
                          const SizedBox(width: 8),
                          _presetVolButton('10% (Defecto)', 0.10, vol, settings, setModalState),
                          const SizedBox(width: 8),
                          _presetVolButton('25%', 0.25, vol, settings, setModalState),
                          const SizedBox(width: 8),
                          _presetVolButton('50%', 0.50, vol, settings, setModalState),
                          const SizedBox(width: 8),
                          _presetVolButton('75%', 0.75, vol, settings, setModalState),
                          const SizedBox(width: 8),
                          _presetVolButton('100%', 1.0, vol, settings, setModalState),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _presetVolButton(
    String label,
    double value,
    double current,
    SettingsService settings,
    void Function(void Function()) setModalState,
  ) {
    final isSelected = (current - value).abs() < 0.03;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setModalState(() {});
        settings.setBgVolume(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF2A2A34),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
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
          _pickAndSetAvatar(context);
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
          ThemeColorCustomizerSheet.show(context, mode: widget.mode);
        },
      ),
      // Volumen música deslizante (slider táctil y modal ampliado)
      LocaEntry(
        icon: settings.bgVolume == 0 ? Icons.volume_off : Icons.volume_up,
        color: t.c,
        label: 'Vol. Música: ${(settings.bgVolume * 100).round()}%',
        onTap: () {
          HapticFeedback.lightImpact();
          _showMusicVolumeSheet(context, settings, t);
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
                      settings.bgVolume == 0 ? Icons.volume_off : Icons.music_note,
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
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
