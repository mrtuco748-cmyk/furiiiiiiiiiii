import 'package:flutter/material.dart';
import '../../models/deck_card.dart';

class DeckCategoryStyle {
  final String emoji;
  final String label;
  final Color color;
  const DeckCategoryStyle(this.emoji, this.label, this.color);

  static const Map<String, DeckCategoryStyle> byCategory = {
    DeckCategory.ideas: DeckCategoryStyle('💡', 'IDEAS', Color(0xFFFFDE59)),
    DeckCategory.chistes: DeckCategoryStyle('😂', 'CHISTES', Color(0xFFFF6B00)),
    DeckCategory.poemas: DeckCategoryStyle('📜', 'POEMAS', Color(0xFF9D00FF)),
    DeckCategory.recetas: DeckCategoryStyle('🍳', 'RECETAS', Color(0xFF39FF14)),
    DeckCategory.retos: DeckCategoryStyle('🚩', 'RETOS', Color(0xFFFF00FF)),
    DeckCategory.random: DeckCategoryStyle('🎲', 'RANDOM', Color(0xFF00D4FF)),
    DeckCategory.sueno: DeckCategoryStyle('🌙', 'SUEÑO', Color(0xFF4FC3FF)),
    DeckCategory.mePaso: DeckCategoryStyle('🤯', 'ME PASÓ', Color(0xFFFF1493)),
  };

  static DeckCategoryStyle of(String category) =>
      byCategory[category] ??
      byCategory[DeckCategory.random]!;
}

class DeckReactionStyle {
  final String label;
  final Color color;
  final IconData icon;
  final double dirX;
  final double dirY;
  const DeckReactionStyle(
      this.label, this.color, this.icon, this.dirX, this.dirY);

  static const Map<String, DeckReactionStyle> byReaction = {
    DeckReaction.encanta: DeckReactionStyle(
        'ME ENCANTA', Color(0xFF39FF14), Icons.favorite, 1, 0),
    DeckReaction.noMeGusta: DeckReactionStyle(
        'NO ME GUSTA', Color(0xFFFF0000), Icons.close, -1, 0),
    DeckReaction.meGusta: DeckReactionStyle(
        'ME GUSTA', Color(0xFFFFDE59), Icons.thumb_up, 0, 1),
    DeckReaction.meh: DeckReactionStyle(
        'MEH', Color(0xFFB0BEC5), Icons.sentiment_neutral, 0, -1),
  };

  static DeckReactionStyle of(String reaction) =>
      byReaction[reaction] ?? byReaction[DeckReaction.meh]!;
}
