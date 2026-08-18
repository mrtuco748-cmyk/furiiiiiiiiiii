import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/workout_log.dart';

void main() {
  WorkoutLog base({String name = 'Press banca'}) =>
      WorkoutLog(exerciseName: name, userId: 'facu-uuid');

  test('isValid es falso sin nombre', () {
    expect(base(name: '   ').isValid, false);
    expect(base(name: '').isValid, false);
  });

  test('isValid es verdadero con nombre', () {
    expect(base().isValid, true);
  });

  test('toMap serializa en snake_case sin id y sin campos nulos', () {
    final log = WorkoutLog(
      exerciseName: 'Sentadilla',
      series: 4,
      reps: 10,
      weight: 80.5,
      restSeconds: 90,
      muscleGroup: 'Piernas',
      notes: 'subir peso',
      userId: 'facu-uuid',
    );
    final m = log.toMap();
    expect(m['exercise_name'], 'Sentadilla');
    expect(m['series'], 4);
    expect(m['reps'], 10);
    expect(m['weight'], 80.5);
    expect(m['rest_seconds'], 90);
    expect(m['muscle_group'], 'Piernas');
    expect(m['notes'], 'subir peso');
    expect(m['user_id'], 'facu-uuid');
    expect(m.containsKey('id'), false);
    expect(m.containsKey('routine_id'), false);
  });

  test('fromMap parsea weight double, fecha y social JSONB', () {
    final log = WorkoutLog.fromMap({
      'id': 7,
      'exercise_name': 'Curl',
      'weight': '12.5',
      'logged_on': '2026-08-17',
      'routine_id': 3,
      'social': {
        'reactions': {
          '🔥': ['rocio-uuid'],
        },
        'comments': [
          {
            'id': 'c1',
            'userId': 'rocio-uuid',
            'text': 'bien',
            'createdAt': '2026-08-17T10:00:00.000Z',
          },
        ],
      },
    });
    expect(log.id, 7);
    expect(log.weight, 12.5);
    expect(log.loggedOn, DateTime(2026, 8, 17));
    expect(log.routineId, 3);
    expect(log.social.reactions['🔥'], ['rocio-uuid']);
    expect(log.social.comments.length, 1);
    expect(log.social.comments.first.text, 'bien');
  });

  test('fromMap tolera social null y social malformado', () {
    expect(WorkoutLog.fromMap({'exercise_name': 'x'}).social.comments, isEmpty);
    expect(
      WorkoutLog.fromMap({'exercise_name': 'x', 'social': 'no-map'}).social,
      isNotNull,
    );
  });

  test('toggleReaction agrega y quita reacción del usuario', () {
    final log = base();
    final con = log.toggleReaction(userId: 'facu-uuid', key: '🔥');
    expect(con.social.reactions['🔥'], ['facu-uuid']);
    final sin = con.toggleReaction(userId: 'facu-uuid', key: '🔥');
    expect(sin.social.reactions.containsKey('🔥'), false);
  });

  test('toggleReaction no permite más de 5 keys', () {
    var log = base();
    for (var i = 0; i < 5; i++) {
      log = log.toggleReaction(userId: 'user-$i', key: 'k$i');
    }
    final sexta = log.toggleReaction(userId: 'user-6', key: 'f');
    expect(sexta.social.reactions.length, 5);
    expect(sexta.social.reactions.containsKey('f'), false);
  });

  test('toggleReaction mueve al usuario si reacciona con otra key', () {
    final log = base().toggleReaction(userId: 'facu-uuid', key: '🔥');
    final movido = log.toggleReaction(userId: 'facu-uuid', key: '💪');
    expect(movido.social.reactions.containsKey('🔥'), false);
    expect(movido.social.reactions['💪'], ['facu-uuid']);
  });

  test('myReactionKey devuelve la key del usuario', () {
    final log = base().toggleReaction(userId: 'facu-uuid', key: '💪');
    expect(log.myReactionKey('facu-uuid'), '💪');
    expect(log.myReactionKey('rocio-uuid'), null);
  });

  test('addComment agrega al social y deleteComment limpia replies', () {
    var log = base();
    log = log.addComment(
      id: 'c1',
      userId: 'facu-uuid',
      text: 'primer comentario',
    );
    log = log.addComment(
      id: 'c2',
      userId: 'rocio-uuid',
      text: 'respuesta',
      replyToId: 'c1',
    );
    expect(log.social.comments.length, 2);
    final sinPadre = log.deleteComment('c1');
    expect(sinPadre.social.comments.length, 0);
  });

  test('summary muestra series x reps y peso cuando existen', () {
    expect(base().summary, '');
    expect(
      WorkoutLog(
        exerciseName: 'x',
        userId: 'u',
        series: 4,
        reps: 10,
        weight: 60,
      ).summary,
      '4x10 @ 60kg',
    );
  });
}
