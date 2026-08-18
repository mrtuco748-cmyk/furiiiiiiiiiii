import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../app_state.dart';
import '../pizarra_screen_v2.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

class BoardHeader extends StatelessWidget {
  final BoardProviderV2 provider;
  final bool searchOpen;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleActivity;
  final Function(BoardViewMode) onViewModeChanged;
  final VoidCallback onToggleTagManager;
  final BoardViewMode currentViewMode;

  const BoardHeader({
    super.key,
    required this.provider,
    required this.searchOpen,
    required this.onToggleSearch,
    required this.onToggleActivity,
    required this.onViewModeChanged,
    required this.onToggleTagManager,
    required this.currentViewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 8,
      right: 12,
      height: 48,
      child: Row(
        children: [
          // Nombre del tablero
          GestureDetector(
            onTap: _showViewModeMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _viewModeIcon(),
                    color: _userColor(),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentViewMode == BoardViewMode.canvas
                        ? provider.boardName
                        : _viewModeLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _userColor(),
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Indicador online/offline
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: provider.isOnline ? const Color(0xFF4CAF50) : const Color(0xFFFF5757),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Tags
          GestureDetector(
            onTap: onToggleTagManager,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              ),
              child: Icon(
                Icons.label,
                color: _userColor(),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Actividad
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleActivity();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              ),
              child: Icon(
                Icons.history,
                color: _userColor(),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Búsqueda
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleSearch();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: searchOpen ? _userColor() : const Color(0xFF1A1A1A),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.search,
                color: _userColor(),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _userColor() {
    final identity = (AppState.identity ?? '').toLowerCase();
    if (identity.contains('facu')) return _accentFacu;
    if (identity.contains('rocio')) return _accentRocio;
    return _accentFacu;
  }

  IconData _viewModeIcon() {
    switch (currentViewMode) {
      case BoardViewMode.canvas:
        return Icons.dashboard;
      case BoardViewMode.list:
        return Icons.view_list;
      case BoardViewMode.timeline:
        return Icons.timeline;
      case BoardViewMode.archived:
        return Icons.archive;
    }
  }

  String _viewModeLabel() {
    switch (currentViewMode) {
      case BoardViewMode.canvas:
        return 'Pizarra';
      case BoardViewMode.list:
        return 'Lista';
      case BoardViewMode.timeline:
        return 'Timeline';
      case BoardViewMode.archived:
        return 'Archivados';
    }
  }

  void _showViewModeMenu() {
    // Simple toggle: canvas -> list -> timeline -> archived -> canvas
    final next = {
      BoardViewMode.canvas: BoardViewMode.list,
      BoardViewMode.list: BoardViewMode.timeline,
      BoardViewMode.timeline: BoardViewMode.archived,
      BoardViewMode.archived: BoardViewMode.canvas,
    }[currentViewMode]!;
    onViewModeChanged(next);
  }
}
