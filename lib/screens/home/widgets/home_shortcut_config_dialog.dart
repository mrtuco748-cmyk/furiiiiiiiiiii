import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../models/home_shortcut_models.dart';

void showShortcutConfigDialog({
  required BuildContext context,
  required ThemeSet theme,
  required List<String> currentShortcuts,
  required ValueChanged<List<String>> onSave,
}) {
  final workingList = List<String>.from(currentShortcuts);

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: theme.b, size: 26),
              const SizedBox(width: 10),
              Text(
                'ELEGIR ATAJOS',
                style: GoogleFonts.bangers(
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tocá para agregar o quitar de la barra',
                      style: GoogleFonts.bangers(
                        fontSize: 13,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: homeShortcuts.length,
                    itemBuilder: (context, i) {
                      final sc = homeShortcuts[i];
                      final isSelected = workingList.contains(sc.action);
                      final itemColor = isSelected ? shortcutColor(theme, i) : const Color(0xFF242424);
                      final textColor = isSelected ? Colors.white : Colors.white38;
                      final iconColor = isSelected ? Colors.white : Colors.white38;

                      return TapTile(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              workingList.remove(sc.action);
                            } else {
                              workingList.add(sc.action);
                            }
                          });
                          onSave(List<String>.from(workingList));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(sc.icon, color: iconColor, size: 26),
                              const SizedBox(height: 6),
                              Text(
                                sc.label,
                                style: GoogleFonts.bangers(
                                  fontSize: 11,
                                  color: textColor,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TapTile(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.b,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'LISTO',
                    style: GoogleFonts.bangers(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
