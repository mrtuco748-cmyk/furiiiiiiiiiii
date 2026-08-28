import 'deck_card.dart';

/// Memoria de los FURI!! del mazo: localiza el match más reciente/antiguo,
/// cuenta los del mes y arma un resumen memorable. Lógica pura testeable.
class DeckMemory {
  /// El match más reciente (por `updatedAt`), o null si no hay ninguno.
  static DeckCard? latestMatch(Iterable<DeckCard> cards) {
    final ms = cards.where((c) => c.isMatch).toList();
    if (ms.isEmpty) return null;
    ms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return ms.first;
  }

  /// El primer FURI!! de la pareja, o null si nunca hubo uno.
  static DeckCard? firstMatch(Iterable<DeckCard> cards) {
    final ms = cards.where((c) => c.isMatch).toList();
    if (ms.isEmpty) return null;
    ms.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return ms.first;
  }

  /// Cantidad de FURIs logrados en el mes indicado.
  static int matchesInMonth(Iterable<DeckCard> cards, DateTime month) =>
      cards
          .where((c) =>
              c.isMatch &&
              c.updatedAt.year == month.year &&
              c.updatedAt.month == month.month)
          .length;

  /// Resumen memorable de un match: día + categoría + preview corto.
  static String summary(DeckCard? match) {
    if (match == null) return '';
    final d = match.updatedAt;
    final cat = _categoryLabel(match.category);
    final preview = match.content.length > 25
        ? '${match.content.substring(0, 25)}...'
        : match.content;
    return '$cat · ${d.day}/${d.month}/${d.year} · $preview';
  }

  static String _categoryLabel(String c) {
    const labels = {
      DeckCategory.ideas: 'Ideas',
      DeckCategory.chistes: 'Chistes',
      DeckCategory.poemas: 'Poemas',
      DeckCategory.recetas: 'Recetas',
      DeckCategory.retos: 'Retos',
      DeckCategory.random: 'Random',
      DeckCategory.sueno: 'Sueño',
      DeckCategory.mePaso: 'Me pasó',
    };
    return labels[c] ?? c;
  }
}