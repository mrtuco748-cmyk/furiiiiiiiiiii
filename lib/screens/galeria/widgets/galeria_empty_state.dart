import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GaleriaEmptyState extends StatelessWidget {
  const GaleriaEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 36,
              color: Color(0xFFFF66C4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay fotos en el lienzo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca el botón rosa para subir recuerdos juntos',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
