import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/workout_social.dart';

void main() {
  test('mergeReactions une user_ids por key sin duplicados', () {
    final a = {
      '🔥': ['facu-uuid'],
      '💪': ['rocio-uuid'],
    };
    final b = {
      '🔥': ['rocio-uuid'],
      'xD': ['facu-uuid'],
    };
    final merged = WorkoutSocial.mergeReactions(a, b);
    expect(merged['🔥']!.toSet(), {'facu-uuid', 'rocio-uuid'});
    expect(merged['💪'], ['rocio-uuid']);
    expect(merged['xD'], ['facu-uuid']);
  });

  test('mergeReactions no duplica un user_id repetido', () {
    final a = {
      '🔥': ['facu-uuid', 'facu-uuid'],
    };
    final b = {
      '🔥': ['facu-uuid'],
    };
    final merged = WorkoutSocial.mergeReactions(a, b);
    expect(merged['🔥']!.length, 1);
  });

  test('mergeComments une por id sin duplicar', () {
    final a = [
      WorkoutComment(id: 'c1', userId: 'u', text: 'uno'),
      WorkoutComment(id: 'c2', userId: 'u', text: 'dos'),
    ];
    final b = [
      WorkoutComment(id: 'c1', userId: 'u', text: 'uno editado'),
      WorkoutComment(id: 'c3', userId: 'u', text: 'tres'),
    ];
    final merged = WorkoutSocial.mergeComments(a, b);
    expect(merged.length, 3);
    expect(
      merged.firstWhere((c) => c.id == 'c1').text,
      'uno editado',
    );
  });

  test('deleteComment elimina padre y respuestas en cascada', () {
    final social = WorkoutSocial(
      comments: const [
        WorkoutComment(id: 'c1', userId: 'u', text: 'padre'),
        WorkoutComment(id: 'c2', userId: 'u', text: 'respuesta', replyToId: 'c1'),
        WorkoutComment(id: 'c3', userId: 'u', text: 'otro'),
      ],
    );
    final sinPadre = social.deleteComment('c1');
    expect(sinPadre.comments.length, 1);
    expect(sinPadre.comments.first.id, 'c3');
  });

  test('toggleReaction mueve al usuario entre keys', () {
    final social = WorkoutSocial().toggleReaction(
      userId: 'facu-uuid',
      key: '🔥',
    );
    final movido = social.toggleReaction(userId: 'facu-uuid', key: '💪');
    expect(movido.reactions.containsKey('🔥'), false);
    expect(movido.reactions['💪'], ['facu-uuid']);
  });

  test('toggleReaction devuelve la misma instancia al llegar al límite', () {
    var social = const WorkoutSocial();
    for (var i = 0; i < 5; i++) {
      social = social.toggleReaction(userId: 'user-$i', key: 'k$i');
    }
    final sexta = social.toggleReaction(userId: 'user-6', key: 'f');
    expect(identical(social, sexta), true);
    expect(sexta.reactions.length, 5);
  });

  test('fromMap tolera social null y tipos malformados', () {
    expect(WorkoutSocial.fromMap(null).reactions, isEmpty);
    expect(WorkoutSocial.fromMap('no-map').comments, isEmpty);
    expect(
      WorkoutSocial.fromMap({
        'reactions': 'no-map',
        'comments': [1, 2],
      }).comments,
      isEmpty,
    );
  });
}
