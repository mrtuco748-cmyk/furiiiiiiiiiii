import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/schedule.dart';
import 'package:furi_app/providers/schedule_sync.dart';

Schedule _s({
  int? id,
  int? cloudId,
  String title = 'Evento',
  DateTime? updatedAt,
  String userId = '',
}) {
  return Schedule(
    id: id,
    cloudId: cloudId,
    title: title,
    date: DateTime(2026, 8, 20),
    startTime: '10:00',
    endTime: '11:00',
    userId: userId,
    updatedAt: updatedAt ?? DateTime(2026, 8, 1),
  );
}

void main() {
  test('cloud sin par local se inserta localmente', () {
    final plan = buildScheduleSyncPlan(
      local: [],
      cloud: [_s(cloudId: 1, title: 'De la pareja', userId: 'Facu')],
    );

    expect(plan.toInsertLocally.length, 1);
    expect(plan.toInsertLocally.first.title, 'De la pareja');
    expect(plan.toInsertLocally.first.userId, 'Facu');
    expect(plan.toUpdateLocally, isEmpty);
    expect(plan.localIdsToDelete, isEmpty);
  });

  test('cloud mas nueva que la local gana y resuelve el id local', () {
    final plan = buildScheduleSyncPlan(
      local: [
        _s(id: 10, cloudId: 1, title: 'Viejo',
            updatedAt: DateTime(2026, 8, 1)),
      ],
      cloud: [
        _s(cloudId: 1, title: 'Nuevo titulo',
            updatedAt: DateTime(2026, 8, 10)),
      ],
    );

    expect(plan.toInsertLocally, isEmpty);
    expect(plan.toUpdateLocally.length, 1);
    expect(plan.toUpdateLocally.first.title, 'Nuevo titulo');
    expect(plan.toUpdateLocally.first.id, 10);
  });

  test('cloud mas vieja no pisa la local', () {
    final plan = buildScheduleSyncPlan(
      local: [
        _s(id: 10, cloudId: 1, title: 'Local nuevo',
            updatedAt: DateTime(2026, 8, 10)),
      ],
      cloud: [
        _s(cloudId: 1, title: 'Cloud viejo',
            updatedAt: DateTime(2026, 8, 1)),
      ],
    );

    expect(plan.toUpdateLocally, isEmpty);
    expect(plan.toInsertLocally, isEmpty);
  });

  test('local con cloudId que ya no esta en cloud se borra', () {
    final plan = buildScheduleSyncPlan(
      local: [
        _s(id: 10, cloudId: 99),
        _s(id: 11, cloudId: 1),
      ],
      cloud: [_s(cloudId: 1)],
    );

    expect(plan.localIdsToDelete, [10]);
  });

  test('local sin cloudId no se borra ni se toca (se sube aparte)', () {
    final plan = buildScheduleSyncPlan(
      local: [_s(id: 10)],
      cloud: [_s(cloudId: 1)],
    );

    expect(plan.localIdsToDelete, isEmpty);
    expect(plan.toInsertLocally.length, 1);
  });
}
