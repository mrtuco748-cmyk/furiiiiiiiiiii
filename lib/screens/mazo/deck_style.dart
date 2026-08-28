import 'package:flutter/material.dart';
import '../../models/deck_card.dart';

class DeckCategoryStyle {
  final String emoji;
  final String label;
  final List<Color> gradient;
  DeckCategoryStyle(this.emoji, this.label, this.gradient);

  Color get color => gradient.first;

  static Map<String, DeckCategoryStyle> get byCategory => {
    DeckCategory.ideas: DeckCategoryStyle('💡', 'IDEAS', [
      Color(0xFFFF0000),
      Color(0xFFFFDE59),
      Color(0xFFFF8F00),
    ]),
    DeckCategory.chistes: DeckCategoryStyle('😂', 'CHISTES', [
      Color(0xFF9D00FF),
      Color(0xFFFFDE59),
      Color(0xFFFF1493),
    ]),
    DeckCategory.poemas: DeckCategoryStyle('📜', 'POEMAS', [
      Color(0xFFFF0000),
      Color(0xFFFF1493),
      Color(0xFFFF0000),
    ]),
    DeckCategory.recetas: DeckCategoryStyle('🍳', 'RECETAS', [
      Color(0xFF39FF14),
      Color(0xFFFFDE59),
      Color(0xFF00C853),
    ]),
    DeckCategory.retos: DeckCategoryStyle('🚩', 'RETOS', [
      Color(0xFFFF0000),
      Color(0xFFFF8F00),
      Color(0xFFFF1493),
    ]),
    DeckCategory.random: DeckCategoryStyle('🎲', 'RANDOM', [
      Color(0xFF9D00FF),
      Color(0xFFFFDE59),
      Color(0xFF00D4FF),
    ]),
    DeckCategory.sueno: DeckCategoryStyle('🌙', 'SUEÑO', [
      Color(0xFF00D4FF),
      Color(0xFF4FC3FF),
      Color(0xFF7B1FA2),
    ]),
    DeckCategory.mePaso: DeckCategoryStyle('🤯', 'ME PASÓ', [
      Color(0xFFFF0000),
      Color(0xFFFFDE59),
      Color(0xFFFF1493),
    ]),
  };

  static DeckCategoryStyle of(String category) =>
      byCategory[category] ?? byCategory[DeckCategory.random]!;
}

class DeckReactionStyle {
  final String label;
  final List<Color> gradient;
  final IconData icon;
  final double dirX;
  final double dirY;
  DeckReactionStyle(this.label, this.gradient, this.icon, this.dirX, this.dirY);

  static Map<String, DeckReactionStyle> get byReaction => {
    DeckReaction.encanta: DeckReactionStyle(
        'ME ENCANTA', [Color(0xFF39FF14), Color(0xFF00C853), Color(0xFF007E33)], Icons.favorite, 1, 0),
    DeckReaction.noMeGusta: DeckReactionStyle(
        'NO ME GUSTA', [Color(0xFFFF0000), Color(0xFFFF1744), Color(0xFFB71C1C)], Icons.close, -1, 0),
    DeckReaction.meGusta: DeckReactionStyle(
        'ME GUSTA', [Color(0xFFFFDE59), Color(0xFFFFB300), Color(0xFFF57F17)], Icons.thumb_up, 0, 1),
    DeckReaction.meh: DeckReactionStyle(
        'MEH', [Color(0xFFB0BEC5), Color(0xFF90A4AE), Color(0xFF607D8B)], Icons.sentiment_neutral, 0, -1),
  };

  static DeckReactionStyle of(String reaction) =>
      byReaction[reaction] ?? byReaction[DeckReaction.meh]!;
}