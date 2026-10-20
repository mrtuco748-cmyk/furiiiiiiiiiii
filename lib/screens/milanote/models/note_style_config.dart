import 'package:flutter/material.dart';

import 'note_style_serializer.dart';
import 'note_style_types.dart';

export 'note_style_types.dart';
export 'pizarron_font_catalog.dart';
export 'pizarron_palette.dart';

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
  final double patternStrokeWidth; // Grosor
  final double patternSpacing; // Espaciado
  final double patternScale; // Tamaño de bloque / radio de círculo / tamaño emoji
  final String patternEmojiText; // Emoji o texto para el patrón

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
      case NotePatternType.chess:
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

  bool get patternSupportsFillToggle =>
      patternType == NotePatternType.circlesFilled ||
      patternType == NotePatternType.circlesEmpty;

  bool get patternSupportsEmojiInput => patternType == NotePatternType.emoji;

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

  Map<String, dynamic> toDataMap() => NoteStyleSerializer.toDataMap(this);

  factory NoteStyleConfig.fromElement({
    required String fallbackColor,
    required Map<String, dynamic> data,
  }) =>
      NoteStyleSerializer.fromElement(
        fallbackColor: fallbackColor,
        data: data,
      );
}
