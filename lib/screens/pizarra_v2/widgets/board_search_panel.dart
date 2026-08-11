import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';

class BoardSearchPanel extends StatelessWidget {
  final List<BoardElementV2> elements;
  final String searchText;
  final Function(String) onSearchChanged;
  final VoidCallback onClose;
  final Function(BoardElementV2) onGoToElement;

  const BoardSearchPanel({
    super.key,
    required this.elements,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClose,
    required this.onGoToElement,
  });

  List<BoardElementV2> get _results {
    final q = searchText.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return elements.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q) ||
          e.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: 64,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: onSearchChanged,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar notas, tags...',
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'monospace',
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ),
              ),
              if (_results.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final el in _results)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            _typeIcon(el.type),
                            color: Colors.white70,
                            size: 18,
                          ),
                          title: Text(
                            el.title.isNotEmpty ? el.title : el.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          subtitle: el.tags.isNotEmpty
                              ? Text(
                                  el.tags.take(2).join(', '),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          onTap: () => onGoToElement(el),
                        ),
                    ],
                  ),
                ),
              if (searchText.isNotEmpty && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Sin resultados',
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case BoardElementType.note:
        return Icons.note;
      case BoardElementType.checklist:
        return Icons.checklist;
      case BoardElementType.drawing:
        return Icons.draw;
      case BoardElementType.video:
        return Icons.videocam;
      case BoardElementType.audio:
        return Icons.mic;
      case BoardElementType.connector:
        return Icons.timeline;
      case BoardElementType.subBoard:
        return Icons.dashboard;
      default:
        return Icons.note;
    }
  }
}
