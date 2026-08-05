import 'dart:math';
import 'package:flutter/material.dart';

class MoodDisplay extends StatefulWidget {
  final String emotion;
  final Color color;
  final double size;
  const MoodDisplay({super.key, required this.emotion, required this.color, this.size = 80});

  @override
  State<MoodDisplay> createState() => _MoodDisplayState();
}

class _MoodDisplayState extends State<MoodDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _pulse = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _rotation = Tween(begin: 0.0, end: 2 * pi).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.size * 0.35;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: _pulse.value,
          child: SizedBox(
            width: widget.size, height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * 0.6, height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                  ),
                ),
                Transform.translate(
                  offset: Offset(r * cos(_rotation.value), r * sin(_rotation.value)),
                  child: Transform.rotate(
                    angle: _rotation.value,
                    child: Text(widget.emotion,
                      style: TextStyle(
                        fontFamily: 'monospace', fontSize: widget.size * 0.1,
                        fontWeight: FontWeight.bold, color: widget.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
