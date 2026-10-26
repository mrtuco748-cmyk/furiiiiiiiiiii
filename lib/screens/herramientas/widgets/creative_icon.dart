import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renderizador de iconos vectoriales SVG para la suite de dibujo y cómic.
class CreativeIcon extends StatelessWidget {
  final String assetName;
  final Color color;
  final double size;
  final IconData? fallback;

  const CreativeIcon(
    this.assetName, {
    super.key,
    this.color = Colors.white,
    this.size = 20,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final path = 'Assets/icons/creative/$assetName.svg';
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (_) => fallback != null
          ? Icon(fallback, color: color, size: size)
          : SizedBox(width: size, height: size),
    );
  }
}
