import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barra superior decorativa para pantallas LocaScreen.
class LocaHeader extends StatelessWidget {
  final double width;
  final double height;
  final ThemeSet theme;
  final bool showHearts;

  const LocaHeader({
    super.key,
    required this.width,
    required this.height,
    required this.theme,
    this.showHearts = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: theme.d,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Spacer(),
              if (showHearts)
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.favorite, color: theme.light, size: 28),
                  ),
                ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay de progreso cuando una acción asíncrona está bloqueando la pantalla.
class LocaBusyOverlay extends StatelessWidget {
  final ThemeSet theme;

  const LocaBusyOverlay({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: theme.dark.withValues(alpha: 0.6),
        child: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: theme.light,
              strokeWidth: 4,
            ),
          ),
        ),
      ),
    );
  }
}
