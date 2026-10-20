import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

/// Header superior para la pantalla de Ejercicios
class EjerciciosHeader extends StatelessWidget {
  final double w;
  final double h;
  final int tab;
  final bool isPopup;
  final VoidCallback onPop;

  const EjerciciosHeader({
    super.key,
    required this.w,
    required this.h,
    required this.tab,
    required this.isPopup,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final Color headerColor;
    final IconData headerIcon;
    final String headerTitle;
    if (isPopup) {
      switch (tab) {
        case 0:
          headerColor = EjerciciosStyle.lime;
          headerIcon = Icons.today;
          headerTitle = 'HOY';
          break;
        case 1:
          headerColor = EjerciciosStyle.cyan;
          headerIcon = Icons.fitness_center;
          headerTitle = 'EJERCICIOS';
          break;
        case 2:
          headerColor = EjerciciosStyle.yellow;
          headerIcon = Icons.emoji_events;
          headerTitle = 'RETOS';
          break;
        default:
          headerColor = EjerciciosStyle.pink;
          headerIcon = Icons.bar_chart;
          headerTitle = 'ESTADÍSTICAS';
          break;
      }
    } else {
      headerColor = EjerciciosStyle.lime;
      headerIcon = Icons.fitness_center;
      headerTitle = 'EJERCICIOS';
    }

    return Container(
      height: h * 0.075,
      margin: EdgeInsets.all(w * 0.02),
      decoration: EjerciciosStyle.panelDeco(
        color: headerColor,
        radius: 18,
        bw: 3,
      ),
      child: Row(
        children: [
          TapTile(
            onTap: onPop,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                isPopup ? Icons.close : Icons.arrow_back,
                color: EjerciciosStyle.darkText,
                size: 26,
              ),
            ),
          ),
          Icon(headerIcon, color: EjerciciosStyle.darkText, size: 24),
          const SizedBox(width: 8),
          Text(
            headerTitle,
            style: GoogleFonts.bangers(
              color: EjerciciosStyle.darkText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

/// Barra de pestañas (HOY, EJERCICIOS, RETOS, STATS)
class EjerciciosTabsBar extends StatelessWidget {
  final double w;
  final double h;
  final int currentTab;
  final ValueChanged<int> onTabSelected;

  const EjerciciosTabsBar({
    super.key,
    required this.w,
    required this.h,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.today, 'HOY'),
      (Icons.fitness_center, 'EJERCICIOS'),
      (Icons.flag, 'RETOS'),
      (Icons.bar_chart, 'STATS'),
    ];
    return Container(
      height: h * 0.055,
      margin: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(child: _tabBtn(tabs[i].$1, tabs[i].$2, i)),
            if (i < tabs.length - 1) SizedBox(width: w * 0.012),
          ],
        ],
      ),
    );
  }

  Widget _tabBtn(IconData icon, String label, int index) {
    final selected = currentTab == index;
    return TapTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTabSelected(index);
      },
      child: Container(
        decoration: EjerciciosStyle.panelDeco(
          color: selected ? EjerciciosStyle.lime : EjerciciosStyle.panel,
          radius: 12,
          bw: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? EjerciciosStyle.darkText : EjerciciosStyle.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(
                  color: selected ? EjerciciosStyle.darkText : EjerciciosStyle.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
