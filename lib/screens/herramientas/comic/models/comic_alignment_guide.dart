/// Orientación de la línea guía de alineación inteligente (Canva / Figma).
enum ComicGuideOrientation {
  horizontal,
  vertical,
}

/// Tipo de objetivo al que se alinea el elemento.
enum ComicGuideType {
  pageCenter,
  pageMargin,
  elementCenter,
  elementEdge,
}

/// Guía magnética de alineación inteligente en lienzo de cómic.
class ComicAlignmentGuide {
  final double position; // Posición en píxeles de la página (X para vertical, Y para horizontal)
  final ComicGuideOrientation orientation;
  final ComicGuideType type;
  final String? label;

  const ComicAlignmentGuide({
    required this.position,
    required this.orientation,
    required this.type,
    this.label,
  });

  bool get isPageCenter => type == ComicGuideType.pageCenter;
  bool get isVertical => orientation == ComicGuideOrientation.vertical;
  bool get isHorizontal => orientation == ComicGuideOrientation.horizontal;
}
