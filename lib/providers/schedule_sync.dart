import '../models/schedule.dart';

/// Resultado del merge entre filas locales (SQLite) y filas cloud (Supabase).
class ScheduleSyncPlan {
  /// Filas cloud que no existen localmente (hay que insertarlas en SQLite).
  final List<Schedule> toInsertLocally;

  /// Filas cloud mas nuevas que la local: ya traen el id local resuelto.
  final List<Schedule> toUpdateLocally;

  /// Ids locales cuyo cloudId ya no existe en cloud (borradas por la pareja).
  final List<int> localIdsToDelete;

  const ScheduleSyncPlan({
    this.toInsertLocally = const [],
    this.toUpdateLocally = const [],
    this.localIdsToDelete = const [],
  });
}

/// Merge local <-> cloud keyeado por [Schedule.cloudId].
/// - cloud sin par local: se inserta localmente.
/// - cloud mas nueva que la local: gana cloud (updatedAt).
/// - local con cloudId que no esta en cloud: se borra (delete de la pareja).
/// - local sin cloudId: se ignora (se sube aparte con push).
ScheduleSyncPlan buildScheduleSyncPlan({
  required List<Schedule> local,
  required List<Schedule> cloud,
}) {
  final cloudIds = cloud.map((s) => s.cloudId).whereType<int>().toSet();

  final toInsertLocally = <Schedule>[];
  final toUpdateLocally = <Schedule>[];
  for (final c in cloud) {
    if (c.cloudId == null) continue;
    Schedule? pair;
    for (final l in local) {
      if (l.cloudId == c.cloudId) {
        pair = l;
        break;
      }
    }
    if (pair == null) {
      toInsertLocally.add(c);
    } else if (c.updatedAt.isAfter(pair.updatedAt)) {
      toUpdateLocally.add(c.copyWith(id: pair.id));
    }
  }

  final localIdsToDelete = <int>[];
  for (final l in local) {
    if (l.cloudId != null && !cloudIds.contains(l.cloudId)) {
      localIdsToDelete.add(l.id!);
    }
  }

  return ScheduleSyncPlan(
    toInsertLocally: toInsertLocally,
    toUpdateLocally: toUpdateLocally,
    localIdsToDelete: localIdsToDelete,
  );
}
