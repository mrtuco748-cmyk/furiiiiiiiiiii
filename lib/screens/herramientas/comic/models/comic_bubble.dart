import 'package:flutter/material.dart';

/// Dirección de la cola del globo de diálogo.
enum ComicTailDirection {
  bottom,
  top,
  left,
  right,
  none;

  String get label {
    switch (this) {
      case ComicTailDirection.bottom:
        return 'Abajo';
      case ComicTailDirection.top:
        return 'Arriba';
      case ComicTailDirection.left:
        return 'Izquierda';
      case ComicTailDirection.right:
        return 'Derecha';
      case ComicTailDirection.none:
        return 'Sin cola';
    }
  }

  IconData get icon {
    switch (this) {
      case ComicTailDirection.bottom:
        return Icons.arrow_downward;
      case ComicTailDirection.top:
        return Icons.arrow_upward;
      case ComicTailDirection.left:
        return Icons.arrow_back;
      case ComicTailDirection.right:
        return Icons.arrow_forward;
      case ComicTailDirection.none:
        return Icons.remove_circle_outline;
    }
  }
}

/// Tipos de globos de diálogo profesionales para cómics y mangas.
enum ComicBubbleType {
  mangaOval,
  screamSpiky,
  thoughtCloud,
  narratorBox,
  whisperDotted,
  furiChat,
  electricShonen,
  dizzyWavy,
  shoujoHeart,
  impactExplosion,
  cyberHexagon,
  wideWebtoon;

  String get displayName {
    switch (this) {
      case ComicBubbleType.mangaOval:
        return 'Manga Clásico';
      case ComicBubbleType.screamSpiky:
        return 'Grito / Acción';
      case ComicBubbleType.thoughtCloud:
        return 'Pensamiento';
      case ComicBubbleType.narratorBox:
        return 'Narrador';
      case ComicBubbleType.whisperDotted:
        return 'Susurro';
      case ComicBubbleType.furiChat:
        return 'Chat F.U.R.I';
      case ComicBubbleType.electricShonen:
        return 'Eléctrico / Radio';
      case ComicBubbleType.dizzyWavy:
        return 'Temblor / Duda';
      case ComicBubbleType.shoujoHeart:
        return 'Shojo Romántico';
      case ComicBubbleType.impactExplosion:
        return 'Impacto Cósmico';
      case ComicBubbleType.cyberHexagon:
        return 'Hexágono Sci-Fi';
      case ComicBubbleType.wideWebtoon:
        return 'Webtoon Suave';
    }
  }

  String get label => displayName;

  IconData get icon {
    switch (this) {
      case ComicBubbleType.mangaOval:
        return Icons.chat_bubble_outline;
      case ComicBubbleType.screamSpiky:
        return Icons.flash_on;
      case ComicBubbleType.thoughtCloud:
        return Icons.cloud_outlined;
      case ComicBubbleType.narratorBox:
        return Icons.crop_portrait;
      case ComicBubbleType.whisperDotted:
        return Icons.more_horiz;
      case ComicBubbleType.furiChat:
        return Icons.mark_chat_unread_outlined;
      case ComicBubbleType.electricShonen:
        return Icons.electric_bolt;
      case ComicBubbleType.dizzyWavy:
        return Icons.waves;
      case ComicBubbleType.shoujoHeart:
        return Icons.favorite_border;
      case ComicBubbleType.impactExplosion:
        return Icons.star_border;
      case ComicBubbleType.cyberHexagon:
        return Icons.hexagon_outlined;
      case ComicBubbleType.wideWebtoon:
        return Icons.crop_square_rounded;
    }
  }
}

/// Representa una burbuja de diálogo posicionable en la página del cómic.
class ComicBubble {
  final String id;
  final ComicBubbleType type;
  final String text;
  final double x; // Posición X normalizada (0.0 a 1.0)
  final double y; // Posición Y normalizada (0.0 a 1.0)
  final double width;
  final double height;
  final double tailX; // Desplazamiento de cola
  final double tailY;
  final ComicTailDirection tailDirection;
  final double rotation; // En radianes (-pi a pi)
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  ComicBubble({
    required this.id,
    this.type = ComicBubbleType.mangaOval,
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.width = 160.0,
    this.height = 90.0,
    this.tailX = 20.0,
    this.tailY = 50.0,
    this.tailDirection = ComicTailDirection.bottom,
    this.rotation = 0.0,
    this.fontFamily = 'Comic Neue',
    this.fontSize = 14.0,
    this.textColor = const Color(0xFF111111),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFF111111),
    this.borderWidth = 2.5,
  });

  ComicBubble copyWith({
    String? id,
    ComicBubbleType? type,
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    double? tailX,
    double? tailY,
    ComicTailDirection? tailDirection,
    double? rotation,
    String? fontFamily,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
  }) {
    return ComicBubble(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      tailX: tailX ?? this.tailX,
      tailY: tailY ?? this.tailY,
      tailDirection: tailDirection ?? this.tailDirection,
      rotation: rotation ?? this.rotation,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'text': text,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'tailX': tailX,
    'tailY': tailY,
    'tailDirection': tailDirection.name,
    'rotation': rotation,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'textColor': textColor.toARGB32(),
    'backgroundColor': backgroundColor.toARGB32(),
    'borderColor': borderColor.toARGB32(),
    'borderWidth': borderWidth,
  };

  factory ComicBubble.fromMap(Map<String, dynamic> map) {
    return ComicBubble(
      id: map['id'] as String? ?? 'bubble_${DateTime.now().microsecondsSinceEpoch}',
      type: ComicBubbleType.values.firstWhere(
        (t) => t.name == (map['type'] as String?),
        orElse: () => ComicBubbleType.mangaOval,
      ),
      text: map['text'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      width: (map['width'] as num?)?.toDouble() ?? 160.0,
      height: (map['height'] as num?)?.toDouble() ?? 90.0,
      tailX: (map['tailX'] as num?)?.toDouble() ?? 20.0,
      tailY: (map['tailY'] as num?)?.toDouble() ?? 50.0,
      tailDirection: ComicTailDirection.values.firstWhere(
        (d) => d.name == (map['tailDirection'] as String?),
        orElse: () => ComicTailDirection.bottom,
      ),
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      fontFamily: map['fontFamily'] as String? ?? 'Comic Neue',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 14.0,
      textColor: Color(map['textColor'] as int? ?? 0xFF111111),
      backgroundColor: Color(map['backgroundColor'] as int? ?? 0xFFFFFFFF),
      borderColor: Color(map['borderColor'] as int? ?? 0xFF111111),
      borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 2.5,
    );
  }
}
