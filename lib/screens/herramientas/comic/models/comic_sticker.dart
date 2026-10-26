import 'package:flutter/material.dart';

/// Estilos visuales de renderizado para onomatopeyas SFX.
enum ComicSfxStyle {
  standard,
  extruded3D,
  neonGlow,
  speedLines,
  screentoneDots;

  String get label {
    switch (this) {
      case ComicSfxStyle.standard:
        return 'Contorno Manga';
      case ComicSfxStyle.extruded3D:
        return 'Relieve 3D';
      case ComicSfxStyle.neonGlow:
        return 'Resplandor Neón';
      case ComicSfxStyle.speedLines:
        return 'Líneas de Velocidad';
      case ComicSfxStyle.screentoneDots:
        return 'Sombra Trama';
    }
  }

  IconData get icon {
    switch (this) {
      case ComicSfxStyle.standard:
        return Icons.format_color_text;
      case ComicSfxStyle.extruded3D:
        return Icons.layers;
      case ComicSfxStyle.neonGlow:
        return Icons.wb_sunny_outlined;
      case ComicSfxStyle.speedLines:
        return Icons.flash_on;
      case ComicSfxStyle.screentoneDots:
        return Icons.grain;
    }
  }
}

/// Representa una onomatopeya o sticker de efecto de sonido manga (SFX).
class ComicSticker {
  final String id;
  final String text;
  final double x; // Normalizado 0.0 a 1.0
  final double y;
  final double rotation; // En radianes
  final double scale;
  final double fontSize;
  final String fontFamily;
  final ComicSfxStyle sfxStyle;
  final Color color;
  final Color outlineColor;

  ComicSticker({
    required this.id,
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = -0.15,
    this.scale = 1.0,
    this.fontSize = 34.0,
    this.fontFamily = 'Bangers',
    this.sfxStyle = ComicSfxStyle.standard,
    this.color = const Color(0xFFFFDE59),
    this.outlineColor = const Color(0xFF111111),
  });

  ComicSticker copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? rotation,
    double? scale,
    double? fontSize,
    String? fontFamily,
    ComicSfxStyle? sfxStyle,
    Color? color,
    Color? outlineColor,
  }) {
    return ComicSticker(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      sfxStyle: sfxStyle ?? this.sfxStyle,
      color: color ?? this.color,
      outlineColor: outlineColor ?? this.outlineColor,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'rotation': rotation,
    'scale': scale,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'sfxStyle': sfxStyle.name,
    'color': color.toARGB32(),
    'outlineColor': outlineColor.toARGB32(),
  };

  factory ComicSticker.fromMap(Map<String, dynamic> map) {
    return ComicSticker(
      id: map['id'] as String? ?? 'sfx_${DateTime.now().microsecondsSinceEpoch}',
      text: map['text'] as String? ?? '¡ZAS!',
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      rotation: (map['rotation'] as num?)?.toDouble() ?? -0.15,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 34.0,
      fontFamily: map['fontFamily'] as String? ?? 'Bangers',
      sfxStyle: ComicSfxStyle.values.firstWhere(
        (s) => s.name == (map['sfxStyle'] as String?),
        orElse: () => ComicSfxStyle.standard,
      ),
      color: Color(map['color'] as int? ?? 0xFFFFDE59),
      outlineColor: Color(map['outlineColor'] as int? ?? 0xFF111111),
    );
  }
}
