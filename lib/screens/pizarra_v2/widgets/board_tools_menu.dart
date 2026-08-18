import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app_state.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

class BoardToolsMenu extends StatefulWidget {
  final VoidCallback onCreateNote;
  final VoidCallback onCreateChecklist;
  final VoidCallback onCreateDrawing;
  final VoidCallback onCreateVideo;
  final VoidCallback onCreateAudio;
  final VoidCallback onCreateConnector;
  final VoidCallback onCreateSubBoard;
  final VoidCallback onCreateSeparator;

  const BoardToolsMenu({
    super.key,
    required this.onCreateNote,
    required this.onCreateChecklist,
    required this.onCreateDrawing,
    required this.onCreateVideo,
    required this.onCreateAudio,
    required this.onCreateConnector,
    required this.onCreateSubBoard,
    required this.onCreateSeparator,
  });

  @override
  State<BoardToolsMenu> createState() => _BoardToolsMenuState();
}

class _BoardToolsMenuState extends State<BoardToolsMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isOpen) ...[
            _ToolItem(
              icon: Icons.note_add,
              label: 'Nota',
              color: const Color(0xFF39FF14),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateNote();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.checklist,
              label: 'Checklist',
              color: const Color(0xFFFFD700),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateChecklist();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.draw,
              label: 'Dibujo',
              color: const Color(0xFFFF6B00),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateDrawing();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.videocam,
              label: 'Video',
              color: const Color(0xFFFF0000),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateVideo();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.mic,
              label: 'Audio',
              color: const Color(0xFFFFD700),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateAudio();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.timeline,
              label: 'Conector',
              color: const Color(0xFF00F0FF),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateConnector();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.folder,
              label: 'Sub-tablero',
              color: const Color(0xFFCE93D8),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateSubBoard();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
            _ToolItem(
              icon: Icons.remove,
              label: 'Separador',
              color: const Color(0xFF9D00FF),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCreateSeparator();
                _toggle();
              },
            ),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: _toggle,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _userColor(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _userColor(), width: 2),
                ),
                child: Icon(
                  _isOpen ? Icons.close : Icons.add,
                  color: const Color(0xFF0A0A0A),
                  size: 28,
                ),
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
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: const Color(0xFF0A0A0A), size: 22),
      ),
    );
  }
}
