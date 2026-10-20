/// Posiciones posibles para la imagen integrada dentro de una nota.
enum InlineImagePosition {
  aboveBody, // Arriba del texto del cuerpo (debajo del título)
  middleBody, // En el medio de los párrafos del cuerpo
  belowBody, // Abajo del texto del cuerpo
  footer, // En el pie de página de la nota
}

/// Formatos decorativos para el título y párrafos.
enum TextBlockFormat {
  none, // Sin decoración extra
  escuadra, // Línea vertical derecha + línea horizontal inferior gruesa
  escuadraLeft, // Línea vertical izquierda + línea horizontal inferior gruesa
  thickUnderline, // Subrayado grueso
  topBottomLines, // Líneas arriba y abajo
  sunken, // Sombreado oscuro hundido (inset dark box)
  quoteBar, // Barra vertical lateral + fondo suave
  framed, // Marco completo de línea
}

/// Formas disponibles para la nota/tarjeta.
enum NoteShapeType {
  square, // Cuadrada recta
  rounded, // Bordes redondeados suaves
  note, // Nota con esquina inferior/superior doblada
  paper, // Hoja de papel con borde dentado suave
  leaf, // Forma de hoja (dos esquinas opuestas curvas, dos en punta)
  circle, // Círculo / elipse
  diamond, // Rombo
  hexagon, // Hexágono
  octagon, // Octágono
  shield, // Escudo
  tag, // Etiqueta recortada
}

/// Tipos de borde que siguen exactamente el contorno (Path) de la forma.
enum NoteBorderType {
  none,
  solid,
  dotted,
  dashed,
  doubleLine,
  wavy,
}

/// Tipos de patrones para la Capa 2 de la nota.
enum NotePatternType {
  none,
  chess, // Ajedrez (sin espaciado ni relleno, solo tamaño de bloque)
  linesOblique, // Líneas oblicuas (grosor, espaciado, sin relleno)
  linesHorizontal, // Líneas horizontales (grosor, espaciado, sin relleno)
  linesVertical, // Líneas verticales (grosor, espaciado, sin relleno)
  waves, // Ondas (grosor, espaciado, escala, sin relleno)
  circlesFilled, // Círculos rellenos (escala, espaciado)
  circlesEmpty, // Círculos vacíos (escala, espaciado, grosor)
  dots, // Puntos (escala, espaciado)
  grid, // Cuadrícula (grosor, espaciado)
  emoji, // Emojis o texto repetido en patrón (texto, escala, espaciado)
}

/// Estilo individual por párrafo para permitir múltiples fuentes, colores y formatos
/// (como el formato "hundido") dentro de un mismo cuerpo de nota.
class ParagraphStyleOverride {
  final String? fontFamily;
  final String? colorHex;
  final double? fontSize;
  final TextBlockFormat format;

  const ParagraphStyleOverride({
    this.fontFamily,
    this.colorHex,
    this.fontSize,
    this.format = TextBlockFormat.none,
  });

  ParagraphStyleOverride copyWith({
    String? fontFamily,
    String? colorHex,
    double? fontSize,
    TextBlockFormat? format,
  }) {
    return ParagraphStyleOverride(
      fontFamily: fontFamily ?? this.fontFamily,
      colorHex: colorHex ?? this.colorHex,
      fontSize: fontSize ?? this.fontSize,
      format: format ?? this.format,
    );
  }

  Map<String, dynamic> toMap() => {
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (colorHex != null) 'colorHex': colorHex,
        if (fontSize != null) 'fontSize': fontSize,
        'format': format.name,
      };

  factory ParagraphStyleOverride.fromMap(Map<String, dynamic> m) {
    return ParagraphStyleOverride(
      fontFamily: m['fontFamily'] as String?,
      colorHex: m['colorHex'] as String?,
      fontSize: (m['fontSize'] as num?)?.toDouble(),
      format: TextBlockFormat.values.firstWhere(
        (e) => e.name == m['format'],
        orElse: () => TextBlockFormat.none,
      ),
    );
  }
}
