import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/drawing_controller.dart';

/// Modal para ajustar el grosor y la opacidad del pincel/trazo.
class DrawingBrushSettingsSheet extends StatelessWidget {
  final DrawingController controller;

  const DrawingBrushSettingsSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AJUSTES DE ${controller.selectedTool.displayName.toUpperCase()}',
                  style: GoogleFonts.bangers(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                // Previsualización dinámica de la punta del pincel
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: controller.strokeWidth.clamp(2.0, 70.0),
                      height: controller.strokeWidth.clamp(2.0, 70.0),
                      decoration: BoxDecoration(
                        color: controller.selectedTool.isEraser
                            ? Colors.white.withValues(alpha: 0.4)
                            : controller.selectedColor.withValues(alpha: controller.strokeOpacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Slider de Grosor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grosor', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      '${controller.strokeWidth.toInt()} px',
                      style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00D4FF),
                    inactiveTrackColor: const Color(0xFF262626),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: controller.strokeWidth.clamp(1.0, 60.0),
                    min: 1.0,
                    max: 60.0,
                    onChanged: (val) => controller.setStrokeWidth(val),
                  ),
                ),
                const SizedBox(height: 12),
                // Preajustes rápidos de grosor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [2.0, 5.0, 10.0, 20.0, 35.0, 50.0].map((w) {
                    final isCurrent = (controller.strokeWidth - w).abs() < 1.0;
                    return GestureDetector(
                      onTap: () => controller.setStrokeWidth(w),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF00D4FF) : const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${w.toInt()}',
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFF111111) : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Slider de Opacidad
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Opacidad', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      '${(controller.strokeOpacity * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF39FF14),
                    inactiveTrackColor: const Color(0xFF262626),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: controller.strokeOpacity.clamp(0.05, 1.0),
                    min: 0.05,
                    max: 1.0,
                    onChanged: (val) => controller.setOpacity(val),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
