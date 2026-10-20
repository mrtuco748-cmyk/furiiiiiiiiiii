import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/event_type.dart';
import '../../../widgets/tap_tile.dart';

const Color _c = Color(0xFF00D4FF);
const Color _near = Color(0xFF1A1A1A);

class ScheduleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const ScheduleTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: _near,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(color: const Color(0xFF0088AA), fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }
}

class ScheduleDateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const ScheduleDateField({
    super.key,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _near,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF00D4FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('EEE d MMM', 'es').format(date),
                  style: GoogleFonts.bangers(color: _c, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleTimeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const ScheduleTimeField({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _near,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: Color(0xFF00D4FF), size: 18),
              const SizedBox(width: 6),
              Text(
                controller.text.isEmpty ? '--:--' : controller.text,
                style: GoogleFonts.bangers(color: _c, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleTypeRow extends StatelessWidget {
  final List<EventType> types;
  final String selectedType;
  final VoidCallback onOpenTypePicker;
  final VoidCallback onManageTypes;

  const ScheduleTypeRow({
    super.key,
    required this.types,
    required this.selectedType,
    required this.onOpenTypePicker,
    required this.onManageTypes,
  });

  @override
  Widget build(BuildContext context) {
    final currentType = types.where((t) => t.name == selectedType).firstOrNull;
    final icon = currentType?.iconData ?? Icons.category;
    final displayColor = currentType != null ? Color(currentType.color) : _c;

    return Row(
      children: [
        const Icon(Icons.category, color: Color(0xFF00D4FF), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TapTile(
            onTap: types.isNotEmpty ? onOpenTypePicker : () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _near,
                  border: Border.all(color: displayColor, width: 3),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: Row(children: [
                  Icon(icon, color: displayColor, size: 28),
                  const SizedBox(width: 8),
                  Icon(Icons.category, color: displayColor, size: 20),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        TapTile(
          onTap: onManageTypes,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _near,
              border: Border.all(color: _c, width: 3),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: const Icon(Icons.settings, color: Color(0xFF00D4FF), size: 22),
          ),
        ),
      ],
    );
  }
}

class ScheduleDeleteConfirmDialog extends StatelessWidget {
  const ScheduleDeleteConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const ScheduleDeleteConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _near,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.red, width: 4),
      ),
      title: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context, false),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _near,
                border: Border.all(color: _near, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TapTile(
          onTap: () => Navigator.pop(context, true),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red,
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 24),
            ),
          ),
        ),
      ],
    );
  }
}
