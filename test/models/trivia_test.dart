import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/models/trivia.dart';

void main() {
  TriviaAnswer a({
    int q = 1,
    required String user,
    required String ans,
    String? guess,
  }) =>
      TriviaAnswer(
        questionId: q,
        userId: user,
        answer: ans,
        guess: guess,
      );

  group('TriviaStats.scoreFor', () {
    test('suma un punto cuando la predicción acierta la respuesta real', () {
      final all = [
        a(user: 'facu', ans: 'A', guess: 'B'),
        a(user: 'rocio', ans: 'B'),
      ];
      expect(TriviaStats.scoreFor(all, 'facu', 'rocio'), 1);
    });

    test('no suma si la predicción no coincide', () {
      final all = [
        a(user: 'facu', ans: 'A', guess: 'C'),
        a(user: 'rocio', ans: 'B'),
      ];
      expect(TriviaStats.scoreFor(all, 'facu', 'rocio'), 0);
    });

    test('no cuenta sin predicción', () {
      final all = [
        a(user: 'facu', ans: 'A'),
        a(user: 'rocio', ans: 'A'),
      ];
      expect(TriviaStats.scoreFor(all, 'facu', 'rocio'), 0);
    });

    test('ignora preguntas que la pareja no respondió', () {
      final all = [
        a(user: 'facu', ans: 'A', guess: 'B', q: 1),
        a(user: 'facu', ans: 'X', guess: 'Y', q: 2),
      ];
      expect(TriviaStats.scoreFor(all, 'facu', 'rocio'), 0);
    });

    test('si ambas aciertan, ambas suman', () {
      final all = [
        a(user: 'facu', ans: 'A', guess: 'B'),
        a(user: 'rocio', ans: 'B', guess: 'A'),
      ];
      expect(TriviaStats.scoreFor(all, 'facu', 'rocio'), 1);
      expect(TriviaStats.scoreFor(all, 'rocio', 'facu'), 1);
    });
  });

  group('TriviaStats.bothAnsweredFor', () {
    test('true cuando ambos respondieron la pregunta', () {
      final all = [
        a(user: 'facu', ans: 'A', q: 5),
        a(user: 'rocio', ans: 'B', q: 5),
      ];
      expect(TriviaStats.bothAnsweredFor(all, 5, {'facu', 'rocio'}), isTrue);
    });

    test('false si falta uno', () {
      final all = [a(user: 'facu', ans: 'A', q: 5)];
      expect(TriviaStats.bothAnsweredFor(all, 5, {'facu', 'rocio'}), isFalse);
    });
  });

  group('TriviaQuestionBank', () {
    test('hay al menos 8 preguntas', () {
      expect(TriviaQuestionBank.all.length, greaterThanOrEqualTo(8));
    });

    test('cada pregunta tiene 2-6 opciones no vacías', () {
      for (final q in TriviaQuestionBank.all) {
        expect(q.question.trim(), isNotEmpty);
        expect(q.options.length, inInclusiveRange(2, 6));
        for (final o in q.options) {
          expect(o.trim(), isNotEmpty);
        }
      }
    });
  });

  group('TriviaStats.questionForDay', () {
    test('mismo día → misma pregunta; distinto día → puede cambiar', () {
      final q1 = TriviaStats.questionForDay(TriviaQuestionBank.all, DateTime(2026, 8, 26));
      final q2 = TriviaStats.questionForDay(TriviaQuestionBank.all, DateTime(2026, 8, 26));
      expect(q1!.question, q2!.question);
    });

    test('nunca devuelve null con banco no vacío', () {
      final q = TriviaStats.questionForDay(TriviaQuestionBank.all, DateTime(2026, 1, 1));
      expect(q, isNotNull);
    });

    test('banco vacío devuelve null', () {
      expect(TriviaStats.questionForDay(const [], DateTime(2026, 1, 1)), isNull);
    });
  });

  group('Multiple questions per user (Deck / Survey persistence)', () {
    test('responder múltiples preguntas preserva cada una en el historial y las saca de pendientes', () {
      final questions = [
        const TriviaQuestion(id: 1, question: 'Q1', options: ['A', 'B']),
        const TriviaQuestion(id: 2, question: 'Q2', options: ['C', 'D']),
        const TriviaQuestion(id: 3, question: 'Q3', options: ['E', 'F']),
      ];

      final answers = <TriviaAnswer>[];
      // Usuario responde Q1
      answers.removeWhere((a) => a.userId == 'user1' && a.questionId == 1);
      answers.add(a(q: 1, user: 'user1', ans: 'A', guess: 'B'));

      // Usuario responde Q2 el mismo día
      answers.removeWhere((a) => a.userId == 'user1' && a.questionId == 2);
      answers.add(a(q: 2, user: 'user1', ans: 'C', guess: 'D'));

      // Verificar que AMBAS respuestas están presentes (ninguna sobreescribió a la otra)
      expect(answers.length, 2);
      final myAnsweredIds = answers.where((a) => a.userId == 'user1').map((a) => a.questionId).toSet();
      expect(myAnsweredIds.contains(1), isTrue);
      expect(myAnsweredIds.contains(2), isTrue);

      // unanswered solo debe contener Q3
      final unanswered = questions.where((q) => !myAnsweredIds.contains(q.id)).toList();
      expect(unanswered.length, 1);
      expect(unanswered.first.id, 3);

      // answered contiene Q1 y Q2
      final answered = questions.where((q) => myAnsweredIds.contains(q.id)).toList();
      expect(answered.length, 2);
    });
  });
}