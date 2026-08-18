import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/workout_routine.dart';

void main() {
  WorkoutRoutine base({String name = 'Piernas'}) =>
      WorkoutRoutine(name: name, userId: 'facu-uuid');

  test('isValid es falso sin nombre', () {
    expect(base(name: ' ').isValid, false);
    expect(base().isValid, true);
  });

  test('toMap serializa items como lista de maps y day_of_week', () {
    final routine = WorkoutRoutine(
      name: 'Pecho',
      dayOfWeek: 1,
      userId: 'facu-uuid',
      items: const [
        RoutineItem(exerciseName: 'Press', series: 4, reps: 10, weight: 60),
        RoutineItem(exerciseName: 'Aperturas', reps: 12),
      ],
    );
    final m = routine.toMap();
    expect(m['name'], 'Pecho');
    expect(m['day_of_week'], 1);
    expect(m['items'], isA<List>());
    final items = m['items'] as List;
    expect(items.length, 2);
    expect((items.first as Map)['exerciseName'], 'Press');
    expect((items.first as Map)['weight'], 60);
    expect(m.containsKey('id'), false);
  });

  test('fromMap parsea items JSONB y tolera malformados', () {
    final routine = WorkoutRoutine.fromMap({
      'id': 2,
      'name': 'Espalda',
      'day_of_week': 3,
      'items': [
        {'exerciseName': 'Dominadas', 'series': 4, 'reps': 8},
        'malformado',
      ],
      'social': {
        'reactions': {
          '💪': ['facu-uuid', 'rocio-uuid'],
        },
        'comments': [],
      },
    });
    expect(routine.id, 2);
    expect(routine.dayOfWeek, 3);
    expect(routine.items.length, 1);
    expect(routine.items.first.exerciseName, 'Dominadas');
    expect(routine.social.reactions['💪']!.length, 2);
  });

  test('addItem y removeItem mantienen la inmutabilidad', () {
    final routine = base();
    final conItem = routine.addItem(
      const RoutineItem(exerciseName: 'Sentadilla'),
    );
    expect(conItem.items.length, 1);
    expect(routine.items.length, 0);
    final sinItem = conItem.removeItem(0);
    expect(sinItem.items.length, 0);
  });

  test('toggleReaction funciona sobre la rutina', () {
    final routine = base();
    final con = routine.toggleReaction(userId: 'facu-uuid', key: '🔥');
    expect(con.social.reactions['🔥'], ['facu-uuid']);
  });
}
