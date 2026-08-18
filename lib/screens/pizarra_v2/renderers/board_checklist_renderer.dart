import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';

/// Renderer para checklist con estados y asignación.
class BoardChecklistRenderer extends StatefulWidget {
  final BoardElementV2 element;
  final bool isEditing;
  final Function(ChecklistData)? onDataChanged;

  const BoardChecklistRenderer({
    super.key,
    required this.element,
    this.isEditing = false,
    this.onDataChanged,
  });

  @override
  State<BoardChecklistRenderer> createState() => _BoardChecklistRendererState();
}

class _BoardChecklistRendererState extends State<BoardChecklistRenderer> {
  late ChecklistData _data;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _data = ChecklistData.fromMap(widget.element.data);
    if (_data.items.isEmpty) {
      _data = ChecklistData(items: [
        ChecklistItem(id: _newId(), text: 'Item 1'),
      ]);
    }
  }

  @override
  void didUpdateWidget(covariant BoardChecklistRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refrescar datos cuando el elemento cambia desde afuera (realtime/sync).
    if (oldWidget.element.data != widget.element.data) {
      _data = ChecklistData.fromMap(widget.element.data);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  void _addItem() {
    setState(() {
      _data = _data.copyWith(
        items: [..._data.items, ChecklistItem(id: _newId(), text: 'Nuevo item')],
      );
    });
    _notifyChange();
  }

  void _removeItem(String id) {
    setState(() {
      _data = _data.copyWith(
        items: _data.items.where((i) => i.id != id).toList(),
      );
    });
    _notifyChange();
  }

  void _toggleState(String id) {
    setState(() {
      final items = _data.items.map((i) {
        if (i.id != id) return i;
        final next = i.state == 'pending'
            ? 'in_progress'
            : i.state == 'in_progress'
                ? 'done'
                : 'pending';
        return i.copyWith(state: next);
      }).toList();
      _data = _data.copyWith(items: items);
    });
    _notifyChange();
  }

  void _updateText(String id, String text) {
    setState(() {
      final items = _data.items.map((i) {
        return i.id == id ? i.copyWith(text: text) : i;
      }).toList();
      _data = _data.copyWith(items: items);
    });
    _notifyChange();
  }

  void _toggleAssign(String id) {
    setState(() {
      final items = _data.items.map((i) {
        if (i.id != id) return i;
        final current = i.assignedTo;
        final next = current == null
            ? 'facu'
            : current == 'facu'
                ? 'rocio'
                : null;
        return i.copyWith(assignedTo: next);
      }).toList();
      _data = _data.copyWith(items: items);
    });
    _notifyChange();
  }

  void _notifyChange() {
    widget.onDataChanged?.call(_data);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(widget.element.color, const Color(0xFF1A1A1A));
    final textColor = _parseColor(widget.element.textColor, Colors.white);

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 350),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (widget.element.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.element.title,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'monospace',
                  fontSize: (widget.element.fontSize ?? 14) + 2,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Items
          ..._data.items.map((item) => _buildItem(item, textColor)),
          // Add button
          GestureDetector(
            onTap: _addItem,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.add, color: textColor.withValues(alpha: 0.5), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Agregar item',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: const Color(0xFF333333),
                    valueColor: AlwaysStoppedAnimation(_progressColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_doneCount/${_data.items.length}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ChecklistItem item, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleState(item.id),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.state == 'done'
                    ? const Color(0xFF4CAF50)
                    : item.state == 'in_progress'
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(4),
              ),
              child: item.state == 'done'
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : item.state == 'in_progress'
                      ? const Icon(Icons.play_arrow, color: Colors.black, size: 12)
                      : null,
            ),
          ),
          const SizedBox(width: 8),
          // Text
          Expanded(
            child: GestureDetector(
              onTap: () => _editItemText(item),
              child: Text(
                item.text,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  decoration: item.state == 'done' ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Assignee badge
          GestureDetector(
            onTap: () => _toggleAssign(item.id),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.assignedTo == 'facu'
                    ? const Color(0xFF4FC3F7)
                    : item.assignedTo == 'rocio'
                        ? const Color(0xFFCE93D8)
                        : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  item.assignedTo == 'facu'
                      ? 'F'
                      : item.assignedTo == 'rocio'
                          ? 'R'
                          : '?',
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () => _removeItem(item.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.close, color: textColor.withValues(alpha: 0.3), size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editItemText(ChecklistItem item) async {
    _textCtrl.text = item.text;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: TextField(
          controller: _textCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'Texto del item',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _textCtrl.text),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _textCtrl.text.trim()),
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _updateText(item.id, result);
    }
  }

  double get _progress {
    if (_data.items.isEmpty) return 0;
    return _data.items.where((i) => i.state == 'done').length / _data.items.length;
  }

  int get _doneCount => _data.items.where((i) => i.state == 'done').length;

  Color get _progressColor {
    if (_progress == 1) return const Color(0xFF4CAF50);
    if (_progress > 0) return const Color(0xFFFFD700);
    return const Color(0xFF666666);
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
