import 'package:flutter/material.dart';

import 'note_style_config.dart';

class NoteStyleSerializer {
  static Map<String, dynamic> toDataMap(NoteStyleConfig c) {
    final encodedOverrides = <String, dynamic>{};
    c.paragraphOverrides.forEach((k, v) {
      encodedOverrides[k.toString()] = v.toMap();
    });

    return {
      'baseMode': c.baseMode,
      'solidColor': c.solidColor,
      'gradientStartColor': c.gradientStartColor,
      'gradientMidColor': c.gradientMidColor,
      'gradientEndColor': c.gradientEndColor,
      'gradientAngle': c.gradientAngle,
      if (c.bgImageBase64 != null) 'bgImageBase64': c.bgImageBase64,
      if (c.bgImageUrl != null) 'bgImageUrl': c.bgImageUrl,
      'bgImageOpacity': c.bgImageOpacity,
      'patternType': c.patternType.name,
      'patternColor1': c.patternColor1,
      'patternColor2': c.patternColor2,
      'patternUseGradient': c.patternUseGradient,
      'patternOpacity': c.patternOpacity,
      'patternStrokeWidth': c.patternStrokeWidth,
      'patternSpacing': c.patternSpacing,
      'patternScale': c.patternScale,
      'patternEmojiText': c.patternEmojiText,
      'shapeType': c.shapeType.name,
      'borderType': c.borderType.name,
      'borderColor': c.borderColor,
      'borderWidth': c.borderWidth,
      'borderSpacing': c.borderSpacing,
      'hasShine': c.hasShine,
      'titleFont': c.titleFont,
      'titleColor': c.titleColor,
      'titleSize': c.titleSize,
      'titleFormat': c.titleFormat.name,
      'bodyFont': c.bodyFont,
      'bodyColor': c.bodyColor,
      'bodySize': c.bodySize,
      'bodyFormat': c.bodyFormat.name,
      'textAlign': c.textAlign.name,
      'paragraphOverrides': encodedOverrides,
      if (c.inlineImageBase64 != null)
        'inlineImageBase64': c.inlineImageBase64,
      if (c.inlineImageUrl != null) 'inlineImageUrl': c.inlineImageUrl,
      'inlineImagePosition': c.inlineImagePosition.name,
      'inlineImageHeightRatio': c.inlineImageHeightRatio,
      'items': c.checklistItems,
    };
  }

  static NoteStyleConfig fromElement({
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

    final String? legacyBase64 = data['imageBase64'] as String?;
    final String? legacyUrl = data['imageUrl'] as String?;

    final shapeName = data['shapeType']?.toString() ?? 'rounded';
    final shape = NoteShapeType.values.firstWhere(
      (e) => e.name == shapeName,
      orElse: () => NoteShapeType.rounded,
    );

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
