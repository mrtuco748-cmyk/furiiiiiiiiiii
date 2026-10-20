import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Posiciones posibles para la imagen integrada dentro de una nota.
enum InlineImagePosition {
  aboveBody,  // Arriba del texto del cuerpo (debajo del título)
  middleBody, // En el medio de los párrafos del cuerpo
  belowBody,  // Abajo del texto del cuerpo
  footer,     // En el pie de página de la nota
}

/// Formatos decorativos para el título y párrafos.
enum TextBlockFormat {
  none,            // Sin decoración extra
  escuadra,        // Línea vertical derecha + línea horizontal inferior gruesa
  escuadraLeft,    // Línea vertical izquierda + línea horizontal inferior gruesa
  thickUnderline,  // Subrayado grueso
  topBottomLines,  // Líneas arriba y abajo
  sunken,          // Sombreado oscuro hundido (inset dark box)
  quoteBar,        // Barra vertical lateral + fondo suave
  framed,          // Marco completo de línea
}

/// Formas disponibles para la nota/tarjeta.
enum NoteShapeType {
  square,   // Cuadrada recta
  rounded,  // Bordes redondeados suaves
  note,     // Nota con esquina inferior/superior doblada
  paper,    // Hoja de papel con borde dentado suave
  leaf,     // Forma de hoja (dos esquinas opuestas curvas, dos en punta)
  circle,   // Círculo / elipse
  diamond,  // Rombo
  hexagon,  // Hexágono
  octagon,  // Octágono
  shield,   // Escudo
  tag,      // Etiqueta recortada
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
  chess,            // Ajedrez (sin espaciado ni relleno, solo tamaño de bloque)
  linesOblique,     // Líneas oblicuas (grosor, espaciado, sin relleno)
  linesHorizontal,  // Líneas horizontales (grosor, espaciado, sin relleno)
  linesVertical,    // Líneas verticales (grosor, espaciado, sin relleno)
  waves,            // Ondas (grosor, espaciado, escala, sin relleno)
  circlesFilled,    // Círculos rellenos (escala, espaciado)
  circlesEmpty,     // Círculos vacíos (escala, espaciado, grosor)
  dots,             // Puntos (escala, espaciado)
  grid,             // Cuadrícula (grosor, espaciado)
  emoji,            // Emojis o texto repetido en patrón (texto, escala, espaciado)
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

/// Configuración completa de capas, forma, bordes, tipografía e imagen de una Nota/Lista.
/// Se serializa dentro de `BoardElement.data` para sincronización transparente con SQLite y Supabase.
class NoteStyleConfig {
  // --- CAPA 1: FONDO BASE (Sólido, Degradado de 3 partes, o Foto) ---
  final String baseMode; // 'solid', 'gradient', 'image'
  final String solidColor;
  final String gradientStartColor;
  final String gradientMidColor;
  final String gradientEndColor;
  final double gradientAngle; // En grados: 0, 45, 90, 135, 180
  final String? bgImageBase64;
  final String? bgImageUrl;
  final double bgImageOpacity;

  // --- CAPA 2: PATRONES ---
  final NotePatternType patternType;
  final String patternColor1;
  final String patternColor2;
  final bool patternUseGradient;
  final double patternOpacity;
  final double patternStrokeWidth; // Grosor (para líneas, ondas, círculos vacíos, cuadrícula)
  final double patternSpacing;     // Espaciado (no aplica a ajedrez)
  final double patternScale;       // Tamaño de bloque / radio de círculo / tamaño emoji
  final String patternEmojiText;   // Emoji o texto para el patrón

  // --- CAPA 3: FORMA Y BORDES ---
  final NoteShapeType shapeType;
  final NoteBorderType borderType;
  final String borderColor;
  final double borderWidth;
  final double borderSpacing;
  final bool hasShine; // Efecto de brillo animado opcional

  // --- TIPOGRAFÍA Y FORMATOS DE TÍTULO Y CUERPO ---
  final String titleFont;
  final String titleColor;
  final double titleSize;
  final TextBlockFormat titleFormat;

  final String bodyFont;
  final String bodyColor;
  final double bodySize;
  final TextBlockFormat bodyFormat;
  final TextAlign textAlign;

  /// Overrides por índice de párrafo (0, 1, 2...) para permitir distintas fuentes,
  /// colores y formatos (ej. párrafo hundido) en el mismo texto.
  final Map<int, ParagraphStyleOverride> paragraphOverrides;

  // --- IMAGEN INTEGRADA EN LA NOTA ---
  final String? inlineImageBase64;
  final String? inlineImageUrl;
  final InlineImagePosition inlineImagePosition;
  final double inlineImageHeightRatio; // 0.20 a 0.55 de la altura de la tarjeta

  // --- LISTA DE TAREAS (CHECKLIST) ---
  final List<Map<String, dynamic>> checklistItems;

  const NoteStyleConfig({
    this.baseMode = 'solid',
    this.solidColor = '#1E2436',
    this.gradientStartColor = '#6A11CB',
    this.gradientMidColor = '#C41C8A',
    this.gradientEndColor = '#2575FC',
    this.gradientAngle = 135.0,
    this.bgImageBase64,
    this.bgImageUrl,
    this.bgImageOpacity = 0.85,
    this.patternType = NotePatternType.none,
    this.patternColor1 = '#FFFFFF',
    this.patternColor2 = '#00F5D4',
    this.patternUseGradient = false,
    this.patternOpacity = 0.22,
    this.patternStrokeWidth = 2.5,
    this.patternSpacing = 22.0,
    this.patternScale = 18.0,
    this.patternEmojiText = '✨',
    this.shapeType = NoteShapeType.rounded,
    this.borderType = NoteBorderType.none,
    this.borderColor = '#FFFFFF',
    this.borderWidth = 3.0,
    this.borderSpacing = 8.0,
    this.hasShine = false,
    this.titleFont = 'Plus Jakarta Sans',
    this.titleColor = '#FFFFFF',
    this.titleSize = 19.0,
    this.titleFormat = TextBlockFormat.none,
    this.bodyFont = 'Plus Jakarta Sans',
    this.bodyColor = '#E2E8F0',
    this.bodySize = 14.5,
    this.bodyFormat = TextBlockFormat.none,
    this.textAlign = TextAlign.left,
    this.paragraphOverrides = const {},
    this.inlineImageBase64,
    this.inlineImageUrl,
    this.inlineImagePosition = InlineImagePosition.belowBody,
    this.inlineImageHeightRatio = 0.34,
    this.checklistItems = const [],
  });

  /// Reglas contextuales de qué parámetros tienen sentido para el patrón seleccionado.
  bool get patternSupportsStrokeWidth {
    switch (patternType) {
      case NotePatternType.linesOblique:
      case NotePatternType.linesHorizontal:
      case NotePatternType.linesVertical:
      case NotePatternType.waves:
      case NotePatternType.circlesEmpty:
      case NotePatternType.grid:
        return true;
      case NotePatternType.none:
      case NotePatternType.chess:
      case NotePatternType.circlesFilled:
      case NotePatternType.dots:
      case NotePatternType.emoji:
        return false;
    }
  }

  bool get patternSupportsSpacing {
    switch (patternType) {
      case NotePatternType.none:
      case NotePatternType.chess: // Ajedrez: bloques juntos sin separación
        return false;
      case NotePatternType.linesOblique:
      case NotePatternType.linesHorizontal:
      case NotePatternType.linesVertical:
      case NotePatternType.waves:
      case NotePatternType.circlesFilled:
      case NotePatternType.circlesEmpty:
      case NotePatternType.dots:
      case NotePatternType.grid:
      case NotePatternType.emoji:
        return true;
    }
  }

  bool get patternSupportsScale {
    switch (patternType) {
      case NotePatternType.chess:
      case NotePatternType.waves:
      case NotePatternType.circlesFilled:
      case NotePatternType.circlesEmpty:
      case NotePatternType.dots:
      case NotePatternType.emoji:
        return true;
      case NotePatternType.none:
      case NotePatternType.linesOblique:
      case NotePatternType.linesHorizontal:
      case NotePatternType.linesVertical:
      case NotePatternType.grid:
        return false;
    }
  }

  bool get patternSupportsFillToggle {
    return patternType == NotePatternType.circlesFilled ||
        patternType == NotePatternType.circlesEmpty;
  }

  bool get patternSupportsEmojiInput {
    return patternType == NotePatternType.emoji;
  }

  bool get hasInlineImage =>
      (inlineImageBase64 != null && inlineImageBase64!.isNotEmpty) ||
      (inlineImageUrl != null && inlineImageUrl!.isNotEmpty);

  bool get hasBgImage =>
      (bgImageBase64 != null && bgImageBase64!.isNotEmpty) ||
      (bgImageUrl != null && bgImageUrl!.isNotEmpty);

  NoteStyleConfig copyWith({
    String? baseMode,
    String? solidColor,
    String? gradientStartColor,
    String? gradientMidColor,
    String? gradientEndColor,
    double? gradientAngle,
    String? bgImageBase64,
    bool clearBgImage = false,
    String? bgImageUrl,
    double? bgImageOpacity,
    NotePatternType? patternType,
    String? patternColor1,
    String? patternColor2,
    bool? patternUseGradient,
    double? patternOpacity,
    double? patternStrokeWidth,
    double? patternSpacing,
    double? patternScale,
    String? patternEmojiText,
    NoteShapeType? shapeType,
    NoteBorderType? borderType,
    String? borderColor,
    double? borderWidth,
    double? borderSpacing,
    bool? hasShine,
    String? titleFont,
    String? titleColor,
    double? titleSize,
    TextBlockFormat? titleFormat,
    String? bodyFont,
    String? bodyColor,
    double? bodySize,
    TextBlockFormat? bodyFormat,
    TextAlign? textAlign,
    Map<int, ParagraphStyleOverride>? paragraphOverrides,
    String? inlineImageBase64,
    bool clearInlineImage = false,
    String? inlineImageUrl,
    InlineImagePosition? inlineImagePosition,
    double? inlineImageHeightRatio,
    List<Map<String, dynamic>>? checklistItems,
  }) {
    return NoteStyleConfig(
      baseMode: baseMode ?? this.baseMode,
      solidColor: solidColor ?? this.solidColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientMidColor: gradientMidColor ?? this.gradientMidColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      bgImageBase64:
          clearBgImage ? null : (bgImageBase64 ?? this.bgImageBase64),
      bgImageUrl: clearBgImage ? null : (bgImageUrl ?? this.bgImageUrl),
      bgImageOpacity: bgImageOpacity ?? this.bgImageOpacity,
      patternType: patternType ?? this.patternType,
      patternColor1: patternColor1 ?? this.patternColor1,
      patternColor2: patternColor2 ?? this.patternColor2,
      patternUseGradient: patternUseGradient ?? this.patternUseGradient,
      patternOpacity: patternOpacity ?? this.patternOpacity,
      patternStrokeWidth: patternStrokeWidth ?? this.patternStrokeWidth,
      patternSpacing: patternSpacing ?? this.patternSpacing,
      patternScale: patternScale ?? this.patternScale,
      patternEmojiText: patternEmojiText ?? this.patternEmojiText,
      shapeType: shapeType ?? this.shapeType,
      borderType: borderType ?? this.borderType,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderSpacing: borderSpacing ?? this.borderSpacing,
      hasShine: hasShine ?? this.hasShine,
      titleFont: titleFont ?? this.titleFont,
      titleColor: titleColor ?? this.titleColor,
      titleSize: titleSize ?? this.titleSize,
      titleFormat: titleFormat ?? this.titleFormat,
      bodyFont: bodyFont ?? this.bodyFont,
      bodyColor: bodyColor ?? this.bodyColor,
      bodySize: bodySize ?? this.bodySize,
      bodyFormat: bodyFormat ?? this.bodyFormat,
      textAlign: textAlign ?? this.textAlign,
      paragraphOverrides: paragraphOverrides ?? this.paragraphOverrides,
      inlineImageBase64: clearInlineImage
          ? null
          : (inlineImageBase64 ?? this.inlineImageBase64),
      inlineImageUrl:
          clearInlineImage ? null : (inlineImageUrl ?? this.inlineImageUrl),
      inlineImagePosition: inlineImagePosition ?? this.inlineImagePosition,
      inlineImageHeightRatio:
          inlineImageHeightRatio ?? this.inlineImageHeightRatio,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }

  Map<String, dynamic> toDataMap() {
    final encodedOverrides = <String, dynamic>{};
    paragraphOverrides.forEach((k, v) {
      encodedOverrides[k.toString()] = v.toMap();
    });

    return {
      'baseMode': baseMode,
      'solidColor': solidColor,
      'gradientStartColor': gradientStartColor,
      'gradientMidColor': gradientMidColor,
      'gradientEndColor': gradientEndColor,
      'gradientAngle': gradientAngle,
      if (bgImageBase64 != null) 'bgImageBase64': bgImageBase64,
      if (bgImageUrl != null) 'bgImageUrl': bgImageUrl,
      'bgImageOpacity': bgImageOpacity,
      'patternType': patternType.name,
      'patternColor1': patternColor1,
      'patternColor2': patternColor2,
      'patternUseGradient': patternUseGradient,
      'patternOpacity': patternOpacity,
      'patternStrokeWidth': patternStrokeWidth,
      'patternSpacing': patternSpacing,
      'patternScale': patternScale,
      'patternEmojiText': patternEmojiText,
      'shapeType': shapeType.name,
      'borderType': borderType.name,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'borderSpacing': borderSpacing,
      'hasShine': hasShine,
      'titleFont': titleFont,
      'titleColor': titleColor,
      'titleSize': titleSize,
      'titleFormat': titleFormat.name,
      'bodyFont': bodyFont,
      'bodyColor': bodyColor,
      'bodySize': bodySize,
      'bodyFormat': bodyFormat.name,
      'textAlign': textAlign.name,
      'paragraphOverrides': encodedOverrides,
      if (inlineImageBase64 != null) 'inlineImageBase64': inlineImageBase64,
      if (inlineImageUrl != null) 'inlineImageUrl': inlineImageUrl,
      'inlineImagePosition': inlineImagePosition.name,
      'inlineImageHeightRatio': inlineImageHeightRatio,
      'items': checklistItems,
    };
  }

  factory NoteStyleConfig.fromElement({
    required String fallbackColor,
    required Map<String, dynamic> data,
  }) {
    final parsedOverrides = <int, ParagraphStyleOverride>{};
    final rawOverrides = data['paragraphOverrides'];
    if (rawOverrides is Map) {
      rawOverrides.forEach((key, value) {
        final idx = int.tryParse(key.toString());
        if (idx != null && value is Map) {
          parsedOverrides[idx] = ParagraphStyleOverride.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final rawItems = data['items'];
    final itemsList = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          itemsList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    // Compatibilidad hacia atrás con notas anteriores si tenían imageBase64
    final String? legacyBase64 = data['imageBase64'] as String?;
    final String? legacyUrl = data['imageUrl'] as String?;

    final shapeName = data['shapeType']?.toString() ?? 'rounded';
    final shape = NoteShapeType.values.firstWhere(
      (e) => e.name == shapeName,
      orElse: () => NoteShapeType.rounded,
    );

    // Si la forma es simétrica (rombo, círculo, hexágono, octágono, escudo),
    // centrar por defecto si no se especificó alineación.
    final defaultAlign = (shape == NoteShapeType.diamond ||
            shape == NoteShapeType.circle ||
            shape == NoteShapeType.hexagon ||
            shape == NoteShapeType.octagon ||
            shape == NoteShapeType.shield)
        ? TextAlign.center
        : TextAlign.left;

    final alignName = data['textAlign']?.toString();
    final align = alignName != null
        ? TextAlign.values.firstWhere(
            (e) => e.name == alignName,
            orElse: () => defaultAlign,
          )
        : defaultAlign;

    return NoteStyleConfig(
      baseMode: data['baseMode']?.toString() ?? 'solid',
      solidColor: data['solidColor']?.toString() ??
          (fallbackColor.isNotEmpty ? fallbackColor : '#1E2436'),
      gradientStartColor:
          data['gradientStartColor']?.toString() ?? '#6A11CB',
      gradientMidColor: data['gradientMidColor']?.toString() ?? '#C41C8A',
      gradientEndColor: data['gradientEndColor']?.toString() ?? '#2575FC',
      gradientAngle:
          (data['gradientAngle'] as num?)?.toDouble() ?? 135.0,
      bgImageBase64: data['bgImageBase64'] as String?,
      bgImageUrl: data['bgImageUrl'] as String?,
      bgImageOpacity:
          (data['bgImageOpacity'] as num?)?.toDouble() ?? 0.85,
      patternType: NotePatternType.values.firstWhere(
        (e) => e.name == data['patternType'],
        orElse: () => NotePatternType.none,
      ),
      patternColor1: data['patternColor1']?.toString() ?? '#FFFFFF',
      patternColor2: data['patternColor2']?.toString() ?? '#00F5D4',
      patternUseGradient: data['patternUseGradient'] == true,
      patternOpacity:
          (data['patternOpacity'] as num?)?.toDouble() ?? 0.22,
      patternStrokeWidth:
          (data['patternStrokeWidth'] as num?)?.toDouble() ?? 2.5,
      patternSpacing:
          (data['patternSpacing'] as num?)?.toDouble() ?? 22.0,
      patternScale: (data['patternScale'] as num?)?.toDouble() ?? 18.0,
      patternEmojiText: data['patternEmojiText']?.toString() ?? '✨',
      shapeType: shape,
      borderType: NoteBorderType.values.firstWhere(
        (e) => e.name == data['borderType'],
        orElse: () => NoteBorderType.none,
      ),
      borderColor: data['borderColor']?.toString() ?? '#FFFFFF',
      borderWidth: (data['borderWidth'] as num?)?.toDouble() ?? 3.0,
      borderSpacing: (data['borderSpacing'] as num?)?.toDouble() ?? 8.0,
      hasShine: data['hasShine'] == true,
      titleFont: data['titleFont']?.toString() ??
          data['fontFamily']?.toString() ??
          'Plus Jakarta Sans',
      titleColor: data['titleColor']?.toString() ?? '#FFFFFF',
      titleSize: (data['titleSize'] as num?)?.toDouble() ?? 19.0,
      titleFormat: TextBlockFormat.values.firstWhere(
        (e) => e.name == data['titleFormat'],
        orElse: () => TextBlockFormat.none,
      ),
      bodyFont: data['bodyFont']?.toString() ??
          data['fontFamily']?.toString() ??
          'Plus Jakarta Sans',
      bodyColor: data['bodyColor']?.toString() ?? '#E2E8F0',
      bodySize: (data['bodySize'] as num?)?.toDouble() ??
          (data['fontSize'] as num?)?.toDouble() ??
          14.5,
      bodyFormat: TextBlockFormat.values.firstWhere(
        (e) => e.name == data['bodyFormat'],
        orElse: () => TextBlockFormat.none,
      ),
      textAlign: align,
      paragraphOverrides: parsedOverrides,
      inlineImageBase64:
          (data['inlineImageBase64'] as String?) ?? legacyBase64,
      inlineImageUrl: (data['inlineImageUrl'] as String?) ?? legacyUrl,
      inlineImagePosition: InlineImagePosition.values.firstWhere(
        (e) => e.name == data['inlineImagePosition'],
        orElse: () => InlineImagePosition.belowBody,
      ),
      inlineImageHeightRatio:
          (data['inlineImageHeightRatio'] as num?)?.toDouble() ?? 0.34,
      checklistItems: itemsList,
    );
  }
}

/// Catálogo de fuentes extravagantes, creativas y variadas para el Pizarrón.
class PizarronFontCatalog {
  static const List<String> fonts = [
    'Plus Jakarta Sans',
    'Space Mono',
    'Syne',
    'Pacifico',
    'Caveat',
    'Permanent Marker',
    'Press Start 2P',
    'Cinzel',
    'Abril Fatface',
    'Righteous',
    'Orbitron',
    'Monoton',
    'Bungee',
    'Creepster',
    'Special Elite',
    'Sacramento',
    'Shadows Into Light',
    'Bebas Neue',
    'Lobster',
    'UnifrakturMaguntia',
    'VT323',
    'Comfortaa',
  ];

  /// Glifo corto representativo para mostrar como ícono visual de cada fuente
  /// sin usar etiquetas de texto largas.
  static String glyphFor(String fontName) {
    switch (fontName) {
      case 'Plus Jakarta Sans':
        return 'Aa';
      case 'Space Mono':
        return '{}';
      case 'Syne':
        return 'Sy';
      case 'Pacifico':
        return 'ℱ';
      case 'Caveat':
        return '✎';
      case 'Permanent Marker':
        return '★';
      case 'Press Start 2P':
        return '8B';
      case 'Cinzel':
        return 'IV';
      case 'Abril Fatface':
        return 'Æ';
      case 'Righteous':
        return 'Rg';
      case 'Orbitron':
        return '01';
      case 'Monoton':
        return '≡';
      case 'Bungee':
        return 'BG';
      case 'Creepster':
        return '⚡';
      case 'Special Elite':
        return 'T!';
      case 'Sacramento':
        return '𝒮';
      case 'Shadows Into Light':
        return '♪';
      case 'Bebas Neue':
        return 'BB';
      case 'Lobster':
        return 'Lb';
      case 'UnifrakturMaguntia':
        return '𝔉';
      case 'VT323':
        return '>_';
      case 'Comfortaa':
        return '◯';
      default:
        return 'Aa';
    }
  }

  static TextStyle resolveFont(
    String fontName, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.3,
  }) {
    try {
      return GoogleFonts.getFont(
        fontName,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    }
  }
}

/// Paleta curada de colores vibrantes y oscuros (sin negro puro #000000).
class PizarronPalette {
  static const List<String> noteColors = [
    '#1E2436', // Slate profundo
    '#2B193D', // Violeta noche
    '#132A2E', // Petróleo oscuro
    '#3B1C32', // Borgoña oscuro
    '#1F2D1E', // Bosque oscuro
    '#33261E', // Tierra oscuro
    '#FF2A85', // Rosa fucsia vibrante
    '#7B2CBF', // Púrpura eléctrico
    '#3A86FF', // Azul intenso
    '#00BBF9', // Cian vibrante
    '#00F5D4', // Turquesa menta
    '#2EE50F', // Verde lima sólido
    '#FFB703', // Ámbar intenso
    '#FB5607', // Naranja fuego
    '#E63946', // Rojo coral
    '#FFF3B0', // Crema pastel cálido
    '#FDE2E4', // Rosa empolvado
    '#E2ECE9', // Menta hielo
    '#EAE4E9', // Lavanda suave
    '#FFFFFF', // Blanco puro
  ];

  static const List<String> boardColors = [
    '#141820', // Pizarra grafito (por defecto)
    '#18241E', // Pizarrón escolar verde oscuro
    '#1A162B', // Pizarra índigo profundo
    '#241A1E', // Pizarra ciruela oscuro
    '#16222F', // Pizarra azul marino
    '#26231F', // Pizarra carbón cálido
    '#2A3240', // Pizarra acero
    '#EDE9E0', // Lienzo papel crema
    '#E2E8F0', // Lienzo gris perla
  ];

  static const List<String> chalkColors = [
    '#FFFFFF', // Tiza blanca
    '#FFF3B0', // Tiza amarilla
    '#FF8FA3', // Tiza rosa
    '#80ED99', // Tiza verde
    '#72EFDD', // Tiza celeste
    '#C77DFF', // Tiza violeta
    '#FFB703', // Tiza naranja
  ];

  static Color parseHex(String hex, {Color fallback = const Color(0xFF1E2436)}) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final val = int.tryParse('FF$cleaned', radix: 16);
      if (val != null) return Color(val);
    } else if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }
}
