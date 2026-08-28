import 'package:flutter/material.dart';

import '../chat_style.dart';

/// Swipe horizontal acumulado (WhatsApp-like) en CUALQUIER mensaje.
class ChatSwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  const ChatSwipeToReply({super.key, required this.child, required this.onReply});

  @override
  State<ChatSwipeToReply> createState() => _ChatSwipeToReplyState();
}

class _ChatSwipeToReplyState extends State<ChatSwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _dx = 0;
  static const _max = 72.0;
  static const _threshold = 42.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      if (_ctrl.isAnimating) {
        setState(() => _dx = _ctrl.value * _max);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snapBack() {
    final from = _dx;
    if (from <= 0) return;
    _ctrl.value = from / _max;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx / _threshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _ctrl.stop();
        setState(() => _dx = 0);
      },
      onHorizontalDragUpdate: (d) {
        setState(() {
          _dx = (_dx + d.delta.dx).clamp(0.0, _max);
        });
      },
      onHorizontalDragEnd: (_) {
        final trigger = _dx >= _threshold;
        _snapBack();
        if (trigger) widget.onReply();
      },
      onHorizontalDragCancel: _snapBack,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Opacity(
            opacity: progress,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.reply,
                  color: ChatStyle.primary.withValues(alpha: progress), size: 22),
            ),
          ),
          Transform.translate(
            offset: Offset(_dx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}