import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/settings_service.dart';
import '../../../theme/app_theme.dart';

/// Modal bottom sheet para ajustar el volumen de la música de fondo.
class SettingsMusicVolumeSheet {
  static void show(BuildContext context, SettingsService settings, ThemeSet t) {
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

  static Widget _presetVolButton(
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
}
