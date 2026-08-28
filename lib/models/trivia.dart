// Papel de la trivia de pareja: pregunta del día con opciones, cada uno elige
// su respuesta y predice la de su pareja. Modelos + lógica pura testeable.

/// Una pregunta de trivia con opciones de opción múltiple.
class TriviaQuestion {
  final int? id;
  final String question;
  final List<String> options;

  const TriviaQuestion({
    this.id,
    required this.question,
    required this.options,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'question': question,
        'options': options,
      };

  factory TriviaQuestion.fromMap(Map<String, dynamic> m) => TriviaQuestion(
        id: _parseInt(m['id']),
        question: m['question']?.toString() ?? '',
        options: (m['options'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

/// Respuesta de un usuario a una pregunta dada.
class TriviaAnswer {
  final int? id;
  final int questionId;
  final String userId;
  final String answer;
  final String? guess;
  final String? date;

  TriviaAnswer({
    this.id,
    required this.questionId,
    required this.userId,
    required this.answer,
    this.guess,
    this.date,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'question_id': questionId,
        'user_id': userId,
        'answer': answer,
        if (guess != null) 'guess': guess,
        if (date != null) 'date': date,
      };

  factory TriviaAnswer.fromMap(Map<String, dynamic> m) => TriviaAnswer(
        id: _parseInt(m['id']),
        questionId: _parseInt(m['question_id']) ?? 0,
        userId: m['user_id']?.toString() ?? '',
        answer: m['answer']?.toString() ?? '',
        guess: m['guess']?.toString(),
        date: m['date']?.toString(),
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

/// Banco de preguntas (fuente de verdad). Se siembra en `daily_questions`.
abstract final class TriviaQuestionBank {
  static const List<TriviaQuestion> all = [
    TriviaQuestion(
      question: '¿Cuál sería el plan perfecto para nosotros una tarde libre?',
      options: ['Netflix y mantita', 'Caminar por la plaza', 'Cocinar algo juntos', 'Jugar a algún juego'],
    ),
    TriviaQuestion(
      question: '¿Qué es lo que más valoro de nosotros?',
      options: ['El humor', 'La confianza', 'Estar siempre para el otro', 'Los planes juntos'],
    ),
    TriviaQuestion(
      question: '¿A dónde sueño con que viajemos este año?',
      options: ['A la playa', 'A la montaña', 'Una ciudad nueva', 'Quedarnos y ahorrar'],
    ),
    TriviaQuestion(
      question: '¿Qué película me haría llorar?',
      options: ['Una de amor', 'Una de despedidas', 'Una de mascotas', 'No lloro con pelis'],
    ),
    TriviaQuestion(
      question: '¿Cuál es mi comida preferida?',
      options: ['Pizza', 'Hamburguesa', 'Asado', 'Pasta'],
    ),
    TriviaQuestion(
      question: '¿Qué prefiero para celebrar nuestro aniversario?',
      options: ['Una cena romántica', 'Un picnic', 'Algo tranqui en casa', 'Una salida distinta'],
    ),
    TriviaQuestion(
      question: '¿Qué me pone de buen humor sí o sí?',
      options: ['Un mensaje tuyo', 'Un abrazo', 'Reírnos de un chiste', 'Comida rica'],
    ),
    TriviaQuestion(
      question: '¿Cómo reacciono cuando me molesta algo?',
      options: ['Lo digo de una', 'Me enojo en silencio', 'Lo comparto y hablamos', 'Necesito espacio'],
    ),
    TriviaQuestion(
      question: '¿Cuál es Nuestra canción?',
      options: ['Una que bailamos', 'Una de nuestros viajes', 'Una que siempre cantamos', 'Todavía no la tenemos'],
    ),
    TriviaQuestion(
      question: '¿Qué mascota soñamos tener?',
      options: ['Un perro', 'Un gato', 'Varias mascotas', 'Ninguna por ahora'],
    ),
  ];
}

/// Lógica pura de la trivia: puntaje por predicciones acertadas.
class TriviaStats {
  /// Puntos de `userId`: un punto por cada respuesta en la que su
  /// predicción (`guess`) coincidió con la respuesta real de `partnerId`.
  static int scoreFor(
    List<TriviaAnswer> all,
    String userId,
    String partnerId,
  ) {
    final mine = all.where((a) => a.userId == userId).toList();
    final partnerByQ = <int, String>{
      for (final a in all)
        if (a.userId == partnerId && a.answer.isNotEmpty) a.questionId: a.answer,
    };
    return mine.where((a) {
      final real = partnerByQ[a.questionId];
      return real != null && a.guess != null && real == a.guess;
    }).length;
  }

  /// ¿Ambos miembros respondieron la pregunta?
  static bool bothAnsweredFor(
    List<TriviaAnswer> all,
    int questionId,
    Set<String> members,
  ) =>
      members.every(
          (u) => all.any((a) => a.questionId == questionId && a.userId == u));

  /// La pregunta del día: se elige por índice según el día del año.
  static TriviaQuestion? questionForDay(
    List<TriviaQuestion> bank,
    DateTime day,
  ) {
    if (bank.isEmpty) return null;
    final idx = (DateTime(day.year, day.month, day.day)
            .difference(DateTime(day.year))
            .inDays) %
        bank.length;
    return bank[idx];
  }
}