import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/event_type.dart';
import '../../../providers/event_type_provider.dart';
import '../../../widgets/tap_tile.dart';
import 'event_color_picker_dialog.dart';

const Color _c = Color(0xFF00D4FF);
const Color _dark = Color(0xFF0D0D0D);
const Color _near = Color(0xFF1A1A1A);
const Color _cDeep = Color(0xFF003344);
const Color _cBright = Color(0xFF0088AA);

const List<String> _iconNames = [
  'event', 'school', 'book', 'assignment', 'science', 'alarm',
  'schedule', 'star', 'favorite', 'celebration', 'restaurant', 'coffee',
  'cake', 'shopping_cart', 'notifications', 'group', 'workspaces',
  'check_circle', 'edit_note', 'description', 'menu_book', 'auto_stories',
  'pan_tool', 'handyman', 'local_dining', 'fastfood', 'local_pizza',
  'local_bar', 'wine_bar', 'menu',
];

class EventTypeDialogs {
  static void showTypePicker({
    required BuildContext context,
    required List<EventType> types,
    required String selectedType,
    required void Function(EventType selected) onSelected,
  }) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _near,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _c, width: 4),
        ),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: Icon(Icons.category, color: _c, size: 36)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) => TapTile(
                  onTap: () {
                    onSelected(t);
                    Navigator.pop(ctx);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedType == t.name ? _c : _near,
                        border: Border.all(color: Color(t.color), width: 3),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
                        ],
                      ),
                      child: Icon(
                        t.iconData,
                        color: selectedType == t.name ? _dark : Color(t.color),
                        size: 28,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showManageTypesDialog({
    required BuildContext context,
    required String currentType,
    required void Function(String resetType) onTypeDeleted,
  }) async {
    HapticFeedback.selectionClick();
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final etp = ctx.read<EventTypeProvider>();
          return AlertDialog(
            backgroundColor: _near,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _c, width: 4),
            ),
            title: Row(children: [
              const Icon(Icons.category, color: Color(0xFF00D4FF), size: 26),
              const SizedBox(width: 8),
              Text('Tipos de evento', style: GoogleFonts.bangers(color: _c, fontSize: 15)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: _manageTextField(nameCtrl, 'Nuevo tipo')),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00D4FF), size: 30),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final picked = await showDialog<int>(
                          context: ctx,
                          builder: (c) => const EventColorPickerDialog(),
                        );
                        if (picked == null || !ctx.mounted) return;
                        final icon = await showPickIconDialog(ctx, 'event');
                        if (icon == null || !ctx.mounted) return;
                        await etp.addType(EventType(
                          name: nameCtrl.text.trim(),
                          color: picked,
                          icon: icon,
                        ));
                        nameCtrl.clear();
                        setDialogState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: etp.types.map((t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(t.iconData, color: Color(t.color), size: 22),
                        title: Text(t.name, style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: t.id == null
                              ? null
                              : () async {
                                  await etp.deleteType(t.id!);
                                  if (t.name == currentType) {
                                    onTypeDeleted('Clase');
                                  }
                                  setDialogState(() {});
                                },
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
                      border: Border.all(color: _c, width: 3),
                      borderRadius: BorderRadius.circular(18),
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

  static Widget _manageTextField(TextEditingController ctrl, String hint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _near,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.bangers(color: _c, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(color: _cDeep, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ),
    );
  }

  static Future<String?> showPickIconDialog(BuildContext ctx, String current) async {
    String selected = current;
    return showDialog<String>(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialogState) {
          return AlertDialog(
            backgroundColor: _near,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _c, width: 4),
            ),
            title: Text('Elegir icono', style: GoogleFonts.bangers(color: _c, fontSize: 15)),
            content: SizedBox(
              width: 300,
              height: 280,
              child: GridView.count(
                crossAxisCount: 6,
                childAspectRatio: 1,
                children: _iconNames.map((name) {
                  final sel = selected == name;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selected = name),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: sel ? _c : _dark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? _c : _cBright, width: 2),
                      ),
                      child: Icon(
                        EventType(name: '', color: 0, icon: name).iconData,
                        color: sel ? _dark : _c,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                      border: Border.all(color: _c, width: 3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
                  ),
                ),
              ),
              TapTile(
                onTap: () => Navigator.pop(c, selected),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _c,
                      border: Border.all(color: _dark, width: 3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 22),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
