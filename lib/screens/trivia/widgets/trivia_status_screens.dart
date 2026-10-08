import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/trivia_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';

class LoadingScreen extends StatelessWidget {
  final ThemeSet theme;
  const LoadingScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF9D00FF), strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Cargando trivia...',
                style: GoogleFonts.bangers(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final ThemeSet theme;
  final String message;
  final VoidCallback onRetry;
  const ErrorScreen({
    super.key,
    required this.theme,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              TapTile(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D00FF),
                    border: Border.all(color: const Color(0xFF9D00FF), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Reintentar',
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyScreen extends StatelessWidget {
  final ThemeSet theme;
  final VoidCallback onAdd;
  const EmptyScreen({super.key, required this.theme, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz, color: const Color(0xFF9D00FF), size: 64),
              const SizedBox(height: 16),
              Text('¡No hay preguntas!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              Text('Agregá la primera para empezar a jugar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              TapTile(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D00FF),
                    border: Border.all(color: const Color(0xFF9D00FF), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Agregar pregunta',
                          style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Scoreboard extends StatelessWidget {
  final ThemeSet theme;
  final TriviaProvider provider;
  const Scoreboard({super.key, required this.theme, required this.provider});

  @override
  Widget build(BuildContext context) {
    final myScore = provider.myScore;
    final partnerScore = provider.partnerScore;
    final iWin = myScore >= partnerScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF9D00FF), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text('VOS', style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
              Text('$myScore',
                  style: GoogleFonts.bangers(
                      color: iWin ? const Color(0xFF39FF14) : Colors.white, fontSize: 24)),
            ],
          ),
          const SizedBox(width: 20),
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 20),
          Column(
            children: [
              Text('PAREJA', style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
              Text('$partnerScore',
                  style: GoogleFonts.bangers(
                      color: !iWin ? const Color(0xFF39FF14) : Colors.white, fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return TapTile(
      onTap: onTap ?? () {},
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? color : const Color(0xFF333333),
            border: Border.all(color: enabled ? color : const Color(0xFF333333), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? Colors.white : Colors.white54, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.bangers(
                      color: enabled ? Colors.white : Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
