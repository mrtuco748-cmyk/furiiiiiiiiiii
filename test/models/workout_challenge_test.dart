import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/workout_challenge.dart';
import 'package:furi_app/models/workout_social.dart';

void main() {
  WorkoutChallenge base() => WorkoutChallenge(
        title: '30 flexiones',
        createdBy: 'facu-uuid',
      );

  test('isValid es falso sin título', () {
    expect(base().isValid, true);
    expect(WorkoutChallenge(title: ' ', createdBy: 'facu-uuid').isValid, false);
  });

  test('toggleApproval agrega y quita la aprobación del usuario', () {
    final c = base();
    final con = c.toggleApproval('rocio-uuid');
    expect(con.approvedBy, ['rocio-uuid']);
    expect(con.approvedByUser('rocio-uuid'), true);
    expect(con.approvedByUser('facu-uuid'), false);
    final sin = con.toggleApproval('rocio-uuid');
    expect(sin.approvedBy, isEmpty);
  });

  test('isApproved requiere aprobación de ambos', () {
    var c = base();
    expect(c.isApproved, false);
    c = c.toggleApproval('facu-uuid');
    expect(c.isApproved, false);
    c = c.toggleApproval('rocio-uuid');
    expect(c.isApproved, true);
  });

  test('isCompleted requiere completado de ambos', () {
    var c = base().toggleCompletion('facu-uuid');
    expect(c.isCompleted, false);
    c = c.toggleCompletion('rocio-uuid');
    expect(c.isCompleted, true);
  });

  test('toggleApproval no permite aprobar más de una vez por usuario', () {
    final c = base()
        .toggleApproval('facu-uuid')
        .toggleApproval('facu-uuid')
        .toggleApproval('facu-uuid');
    expect(c.approvedBy.where((u) => u == 'facu-uuid').length, 1);
  });

  test('toMap serializa en snake_case y fromMap parsea arrays JSONB', () {
    final c = WorkoutChallenge(
      id: 5,
      title: 'Abdominales',
      description: '100 reps',
      createdBy: 'facu-uuid',
      approvedBy: const ['facu-uuid', 'rocio-uuid'],
      completedBy: const ['facu-uuid'],
      social: const WorkoutSocial(
        reactions: {'🔥': ['rocio-uuid']},
        comments: [],
      ),
    );
    final m = c.toMap();
    expect(m['title'], 'Abdominales');
    expect(m['description'], '100 reps');
    expect(m['created_by'], 'facu-uuid');
    expect(m['approved_by'], ['facu-uuid', 'rocio-uuid']);
    expect(m['completed_by'], ['facu-uuid']);
    expect(m.containsKey('id'), false);

    final parsed = WorkoutChallenge.fromMap({
      'id': 5,
      'title': 'Abdominales',
      'created_by': 'facu-uuid',
      'approved_by': ['facu-uuid', 'rocio-uuid'],
      'completed_by': ['facu-uuid'],
      'social': {
        'reactions': {
          '🔥': ['rocio-uuid'],
        },
        'comments': [],
      },
    });
    expect(parsed.isApproved, true);
    expect(parsed.isCompleted, false);
    expect(parsed.social.reactions['🔥'], ['rocio-uuid']);
  });

  test('toggleReaction funciona sobre el reto', () {
    final c = base().toggleReaction(userId: 'facu-uuid', key: '🏆');
    expect(c.social.reactions['🏆'], ['facu-uuid']);
  });
}
