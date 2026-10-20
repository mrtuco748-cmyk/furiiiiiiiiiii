import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/gallery_provider.dart';
import '../../../router.dart';

class GaleriaTopBar extends StatelessWidget {
  final GalleryProvider provider;
  final VoidCallback onClearCache;

  const GaleriaTopBar({
    super.key,
    required this.provider,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF181818),
      child: Row(
        children: [
          // Botón volver
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF242424),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Título
          Text(
            'GALERÍA',
            style: GoogleFonts.bangers(
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),

          // Badge con conteo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${provider.items.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF66C4),
              ),
            ),
          ),

          const Spacer(),

          // Botón temático Pinterest (Abre la vista integrada)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onClearCache();
              context.push(RouterRoutes.pinterest);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE60023), // Rojo sólido Pinterest
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Pinterest',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón refrescar
          GestureDetector(
            onTap: () => provider.load(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
