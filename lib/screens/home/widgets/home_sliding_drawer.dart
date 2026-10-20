import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

Widget tbLine({required Color color, required Color borderColor}) {
  return Container(
    width: 22,
    height: 14,
    margin: const EdgeInsets.symmetric(vertical: 3.5),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: borderColor, width: 2),
      borderRadius: BorderRadius.circular(7),
    ),
  );
}

class HomeTopSlidingDrawer extends StatelessWidget {
  final AnimationController controller;
  final ThemeSet theme;
  final double panelHeight;
  final double panelWidth;
  final double c1;
  final VoidCallback onClose;
  final GestureDragStartCallback onDragStart;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget child;

  const HomeTopSlidingDrawer({
    super.key,
    required this.controller,
    required this.theme,
    required this.panelHeight,
    required this.panelWidth,
    required this.c1,
    required this.onClose,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.value;
        final panelLeft = (progress - 1.0) * panelWidth;
        final cardLeft = progress * panelWidth;

        final topBtnColor = theme.d;
        final topDotColor = (topBtnColor == theme.a) ? theme.light : theme.a;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5 * progress),
                  ),
                ),
              ),
            ),
            Positioned(
              left: panelLeft,
              top: 0,
              width: panelWidth,
              height: panelHeight,
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onHorizontalDragStart: onDragStart,
                  onHorizontalDragUpdate: onDragUpdate,
                  onHorizontalDragEnd: onDragEnd,
                  child: child,
                ),
              ),
            ),
            Positioned(
              left: cardLeft,
              top: 0,
              width: c1,
              height: panelHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: onDragStart,
                  onHorizontalDragUpdate: onDragUpdate,
                  onHorizontalDragEnd: onDragEnd,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: topBtnColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dark, width: 2.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (_) => tbLine(color: topDotColor, borderColor: theme.dark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HomeBottomSlidingDrawer extends StatelessWidget {
  final AnimationController controller;
  final ThemeSet theme;
  final double panelHeight;
  final double panelWidth;
  final double c1;
  final VoidCallback onClose;
  final GestureDragStartCallback onDragStart;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget child;

  const HomeBottomSlidingDrawer({
    super.key,
    required this.controller,
    required this.theme,
    required this.panelHeight,
    required this.panelWidth,
    required this.c1,
    required this.onClose,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.value;
        final panelLeft = (progress - 1.0) * panelWidth;
        final cardLeft = progress * panelWidth;

        final bottomBtnColor = theme.b;
        final bottomDotColor = (bottomBtnColor == theme.a) ? theme.d : theme.a;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5 * progress),
                  ),
                ),
              ),
            ),
            Positioned(
              left: panelLeft,
              top: panelHeight,
              width: panelWidth,
              height: panelHeight,
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onHorizontalDragStart: onDragStart,
                  onHorizontalDragUpdate: onDragUpdate,
                  onHorizontalDragEnd: onDragEnd,
                  child: child,
                ),
              ),
            ),
            Positioned(
              left: cardLeft,
              top: panelHeight,
              width: c1,
              height: panelHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: onDragStart,
                  onHorizontalDragUpdate: onDragUpdate,
                  onHorizontalDragEnd: onDragEnd,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bottomBtnColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dark, width: 2.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (_) => tbLine(color: bottomDotColor, borderColor: theme.dark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
