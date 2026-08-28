import 'package:flutter/material.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../models/board_element_v2.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

/// Vista de lista de todos los elementos del pizarrón.
class BoardListView extends StatelessWidget {
  final BoardProviderV2 provider;
  final Function(BoardElementV2) onGoToElement;

  const BoardListView({
    super.key,
    required this.provider,
    required this.onGoToElement,
  });

  @override
  Widget build(BuildContext context) {
    final elements = provider.elements;

    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentFacu),
      );
    }

    if (provider.hasError && elements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF5757), size: 40),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Error',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => provider.load(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: Color(0xFF0A0A0A)),
              ),
            ),
          ],
        ),
      );
    }

    if (elements.isEmpty) {
      return const Center(
        child: Text(
          'No hay elementos en el pizarrón',
          style: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: elements.length,
      itemBuilder: (context, index) {
        final el = elements[index];
        return _ListItem(
          element: el,
          onTap: () => onGoToElement(el),
        );
      },
    );
  }
}

class _ListItem extends StatelessWidget {
  final BoardElementV2 element;
  final VoidCallback onTap;

  const _ListItem({
    required this.element,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authorColor = _authorColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor(element.type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _typeColor(element.type), width: 1),
              ),
              child: Icon(
                _typeIcon(element.type),
                color: _typeColor(element.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    element.title.isNotEmpty ? element.title : 'Sin título',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (element.content.isNotEmpty)
                    Text(
                      element.content,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
              ),
            ),
            // Author badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: authorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  element.authorInitial,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _authorColor() {
    final uid = (element.userId ?? '').toLowerCase();
    if (uid.contains('facu')) return _accentFacu;
    if (uid.contains('rocio')) return _accentRocio;
    return _accentFacu;
  }

  Color _typeColor(String type) {
    switch (type) {
      case BoardElementType.note:
        return const Color(0xFF39FF14);
      case BoardElementType.checklist:
        return const Color(0xFFFFD700);
      case BoardElementType.drawing:
        return const Color(0xFFFF6B00);
      case BoardElementType.video:
        return const Color(0xFFFF0000);
      case BoardElementType.audio:
        return const Color(0xFFFFD700);
      case BoardElementType.connector:
        return const Color(0xFF00F0FF);
      default:
        return const Color(0xFF9D00FF);
    }
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
      default:
        return Icons.note;
    }
  }
}
