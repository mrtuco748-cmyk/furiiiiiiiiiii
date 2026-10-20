import 'package:flutter/material.dart';

/// Entrada de una pantalla "loca" estilo Nosotros: un bloque gigante con icono
/// que ocupa una porción del lienzo. Al tocarlo puede:
///  - abrir un panel swink (si [panel] >= 0, indexando `LocaScreen.panels`),
///  - ejecutar una acción directa (si [onTap] != null),
///  - y/o mostrar contenido rotativo (swap) encima del icono.
/// [label] es el título corto del ítem (se muestra bajo el icono) y hace que
/// el arranger le dé un bloque más grande cuanto más texto tiene.
class LocaEntry {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final int panel;
  final VoidCallback? onTap;
  final Future<void> Function(BuildContext context)? onTapAsync;
  final Widget Function(BuildContext)? swapBuilder;
  final Widget Function(BuildContext)? childBuilder;
  final bool autoPlaySwap;
  final bool isAction;
  final bool tapToSwap;
  final String? label;
  final double? weight;
  final Duration iconDuration;
  final Duration swapDuration;
  final Duration initialDelay;

  const LocaEntry({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    this.panel = -1,
    this.onTap,
    this.onTapAsync,
    this.swapBuilder,
    this.childBuilder,
    this.autoPlaySwap = false,
    this.isAction = false,
    this.tapToSwap = false,
    this.label,
    this.weight,
    this.iconDuration = const Duration(seconds: 4),
    this.swapDuration = const Duration(seconds: 7),
    this.initialDelay = const Duration(seconds: 4),
  });
}
