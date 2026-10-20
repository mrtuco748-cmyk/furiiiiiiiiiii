import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

class ExerciseActionButtons extends StatelessWidget {
  final bool isEditing;
  final VoidCallback? onDelete;
  final VoidCallback onSubmit;

  const ExerciseActionButtons({
    super.key,
    required this.isEditing,
    this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isEditing && onDelete != null) ...[
          TapTile(
            onTap: () {
              HapticFeedback.heavyImpact();
              onDelete!();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: EjerciciosStyle.panelDeco(
                color: EjerciciosStyle.red,
                radius: 14,
                bw: 2,
              ),
              child: const Icon(Icons.delete,
                  color: EjerciciosStyle.white, size: 26),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: TapTile(
            onTap: onSubmit,
            child: Container(
              height: 52,
              decoration: EjerciciosStyle.panelDeco(
                color: EjerciciosStyle.lime,
                radius: 14,
                bw: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check,
                      color: EjerciciosStyle.darkText, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR EJERCICIO',
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.darkText,
                      fontSize: 18,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
