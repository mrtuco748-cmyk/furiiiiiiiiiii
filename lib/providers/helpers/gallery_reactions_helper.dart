/// Utilidades para el manejo y combinación de reacciones en la galería.
class GalleryReactionsHelper {
  /// Conmuta la reacción de un usuario:
  /// Si ya existía, la remueve. Si no existía, la agrega (removiendo cualquier otra que tuviera).
  static Map<String, List<String>> toggleUserReaction({
    required Map<String, List<String>> currentReactions,
    required String key,
    required String userId,
  }) {
    final reactions = <String, List<String>>{};
    currentReactions.forEach((k, v) => reactions[k] = List<String>.from(v));

    final already = reactions[key]?.contains(userId) ?? false;
    final toRemove = <String>[];
    reactions.forEach((k, list) {
      list.remove(userId);
      if (list.isEmpty) toRemove.add(k);
    });
    for (final k in toRemove) {
      reactions.remove(k);
    }
    if (!already) {
      reactions.putIfAbsent(key, () => <String>[]).add(userId);
    }
    return reactions;
  }

  /// Une dos mapas de reacciones `{key: [userIds]}` preservando todas las
  /// entradas de `local` (mi estado optimista) con el server (`remote`).
  static Map<String, List<String>> mergeReactions(
    Map<String, List<String>> local,
    Map<String, List<String>> remote,
  ) {
    final out = <String, List<String>>{};
    for (final e in remote.entries) {
      out[e.key] = List<String>.from(e.value);
    }
    local.forEach((k, v) {
      final existing = out[k] ?? <String>[];
      for (final uid in v) {
        if (!existing.contains(uid)) existing.add(uid);
      }
      out[k] = existing;
    });
    return out;
  }
}
