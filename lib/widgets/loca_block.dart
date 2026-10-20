import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brutal_style.dart';
import 'loca_entry.dart';
import 'swap_widget.dart';

/// Bloque individual dispuesto dentro de LocaScreen.
class LocaBlock extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final int index;
  final LocaEntry entry;
  final bool forced;
  final VoidCallback onTap;

  const LocaBlock({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.index,
    required this.entry,
    required this.forced,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (entry.childBuilder != null) {
      child = entry.childBuilder!(context);
    } else if (entry.swapBuilder != null) {
      child = SwapWidget(
        autoPlay: entry.autoPlaySwap && !forced,
        iconDuration: entry.iconDuration,
        swapDuration: entry.swapDuration,
        initialDelay: entry.initialDelay,
        showSwap: entry.tapToSwap && forced ? true : null,
        iconChild: _iconWithLabel(entry),
        swapChild: entry.swapBuilder!(context),
      );
    } else {
      child = _iconWithLabel(entry);
    }
    return BrutalStyle.block(
      left,
      top,
      width,
      height,
      entry.color,
      child,
      onTap,
      rot: 0,
    );
  }

  static Widget _iconWithLabel(LocaEntry e) {
    final icon = BrutalStyle.fillIcon(e.icon, e.iconColor);
    final title = e.label;
    if (title == null || title.isEmpty) return icon;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: icon),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bangers(
              color: e.iconColor,
              fontSize: 13,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
