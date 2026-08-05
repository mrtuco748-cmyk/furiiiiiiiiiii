import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class TapTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const TapTile({super.key, required this.child, required this.onTap});

  @override
  State<TapTile> createState() => TapTileState();
}

class TapTileState extends State<TapTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { SoundService().click(); widget.onTap(); _ctrl.forward(from: 0); },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          final s = _scale.value;
          final shadowShrink = (1.0 - (s - 1.0) / 0.12 * 0.4).clamp(0.6, 1.0);
          final shadowOff = const Offset(5, 5) * shadowShrink;
          return Transform.translate(
            offset: (const Offset(5, 5) - shadowOff) / 2,
            child: Transform.scale(scale: s, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
