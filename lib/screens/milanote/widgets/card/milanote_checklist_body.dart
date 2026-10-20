import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/board_element.dart';

/// Checklist en modo lectura (checkboxes interactivos pero sin edición de texto)
class MilanoteChecklistViewBody extends StatelessWidget {
  final BoardElement element;
  final Color textColor;
  final Function(BoardElement) onUpdate;

  const MilanoteChecklistViewBody({
    super.key,
    required this.element,
    required this.textColor,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(
      (element.data['items'] as List?) ?? [],
    );

    if (items.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.topLeft,
        child: Text(
          'Toca para añadir tareas...',
          style: GoogleFonts.plusJakartaSans(
            color: textColor.withValues(alpha: 0.4),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(items.length, (idx) {
          final item = items[idx];
          final isChecked = item['checked'] == true;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    items[idx]['checked'] = !isChecked;
                    final updatedData = Map<String, dynamic>.from(element.data);
                    updatedData['items'] = items;
                    onUpdate(element.copyWith(data: updatedData));
                  },
                  child: Icon(
                    isChecked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: isChecked
                        ? const Color(0xFF39FF14)
                        : textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['text']?.toString() ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      color: isChecked
                          ? textColor.withValues(alpha: 0.4)
                          : textColor.withValues(alpha: 0.9),
                      fontSize: 12,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Checklist en modo edición (agregar tareas, editar texto de tarea, borrar tarea)
class MilanoteChecklistEditingBody extends StatefulWidget {
  final BoardElement element;
  final Color textColor;
  final Function(BoardElement) onUpdate;

  const MilanoteChecklistEditingBody({
    super.key,
    required this.element,
    required this.textColor,
    required this.onUpdate,
  });

  @override
  State<MilanoteChecklistEditingBody> createState() => _MilanoteChecklistEditingBodyState();
}

class _MilanoteChecklistEditingBodyState extends State<MilanoteChecklistEditingBody> {
  final TextEditingController _newChecklistCtrl = TextEditingController();
  bool _isAddingChecklistItem = false;

  @override
  void dispose() {
    _newChecklistCtrl.dispose();
    super.dispose();
  }

  void _submitNewItem(List<Map<String, dynamic>> items) {
    final val = _newChecklistCtrl.text.trim();
    if (val.isNotEmpty) {
      items.add({'text': val, 'checked': false});
      final updatedData = Map<String, dynamic>.from(widget.element.data);
      updatedData['items'] = items;
      widget.onUpdate(widget.element.copyWith(data: updatedData));
      _newChecklistCtrl.clear();
    }
    setState(() => _isAddingChecklistItem = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(
      (widget.element.data['items'] as List?) ?? [],
    );
    final textColor = widget.textColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(items.length, (idx) {
          final item = items[idx];
          final isChecked = item['checked'] == true;
          final itemText = item['text']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    items[idx]['checked'] = !isChecked;
                    final updatedData = Map<String, dynamic>.from(widget.element.data);
                    updatedData['items'] = items;
                    widget.onUpdate(widget.element.copyWith(data: updatedData));
                  },
                  child: Icon(
                    isChecked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: isChecked
                        ? const Color(0xFF39FF14)
                        : textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: itemText,
                    style: GoogleFonts.plusJakartaSans(
                      color: isChecked
                          ? textColor.withValues(alpha: 0.4)
                          : textColor,
                      fontSize: 12,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      items[idx]['text'] = val;
                      final updatedData = Map<String, dynamic>.from(widget.element.data);
                      updatedData['items'] = items;
                      widget.onUpdate(widget.element.copyWith(data: updatedData));
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    items.removeAt(idx);
                    final updatedData = Map<String, dynamic>.from(widget.element.data);
                    updatedData['items'] = items;
                    widget.onUpdate(widget.element.copyWith(data: updatedData));
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        if (_isAddingChecklistItem)
          Row(
            children: [
              const Icon(
                Icons.check_box_outline_blank_rounded,
                size: 18,
                color: Colors.white38,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newChecklistCtrl,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nombre de la tarea...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _submitNewItem(items),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _submitNewItem(items),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: () {
              setState(() => _isAddingChecklistItem = true);
            },
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Añadir tarea...',
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
