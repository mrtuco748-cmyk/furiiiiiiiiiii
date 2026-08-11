import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';

/// Renderer simple para notas de texto.
class BoardNoteRenderer extends StatefulWidget {
  final BoardElementV2 element;
  final bool isEditing;
  final Function(String? content)? onContentChanged;
  final VoidCallback? onRequestEdit;

  const BoardNoteRenderer({
    super.key,
    required this.element,
    this.isEditing = false,
    this.onContentChanged,
    this.onRequestEdit,
  });

  @override
  State<BoardNoteRenderer> createState() => _BoardNoteRendererState();
}

class _BoardNoteRendererState extends State<BoardNoteRenderer> {
  late TextEditingController _ctrl;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.element.content);
    _focus = FocusNode();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(BoardNoteRenderer old) {
    super.didUpdateWidget(old);
    if (widget.isEditing != old.isEditing) {
      if (widget.isEditing) {
        _ctrl.text = widget.element.content;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      } else {
        _focus.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(widget.element.color, const Color(0xFF1A1A1A));
    final textColor = _parseColor(widget.element.textColor, Colors.white);
    final fontFamily = widget.element.fontFamily ?? 'monospace';
    final fontSize = widget.element.fontSize ?? 14;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        minHeight: 60,
        maxWidth: 400,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji header
          if (widget.element.emojiHeader != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.element.emojiHeader!,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          // Title
          if (widget.element.title.isNotEmpty && !widget.element.isCollapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.element.title,
                style: TextStyle(
                  color: textColor,
                  fontFamily: fontFamily,
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Content
          if (!widget.element.isCollapsed)
            widget.isEditing
                ? TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: true,
                    maxLines: 10,
                    minLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escribí algo...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.3),
                        fontFamily: fontFamily,
                        fontSize: fontSize,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (v) {
                      widget.onContentChanged?.call(v);
                    },
                    onChanged: (v) {
                      // Save on every change
                      widget.onContentChanged?.call(v);
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () {
                      // Entrar en modo edición (el canvas setea isEditing)
                      widget.onRequestEdit?.call();
                    },
                    child: Text(
                      widget.element.content.isNotEmpty
                          ? widget.element.content
                          : 'Doble tap para editar',
                      style: TextStyle(
                        color: widget.element.content.isNotEmpty
                            ? textColor
                            : textColor.withValues(alpha: 0.3),
                        fontFamily: fontFamily,
                        fontSize: fontSize,
                        height: 1.4,
                      ),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          // Tags
          if (widget.element.tags.isNotEmpty && !widget.element.isCollapsed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: widget.element.tags
                    .take(3)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
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
