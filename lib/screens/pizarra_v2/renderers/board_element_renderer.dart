import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import 'board_note_renderer.dart';
import 'board_checklist_renderer.dart';
import 'board_drawing_renderer.dart';
import 'board_video_renderer.dart';
import 'board_audio_renderer.dart';

/// Widget unificado que renderiza cualquier tipo de elemento.
/// Delega al renderer específico según el tipo.
class BoardElementRenderer extends StatelessWidget {
  final BoardElementV2 element;
  final bool isEditing;
  final Function(Map<String, dynamic>)? onDataChanged;
  final VoidCallback? onRequestEdit;

  const BoardElementRenderer({
    super.key,
    required this.element,
    this.isEditing = false,
    this.onDataChanged,
    this.onRequestEdit,
  });

  @override
  Widget build(BuildContext context) {
    switch (element.type) {
      case BoardElementType.note:
        return BoardNoteRenderer(
          element: element,
          isEditing: isEditing,
          onContentChanged: (content) {
            onDataChanged?.call({'_content': content});
          },
          onRequestEdit: onRequestEdit,
        );

      case BoardElementType.checklist:
        return BoardChecklistRenderer(
          element: element,
          isEditing: isEditing,
          onDataChanged: (data) {
            onDataChanged?.call(data.toMap());
          },
        );

      case BoardElementType.drawing:
        return BoardDrawingRenderer(element: element);

      case BoardElementType.video:
        return BoardVideoRenderer(element: element);

      case BoardElementType.audio:
        return BoardAudioRenderer(element: element);

      case BoardElementType.subBoard:
        return _subBoardRenderer();

      case BoardElementType.separator:
        return _separatorRenderer();

      default:
        return _defaultRenderer();
    }
  }

  Widget _subBoardRenderer() {
    final bgColor = _parseColor(element.color, const Color(0xFF1A1A1A));
    final title = element.title.isNotEmpty ? element.title : 'Sub-tablero';
    return Container(
      width: 160,
      height: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.dashboard, color: Colors.white70, size: 24),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _separatorRenderer() {
    final color = _parseColor(element.color, const Color(0xFF333333));
    final horizontal = element.data['orientation'] == 'vertical';
    return SizedBox(
      width: horizontal ? 2 : (element.width ?? 300),
      height: horizontal ? (element.height ?? 200) : 2,
      child: Container(
        color: color,
      ),
    );
  }

  Widget _defaultRenderer() {
    final bgColor = _parseColor(element.color, const Color(0xFF1A1A1A));
    final textColor = _parseColor(element.textColor, Colors.white);

    return Container(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (element.emojiHeader != null)
            Text(element.emojiHeader!, style: const TextStyle(fontSize: 24)),
          if (element.emojiHeader != null) const SizedBox(height: 4),
          if (element.title.isNotEmpty)
            Text(
              element.title,
              style: TextStyle(
                color: textColor,
                fontFamily: element.fontFamily ?? 'monospace',
                fontSize: element.fontSize ?? 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (element.content.isNotEmpty)
            Text(
              element.content,
              style: TextStyle(
                color: textColor,
                fontFamily: element.fontFamily ?? 'monospace',
                fontSize: (element.fontSize ?? 14) - 1,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
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
