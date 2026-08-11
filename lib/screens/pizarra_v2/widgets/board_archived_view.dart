import 'package:flutter/material.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../models/board_element_v2.dart';
import '../../../app_state.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

/// Vista de elementos archivados.
class BoardArchivedView extends StatelessWidget {
  final BoardProviderV2 provider;
  final Function(BoardElementV2) onRestore;

  const BoardArchivedView({
    super.key,
    required this.provider,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final elements = provider.archivedElements;

    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentFacu),
      );
    }

    if (elements.isEmpty) {
      return const Center(
        child: Text(
          'No hay elementos archivados',
          style: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: elements.length,
      itemBuilder: (context, index) {
        final el = elements[index];
        return _ArchivedItem(
          element: el,
          onRestore: () => onRestore(el),
        );
      },
    );
  }
}

class _ArchivedItem extends StatelessWidget {
  final BoardElementV2 element;
  final VoidCallback onRestore;

  const _ArchivedItem({
    required this.element,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final authorColor = _authorColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      child: Row(
        children: [
          // Archived icon
          const Icon(
            Icons.archive,
            color: Colors.white38,
            size: 20,
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
                    color: Colors.white54,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (element.content.isNotEmpty)
                  Text(
                    element.content,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    maxLines: 1,
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
              color: authorColor.withValues(alpha: 0.5),
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
          const SizedBox(width: 8),
          // Restore button
          GestureDetector(
            onTap: onRestore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Restaurar',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _authorColor() {
    final uid = (element.userId ?? '').toLowerCase();
    if (uid.contains('facu')) return _accentFacu;
    if (uid.contains('rocio')) return _accentRocio;
    return _accentFacu;
  }
}
