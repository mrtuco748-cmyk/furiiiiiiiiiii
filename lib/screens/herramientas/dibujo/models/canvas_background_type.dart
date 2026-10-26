import 'package:flutter/material.dart';

/// Tipos de fondo y tramas para el lienzo de dibujo y cómic.
enum CanvasBackgroundType {
  blank,
  grid,
  dots,
  dark;

  String get displayName {
    switch (this) {
      case CanvasBackgroundType.blank:
        return 'Blanco';
      case CanvasBackgroundType.grid:
        return 'Cuadrícula';
      case CanvasBackgroundType.dots:
        return 'Trama Puntos';
      case CanvasBackgroundType.dark:
        return 'Modo Oscuro';
    }
  }

  Color get color {
    switch (this) {
      case CanvasBackgroundType.dark:
        return const Color(0xFF1E1E1E);
      default:
        return const Color(0xFFFFFFFF);
    }
  }
}
