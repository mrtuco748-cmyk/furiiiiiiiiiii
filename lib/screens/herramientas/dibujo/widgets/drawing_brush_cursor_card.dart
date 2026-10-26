import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';

/// Tarjeta de configuración para la guía visual de trazo y borrador (Brush Cursor ring).
class DrawingBrushCursorCard extends StatelessWidget {
  final DrawingController controller;

  const DrawingBrushCursorCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked, color: Color(0xFF00D4FF), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Guía Visual de Pincel y Goma',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Círculo con el grosor exacto en vivo',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: controller.showBrushCursor,
            activeThumbColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF005577),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) => controller.setShowBrushCursor(val),
          ),
        ],
      ),
    );
  }
}
