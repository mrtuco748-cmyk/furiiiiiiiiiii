import 'package:flutter/material.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../models/board_element_v2.dart';
import '../../../app_state.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

/// Vista de timeline cronológico de los elementos del pizarrón.
class BoardTimelineView extends StatelessWidget {
  final BoardProviderV2 provider;
  final Function(BoardElementV2) onGoToElement;

  const BoardTimelineView({
    super.key,
    required this.provider,
    required this.onGoToElement,
  });

  @override
  Widget build(BuildContext context) {
    final elements = List.of(provider.elements)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
        final isLast = index == elements.length - 1;

        return _TimelineItem(
          element: el,
          isLast: isLast,
          onTap: () => onGoToElement(el),
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BoardElementV2 element;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.element,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authorColor = _authorColor();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line + dot
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: authorColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF0A0A0A),
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  color: const Color(0xFF333333),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content card
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: type + date
                  Row(
                    children: [
                      Icon(
                        _typeIcon(element.type),
                        color: _typeColor(element.type),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _typeName(element.type),
                        style: TextStyle(
                          color: _typeColor(element.type),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(element.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  if (element.title.isNotEmpty)
                    Text(
                      element.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Content
                  if (element.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        element.content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Tags
                  if (element.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        children: element.tags
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
            ),
          ),
        ),
      ],
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

  String _typeName(String type) {
    switch (type) {
      case BoardElementType.note:
        return 'Nota';
      case BoardElementType.checklist:
        return 'Checklist';
      case BoardElementType.drawing:
        return 'Dibujo';
      case BoardElementType.video:
        return 'Video';
      case BoardElementType.audio:
        return 'Audio';
      case BoardElementType.connector:
        return 'Conector';
      default:
        return 'Elemento';
    }
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}
