import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';
import 'widgets/herramienta_cards.dart';

/// Pantalla de selección de herramientas creativas de F.U.R.I.
/// Disposición brutalista: Fila superior con 2 tarjetas cuadradas (Dibujo y Cómic),
/// tarjeta de Animación debajo y espacio para futuras herramientas.
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
            // Contenido en grilla y lista
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Fila 1: 2 cuadrados idénticos (Dibujo y Cómic)
                  Row(
                    children: [
                      HerramientaSquareCard(
                        title: 'DIBUJO DIGITAL',
                        subtitle: 'Lienzo multicapa, pinceles y trazo predictivo.',
                        icon: Icons.draw,
                        color: const Color(0xFF00D4FF),
                        textColor: const Color(0xFF111111),
                        badgeText: 'DISPONIBLE',
                        badgeBg: const Color(0xFF111111),
                        badgeFg: const Color(0xFF00D4FF),
                        onTap: () => context.push(RouterRoutes.dibujo),
                      ),
                      const SizedBox(width: 14),
                      HerramientaSquareCard(
                        title: 'HISTORIETAS & COMIC',
                        subtitle: 'Páginas, viñetas, globos manga y lector.',
                        icon: Icons.auto_stories,
                        color: const Color(0xFFFFDE59),
                        textColor: const Color(0xFF111111),
                        badgeText: 'DISPONIBLE',
                        badgeBg: const Color(0xFF111111),
                        badgeFg: const Color(0xFFFFDE59),
                        onTap: () => context.push(RouterRoutes.comic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fila 2: Animación Flipbook abajo
                  HerramientaWideCard(
                    title: 'ANIMACIÓN FLIPBOOK',
                    subtitle: 'Fotogramas basados en capas de dibujo para animación cuadro a cuadro.',
                    icon: Icons.movie_creation_outlined,
                    color: const Color(0xFF222222),
                    textColor: Colors.white,
                    badgeText: 'EN ESPERA',
                    badgeBg: const Color(0xFF141414),
                    badgeFg: Colors.white54,
                    onTap: () => _showFlipbookInfo(context),
                  ),
                  const SizedBox(height: 16),

                  // Espacio preparado para futuras herramientas
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.white30, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'MÁS HERRAMIENTAS CREATIVAS PRÓXIMAMENTE',
                          style: GoogleFonts.bangers(
                            color: Colors.white30,
                            fontSize: 14,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
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
