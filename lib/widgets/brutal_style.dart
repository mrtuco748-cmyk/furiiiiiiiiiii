import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'concrete_painter.dart';
import 'tap_tile.dart';

// Estilo compartido "Nosotros" para todas las pantallas de F.U.R.I.
// Sistema brutalista modificado: fondo ConcretePainter, bloques con
// esquinas redondeadas, borde == color de fondo, sombra negra dura,
// tipografía Bangers y animaciones TapTile.
class BrutalStyle {
  BrutalStyle._();

  // Fondo de pantalla con textura de hormigón (debe ir dentro de un Stack/Positioned).
  static Widget bg(Color fallback) {
    return Positioned.fill(
      child: CustomPaint(painter: ConcretePainter()),
    );
  }

  // Icono que se adapta al tamaño del contenedor.
  static Widget fillIcon(IconData icon, Color color) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)),
    );
  }

  // Decoración base de un bloque/card brutalista.
  static BoxDecoration decoration(Color color, {int bw = 3, BorderRadius? radius, Offset shadow = const Offset(5, 5)}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: color, width: bw.toDouble()),
      borderRadius: radius ?? BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: const Color(0xFF000000), offset: shadow, blurRadius: 0)],
    );
  }

  // Bloque posicionado (compatible con el layout de Nosotros).
  static Widget block(
    double l, double t, double w, double h, Color color, Widget child,
    VoidCallback? onTap, {
    int bw = 3,
    double rot = 0,
    BorderRadius? radius,
  }) {
    final content = clip(color, child, bw: bw, radius: radius, rot: rot);
    return Positioned(
      left: l, top: t, width: w, height: h,
      child: onTap != null
          ? TapTile(onTap: () { HapticFeedback.heavyImpact(); onTap(); }, child: content)
          : content,
    );
  }

  // Card/panel brutalista para layouts flexibles (no posicionado).
  static Widget card(
    Color color,
    Widget child, {
    VoidCallback? onTap,
    int bw = 3,
    BorderRadius? radius,
    EdgeInsets padding = EdgeInsets.zero,
    bool tappable = true,
  }) {
    final content = Padding(
      padding: padding,
      child: child,
    );
    final decorated = Container(
      decoration: decoration(color, bw: bw, radius: radius),
      child: content,
    );
    if (onTap == null || !tappable) return decorated;
    return TapTile(onTap: () { HapticFeedback.heavyImpact(); onTap(); }, child: decorated);
  }

  // Recorta y decora el contenido (sombra + borde + rotación opcional).
  static Widget clip(Color color, Widget child, {int bw = 3, BorderRadius? radius, double rot = 0}) {
    final content = ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(18),
      child: Container(decoration: decoration(color, bw: bw, radius: radius), child: child),
    );
    return rot != 0
        ? Transform.rotate(angle: rot, alignment: Alignment.center, child: content)
        : content;
  }

  // Botón de acción con icono siguiendo el sistema brutalista.
  static Widget iconAction({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    Color? iconColor,
    double size = 20,
    double pad = 8,
    BorderRadius? radius,
  }) {
    return TapTile(
      onTap: () { HapticFeedback.heavyImpact(); onTap(); },
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius ?? BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: size),
      ),
    );
  }
}