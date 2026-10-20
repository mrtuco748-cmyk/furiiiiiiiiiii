import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/board_element.dart';
import '../milanote_colors.dart';
import 'card/milanote_card_body.dart';
import 'card/milanote_card_header.dart';
import 'card/milanote_card_toolbar.dart';

/// Tarjeta de elemento de Milanote con edición directa e inline
/// y arrastre fluido local a 60/120 FPS sin lag.
class MilanoteElementCard extends StatefulWidget {
  final BoardElement element;
  final double canvasScale;
  final bool isSelected;
  final bool isConnectingSource;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final Function(double worldDx, double worldDy, double totalDx, double totalDy) onDragUpdate;
  final Function(double totalDx, double totalDy) onDragEnd;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onStartConnect;
  final Function(BoardElement) onUpdate;
  final Function(int subBoardId, String title)? onOpenSubBoard;

  const MilanoteElementCard({
    super.key,
    required this.element,
    this.canvasScale = 1.0,
    required this.isSelected,
    this.isConnectingSource = false,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDelete,
    required this.onDuplicate,
    required this.onStartConnect,
    required this.onUpdate,
    this.onOpenSubBoard,
  });

  @override
  State<MilanoteElementCard> createState() => _MilanoteElementCardState();
}

class _MilanoteElementCardState extends State<MilanoteElementCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  Timer? _debounceTimer;

  bool _isEditing = false;
  double _dragLocalDx = 0.0;
  double _dragLocalDy = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.element.title);
    _contentCtrl = TextEditingController(text: widget.element.content);
  }

  @override
  void didUpdateWidget(MilanoteElementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.id != widget.element.id) {
      _titleCtrl.text = widget.element.title;
      _contentCtrl.text = widget.element.content;
      _isEditing = false;
    } else if (oldWidget.isSelected && !widget.isSelected) {
      if (_isEditing) {
        _saveChanges();
        _isEditing = false;
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    _debounceTimer?.cancel();
    widget.onUpdate(widget.element.copyWith(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
    ));
  }

  void _finishEditing() {
    FocusScope.of(context).unfocus();
    _saveChanges();
    setState(() => _isEditing = false);
  }

  void _startEditing() {
    HapticFeedback.lightImpact();
    widget.onTap();
    setState(() => _isEditing = true);
  }

  void _handleDragStart() {
    _isDragging = true;
    _dragLocalDx = 0.0;
    _dragLocalDy = 0.0;
    widget.onDragStart();
    widget.onTap();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final scale = widget.canvasScale > 0 ? widget.canvasScale : 1.0;
    final worldDx = details.delta.dx / scale;
    final worldDy = details.delta.dy / scale;

    setState(() {
      _dragLocalDx += worldDx;
      _dragLocalDy += worldDy;
    });

    widget.onDragUpdate(worldDx, worldDy, _dragLocalDx, _dragLocalDy);
  }

  void _handleDragEnd() {
    if (!_isDragging) return;
    final finalDx = _dragLocalDx;
    final finalDy = _dragLocalDy;
    setState(() {
      _isDragging = false;
      _dragLocalDx = 0.0;
      _dragLocalDy = 0.0;
    });
    widget.onDragEnd(finalDx, finalDy);
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      widget.onUpdate(widget.element.copyWith(
        title: _titleCtrl.text,
        content: _contentCtrl.text,
      ));
    });
  }

  void _changeColor(Color color) {
    widget.onUpdate(widget.element.copyWith(
      color: MilanotePalette.toHex(color),
    ));
  }

  void _toggleCardWidth() {
    HapticFeedback.selectionClick();
    final newWidth = widget.element.width > 260 ? 220.0 : 340.0;
    widget.onUpdate(widget.element.copyWith(width: newWidth));
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final bgColor = MilanotePalette.parseHex(
      el.color,
      defaultColor: MilanotePalette.noteYellow,
    );
    final isDark = bgColor.computeLuminance() < 0.45;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2024);

    return Positioned(
      left: el.x + _dragLocalDx,
      top: el.y + _dragLocalDy,
      child: RepaintBoundary(
        child: Container(
          width: el.width,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (widget.isConnectingSource)
                BoxShadow(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDragging ? 0.45 : (widget.isSelected ? 0.35 : 0.15),
                  ),
                  blurRadius: _isDragging ? 22 : (widget.isSelected ? 14 : 6),
                  offset: _isDragging ? const Offset(0, 8) : const Offset(0, 3),
                ),
            ],
          ),
          child: _isEditing
              ? _buildEditingCard(textColor, isDark)
              : _buildDraggableCard(textColor, isDark),
        ),
      ),
    );
  }

  Widget _buildDraggableCard(Color textColor, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startEditing,
      onPanStart: (_) => _handleDragStart(),
      onPanUpdate: _handleDragUpdate,
      onPanEnd: (_) => _handleDragEnd(),
      onPanCancel: _handleDragEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MilanoteCardDraggableHeader(
            type: widget.element.type,
            title: _titleCtrl.text,
            textColor: textColor,
            isDark: isDark,
            isSelected: widget.isSelected,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: MilanoteCardBody(
              element: widget.element,
              titleCtrl: _titleCtrl,
              contentCtrl: _contentCtrl,
              textColor: textColor,
              isEditing: false,
              onUpdate: widget.onUpdate,
              onOpenSubBoard: widget.onOpenSubBoard,
              onFieldChanged: _onFieldChanged,
            ),
          ),
          if (widget.isSelected)
            MilanoteCardToolbar(
              isDark: isDark,
              textColor: textColor,
              onToggleCardWidth: _toggleCardWidth,
              onStartConnect: widget.onStartConnect,
              onDuplicate: widget.onDuplicate,
              onDelete: widget.onDelete,
              onSelectColor: _changeColor,
            ),
        ],
      ),
    );
  }

  Widget _buildEditingCard(Color textColor, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MilanoteCardEditingHeader(
          type: widget.element.type,
          titleCtrl: _titleCtrl,
          textColor: textColor,
          isDark: isDark,
          onFinishEditing: _finishEditing,
          onFieldChanged: _onFieldChanged,
          onDragStart: _handleDragStart,
          onDragUpdate: _handleDragUpdate,
          onDragEnd: _handleDragEnd,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: MilanoteCardBody(
            element: widget.element,
            titleCtrl: _titleCtrl,
            contentCtrl: _contentCtrl,
            textColor: textColor,
            isEditing: true,
            onUpdate: widget.onUpdate,
            onOpenSubBoard: widget.onOpenSubBoard,
            onFieldChanged: _onFieldChanged,
          ),
        ),
        MilanoteCardToolbar(
          isDark: isDark,
          textColor: textColor,
          onToggleCardWidth: _toggleCardWidth,
          onStartConnect: widget.onStartConnect,
          onDuplicate: widget.onDuplicate,
          onDelete: widget.onDelete,
          onSelectColor: _changeColor,
        ),
      ],
    );
  }
}
