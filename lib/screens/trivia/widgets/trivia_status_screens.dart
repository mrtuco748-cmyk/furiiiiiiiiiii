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
            CircularProgressIndicator(color: theme.a, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Cargando trivia...',
              style: GoogleFonts.bangers(color: Colors.white54, fontSize: 16),
            ),
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
              const Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TapTile(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.a,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Reintentar',
                    style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
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

class EmptyScreen extends StatelessWidget {
  final ThemeSet theme;
  final VoidCallback onAdd;
  final VoidCallback? onHistory;

  const EmptyScreen({
    super.key,
    required this.theme,
    required this.onAdd,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_rounded, color: theme.a, size: 60),
            const SizedBox(height: 16),
            Text(
              '¡Están al día con la trivia!',
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'No quedan preguntas pendientes por responder.',
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (onHistory != null)
                  TapTile(
                    onTap: onHistory!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Ver historial',
                            style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                TapTile(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.a,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Nueva pregunta',
                          style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'VOS $myScore',
            style: GoogleFonts.bangers(
              color: iWin ? const Color(0xFF39FF14) : Colors.white,
              fontSize: 16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '·',
              style: GoogleFonts.bangers(color: Colors.white38, fontSize: 16),
            ),
          ),
          Text(
            'PAREJA $partnerScore',
            style: GoogleFonts.bangers(
              color: !iWin ? const Color(0xFF39FF14) : Colors.white,
              fontSize: 16,
            ),
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
            color: enabled ? color : const Color(0xFF222222),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? Colors.white : Colors.white54, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.bangers(
                  color: enabled ? Colors.white : Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
