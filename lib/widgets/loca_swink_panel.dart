import 'package:flutter/material.dart';

/// Contenedor animado con escala y opacidad para paneles desplegables (swink) en LocaScreen.
class LocaSwinkPanel extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final Alignment alignment;
  final Widget child;

  const LocaSwinkPanel({
    super.key,
    required this.controller,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.alignment,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return IgnorePointer(
          ignoring: controller.status == AnimationStatus.dismissed,
          child: Opacity(
            opacity: opacityAnimation.value,
            child: Transform.scale(
              scale: scaleAnimation.value,
              alignment: alignment,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
