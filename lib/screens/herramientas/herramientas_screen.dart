import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';

/// Pantalla de selección de herramientas de F.U.R.I.
/// Incluye Dibujo (activo) y Comic (próximamente), con estética brutalista de bloques sólidos.
class HerramientasScreen extends StatelessWidget {
  final AppMode mode;

  const HerramientasScreen({super.key, required this.mode});

  void _showFlipbookInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.movie_creation_outlined, color: Color(0xFFFFDE59)),
            SizedBox(width: 8),
            Text('Animación Flipbook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'La animación cuadro por cuadro reproducirá tus capas de dibujo como fotogramas continuos.\n\nPor ahora, podés organizar tus fotogramas en capas independientes dentro del Taller de Dibujo.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CERRAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: const Color(0xFF111111),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(RouterRoutes.dibujo);
            },
            child: const Text('IR A DIBUJO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: textColor),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.bangers(
                      color: badgeFg,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.bangers(
                color: textColor,
                fontSize: 26,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera brutalista
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'HERRAMIENTAS',
                    style: GoogleFonts.bangers(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Lista de herramientas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Herramienta 1: Dibujo
                  _buildToolCard(
                    context: context,
                    title: 'DIBUJO DIGITAL',
                    subtitle: 'Lienzo multicapa, birome fluida, lápiz grafito texturado, gestos y exportación a PNG y galería.',
                    icon: Icons.draw,
                    color: const Color(0xFF00D4FF),
                    textColor: const Color(0xFF111111),
                    badgeText: 'DISPONIBLE',
                    badgeBg: const Color(0xFF111111),
                    badgeFg: const Color(0xFF00D4FF),
                    onTap: () => context.push(RouterRoutes.dibujo),
                  ),
                  // Herramienta 2: Comic
                  _buildToolCard(
                    context: context,
                    title: 'HISTORIETAS & COMIC',
                    subtitle: 'Páginas y viñetas a escala real, inserción de dibujos, globos de diálogo manga/FURI, SFX y lector.',
                    icon: Icons.auto_stories,
                    color: const Color(0xFFFFDE59),
                    textColor: const Color(0xFF111111),
                    badgeText: 'DISPONIBLE',
                    badgeBg: const Color(0xFF111111),
                    badgeFg: const Color(0xFFFFDE59),
                    onTap: () => context.push(RouterRoutes.comic),
                  ),
                  // Herramienta 3: Animación
                  _buildToolCard(
                    context: context,
                    title: 'ANIMACIÓN FLIPBOOK',
                    subtitle: 'Cuadros de animación cuadro por cuadro basados en tus capas de dibujo.',
                    icon: Icons.movie_creation_outlined,
                    color: const Color(0xFF242424),
                    textColor: Colors.white70,
                    badgeText: 'EN ESPERA',
                    badgeBg: const Color(0xFF141414),
                    badgeFg: Colors.white54,
                    onTap: () => _showFlipbookInfo(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
