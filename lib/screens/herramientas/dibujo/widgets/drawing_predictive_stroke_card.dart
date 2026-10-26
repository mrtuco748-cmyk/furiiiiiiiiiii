import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';

/// Tarjeta y control interactivo de Trazo Predictivo con deslizador de 1 a 10.
/// Permite activar la estabilización avanzada y ajustar el nivel de amortiguación
/// y extrapolación matemática de trazo.
class DrawingPredictiveStrokeCard extends StatelessWidget {
  final DrawingController controller;
  final bool compact;

  const DrawingPredictiveStrokeCard({
    super.key,
    required this.controller,
    this.compact = false,
  });

  String _getLevelDescription(int level) {
    if (level <= 3) return 'Suavizado ágil (boceto rápido)';
    if (level <= 7) return 'Entintado manga & cómic balanceado';
    return 'Líneas caligráficas y curvas de precisión';
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = controller.isPredictiveStrokeEnabled;
    final level = controller.predictiveStrokeLevel;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila de encabezado y Switch
          Row(
            children: [
              Icon(
                Icons.stream,
                color: isEnabled ? const Color(0xFF00D4FF) : Colors.white60,
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trazo Predictivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                    if (!compact)
                      Text(
                        isEnabled ? _getLevelDescription(level) : 'Desactivado (usa micro-corrección)',
                        style: TextStyle(
                          color: isEnabled ? const Color(0xFF00D4FF).withValues(alpha: 0.8) : Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (val) => controller.setPredictiveStrokeEnabled(val),
                activeThumbColor: const Color(0xFF00D4FF),
                activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: const Color(0xFF333333),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),

          // Control deslizante (1 a 10) cuando está activado
          if (isEnabled) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nivel de predicción:',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$level / 10',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF00D4FF),
                inactiveTrackColor: const Color(0xFF333333),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                trackHeight: 3,
                overlayColor: const Color(0xFF00D4FF).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: level.toDouble().clamp(1.0, 10.0),
                min: 1.0,
                max: 10.0,
                divisions: 9,
                onChanged: (val) => controller.setPredictiveStrokeLevel(val.round()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
