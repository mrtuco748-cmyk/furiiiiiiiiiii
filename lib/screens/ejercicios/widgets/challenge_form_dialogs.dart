import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/workout_challenge.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

Widget ejercicioField(TextEditingController ctrl, String hint, {bool autofocus = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: ctrl,
      autofocus: autofocus,
      style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
      decoration: EjerciciosStyle.inputDeco(hint),
    ),
  );
}

Widget ejercicioNumField(TextEditingController ctrl, String hint) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
      decoration: EjerciciosStyle.inputDeco(hint),
    ),
  );
}

Widget ejercicioDecimalField(TextEditingController ctrl, String hint) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
      decoration: EjerciciosStyle.inputDeco(hint),
    ),
  );
}

Widget customFormDialog({
  required BuildContext context,
  required String title,
  required List<Widget> fields,
  required bool Function() onOk,
}) {
  return AlertDialog(
    backgroundColor: EjerciciosStyle.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    title: Row(
      children: [
        const Icon(Icons.fitness_center, color: EjerciciosStyle.cyan, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.bangers(
            color: EjerciciosStyle.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: fields,
      ),
    ),
    actions: [
      TapTile(
        onTap: () => Navigator.pop(context, false),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EjerciciosStyle.panelLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 20),
        ),
      ),
      TapTile(
        onTap: () {
          if (onOk()) {
            Navigator.pop(context, true);
          } else {
            HapticFeedback.heavyImpact();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EjerciciosStyle.cyan,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check, color: EjerciciosStyle.darkText, size: 20),
        ),
      ),
    ],
  );
}

Future<void> dialogNewChallenge(BuildContext context, WorkoutProvider pv) async {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => customFormDialog(
      context: ctx,
      title: 'Nuevo reto',
      fields: [
        ejercicioField(titleCtrl, 'Título *', autofocus: true),
        ejercicioField(descCtrl, 'Descripción'),
      ],
      onOk: () => titleCtrl.text.trim().isNotEmpty,
    ),
  );
  if (saved != true) return;
  await pv.addChallenge(WorkoutChallenge(
    title: titleCtrl.text.trim(),
    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
  ));
}

void sheetReactions(BuildContext context, Future<void> Function(String key) onReact) {
  showModalBottomSheet(
    context: context,
    backgroundColor: EjerciciosStyle.panel,
    barrierColor: Colors.black26,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 10,
                  children: [
                    for (final emoji in EjerciciosStyle.defaultReactions)
                      TapTile(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await onReact(emoji);
                          setSheetState(() {});
                        },
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    TapTile(
                      onTap: () => customReactionDialog(context, (key) async => onReact(key)),
                      child: const Icon(Icons.add_reaction, color: EjerciciosStyle.cyan, size: 26),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> customReactionDialog(BuildContext context, Future<void> Function(String key) onReact) async {
  final ctrl = TextEditingController();
  final key = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: EjerciciosStyle.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 10,
        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
        decoration: EjerciciosStyle.inputDeco('Reacción custom (max 10)'),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(ctx),
          child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 20),
        ),
        TapTile(
          onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Icon(Icons.check, color: EjerciciosStyle.cyan, size: 20),
        ),
      ],
    ),
  );
  if (key != null && key.isNotEmpty) await onReact(key);
}
