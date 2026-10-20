import 'package:flutter/material.dart';

/// Barra y botones de acción flotantes para el mazo (Volver, Historial, Banner de re-deslizar).
class DeckHeaderActions {
  static Widget closeButton({required VoidCallback onTap}) {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }

  static Widget historyButton({required VoidCallback onTap}) {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF9D00FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              const Icon(Icons.history, color: Color(0xFF1A1A1A), size: 20),
        ),
      ),
    );
  }

  static Widget reswipeBanner({required VoidCallback onDismiss}) {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF9D00FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz,
                  color: Color(0xFF1A1A1A), size: 18),
              const SizedBox(width: 6),
              const Text(
                'deslizá de nuevo',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close,
                    color: Color(0xFF1A1A1A), size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
