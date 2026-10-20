import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/class_type.dart';
import '../../../providers/class_type_provider.dart';
import '../../../widgets/tap_tile.dart';
import 'class_color_picker_dialog.dart';

const Color _c = Color(0xFF00D4FF);
const Color _dark = Color(0xFF0D0D0D);
const Color _near = Color(0xFF1A1A1A);
const Color _cBright = Color(0xFF0088AA);

class ClassTypeDialogs {
  static void showManageTypes(BuildContext context) {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tp = ctx.read<ClassTypeProvider>();
          return AlertDialog(
            backgroundColor: _near,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _c, width: 4),
            ),
            title: Row(children: [
              const Icon(Icons.category, color: Color(0xFF00D4FF), size: 26),
              const SizedBox(width: 8),
              Text(
                'Tipos de clase',
                style: GoogleFonts.bangers(
                  color: _c,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: manageField(nameCtrl, 'Nuevo tipo')),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00D4FF), size: 30),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final picked = await showDialog<int>(
                          context: ctx,
                          builder: (c) => const ClassColorPickerDialog(),
                        );
                        if (picked == null) return;
                        await tp.addType(ClassType(name: nameCtrl.text.trim(), color: picked));
                        nameCtrl.clear();
                        setDialogState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: tp.types.map((t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Color(t.color),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        title: Text(t.name, style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: _cBright),
                              onPressed: () async {
                                final edited = await editType(ctx, t);
                                if (edited != null) {
                                  await tp.updateType(edited);
                                  setDialogState(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: t.id == null
                                  ? null
                                  : () async {
                                      await tp.deleteType(t.id!);
                                      setDialogState(() {});
                                    },
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TapTile(
                onTap: () => Navigator.pop(ctx),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _near,
                      border: Border.all(color: _near, width: 3),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<ClassType?> editType(BuildContext ctx, ClassType type) async {
    final nameCtrl = TextEditingController(text: type.name);
    int pickedColor = type.color;
    return showDialog<ClassType>(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (c, setEditState) => AlertDialog(
          backgroundColor: _near,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _c, width: 4),
          ),
          title: Text('Editar tipo', style: GoogleFonts.bangers(color: _c, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              manageField(nameCtrl, 'Nombre'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: classColors.map((col) => GestureDetector(
                  onTap: () => setEditState(() => pickedColor = col.toARGB32()),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pickedColor == col.toARGB32() ? _c : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TapTile(
              onTap: () => Navigator.pop(c),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _near,
                    border: Border.all(color: _near, width: 3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
                ),
              ),
            ),
            TapTile(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(c, ClassType(id: type.id, name: nameCtrl.text.trim(), color: pickedColor));
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _c,
                    border: Border.all(color: _c, width: 3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget manageField(TextEditingController ctrl, String hint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _dark,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(color: const Color(0xFF0088AA), fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ),
    );
  }
}
