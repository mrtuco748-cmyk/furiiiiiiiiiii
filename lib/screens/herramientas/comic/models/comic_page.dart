import 'dart:ui';
import 'package:flutter/material.dart';
import 'comic_bubble.dart';
import 'comic_panel.dart';
import 'comic_sticker.dart';

/// Representa una hoja o página individual dentro del cómic.
class ComicPage {
  final String id;
  final int pageNumber;
  final double width;
  final double height;
  final Color backgroundColor;
  final List<ComicPanel> panels;
  final List<ComicBubble> bubbles;
  final List<ComicSticker> sfxStickers;

  ComicPage({
    required this.id,
    required this.pageNumber,
    this.width = 1000.0,
    this.height = 1414.0, // Proporción clásica B5/A4
    this.backgroundColor = const Color(0xFFFFFFFF),
    required this.panels,
    required this.bubbles,
    required this.sfxStickers,
  });

  ComicPage copyWith({
    String? id,
    int? pageNumber,
    double? width,
    double? height,
    Color? backgroundColor,
    List<ComicPanel>? panels,
    List<ComicBubble>? bubbles,
    List<ComicSticker>? sfxStickers,
  }) {
    return ComicPage(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      panels: panels ?? this.panels,
      bubbles: bubbles ?? this.bubbles,
      sfxStickers: sfxStickers ?? this.sfxStickers,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'pageNumber': pageNumber,
    'width': width,
    'height': height,
    'backgroundColor': backgroundColor.toARGB32(),
    'panels': panels.map((p) => p.toMap()).toList(),
    'bubbles': bubbles.map((b) => b.toMap()).toList(),
    'sfxStickers': sfxStickers.map((s) => s.toMap()).toList(),
  };

  factory ComicPage.fromMap(Map<String, dynamic> map) {
    final panelsData = (map['panels'] as List<dynamic>?) ?? [];
    final bubblesData = (map['bubbles'] as List<dynamic>?) ?? [];
    final sfxData = (map['sfxStickers'] as List<dynamic>?) ?? [];

    return ComicPage(
      id: map['id'] as String? ?? 'page_${DateTime.now().microsecondsSinceEpoch}',
      pageNumber: map['pageNumber'] as int? ?? 1,
      width: (map['width'] as num?)?.toDouble() ?? 1000.0,
      height: (map['height'] as num?)?.toDouble() ?? 1414.0,
      backgroundColor: Color(map['backgroundColor'] as int? ?? 0xFFFFFFFF),
      panels: panelsData.map((p) => ComicPanel.fromMap(p as Map<String, dynamic>)).toList(),
      bubbles: bubblesData.map((b) => ComicBubble.fromMap(b as Map<String, dynamic>)).toList(),
      sfxStickers: sfxData.map((s) => ComicSticker.fromMap(s as Map<String, dynamic>)).toList(),
    );
  }
}
