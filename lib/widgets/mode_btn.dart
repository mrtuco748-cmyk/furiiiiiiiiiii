import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeBtn extends StatelessWidget {
  final AppMode mode;
  final IconData icon;
  final bool active;
  final void Function(AppMode, Offset) onTap;
  final Color? iconColor;

  const ModeBtn(this.mode, this.icon, this.active, this.onTap, {super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final t = appThemes[mode]!;
    Offset? downPos;
    return GestureDetector(
      onTapDown: (d) => downPos = d.globalPosition,
      onTap: () => onTap(mode, downPos ?? Offset.zero),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active ? t.light : t.a,
          border: Border.all(color: t.dark, width: active ? 4 : 2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: active ? 20 : 14, color: iconColor ?? t.dark),
      ),
    );
  }
}
