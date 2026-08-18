import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/workout_log.dart';
import 'package:furi_app/models/workout_stats.dart';

void main() {
  WorkoutLog log(String name, DateTime day, {double? weight}) => WorkoutLog(
        exerciseName: name,
        userId: 'u',
        weight: weight,
        loggedOn: day,
      );

  test('streakFor cuenta días consecutivos hasta hoy', () {
    final today = DateTime(2026, 8, 17);
    final days = [
      DateTime(2026, 8, 15),
      DateTime(2026, 8, 16),
      DateTime(2026, 8, 17),
    ];
    expect(WorkoutStats.streakFor(days, today: today), 3);
  });

  test('streakFor sigue contando si hoy todavía no entrenó', () {
    final today = DateTime(2026, 8, 17);
    final days = [DateTime(2026, 8, 15), DateTime(2026, 8, 16)];
    expect(WorkoutStats.streakFor(days, today: today), 2);
  });

  test('streakFor es 0 sin días y corta en huecos', () {
    final today = DateTime(2026, 8, 17);
    expect(WorkoutStats.streakFor([], today: today), 0);
    expect(
      WorkoutStats.streakFor([DateTime(2026, 8, 17)], today: today),
      1,
    );
    expect(
      WorkoutStats.streakFor(
        [DateTime(2026, 8, 15), DateTime(2026, 8, 17)],
        today: today,
      ),
      1,
    );
    expect(
      WorkoutStats.streakFor(
        [DateTime(2026, 8, 10), DateTime(2026, 8, 11)],
        today: today,
      ),
      0,
    );
  });

  test('weightHistoryFor filtra por nombre y ordena por fecha', () {
    final logs = [
      log('Press', DateTime(2026, 8, 17), weight: 70),
      log('Curl', DateTime(2026, 8, 16), weight: 20),
      log('Press', DateTime(2026, 8, 10), weight: 60),
      log('Press', DateTime(2026, 8, 12)),
    ];
    final history = WorkoutStats.weightHistoryFor(logs, 'Press');
    expect(history.length, 2);
    expect(history.first.weight, 60);
    expect(history.last.weight, 70);
  });

  test('lastWeightFor devuelve el último peso registrado', () {
    final logs = [
      log('Press', DateTime(2026, 8, 10), weight: 60),
      log('Press', DateTime(2026, 8, 17), weight: 72.5),
    ];
    expect(WorkoutStats.lastWeightFor(logs, 'Press'), 72.5);
    expect(WorkoutStats.lastWeightFor(logs, 'Curl'), null);
  });

  test('sessionsThisWeek y sessionsLastWeek cuentan logs por semana', () {
    // lunes 2026-08-17, domingo 2026-08-23
    final now = DateTime(2026, 8, 19);
    final logs = [
      log('A', DateTime(2026, 8, 18)),
      log('B', DateTime(2026, 8, 19)),
      log('C', DateTime(2026, 8, 12)),
      log('D', DateTime(2026, 8, 3)),
    ];
    expect(WorkoutStats.sessionsThisWeek(logs, now: now), 2);
    expect(WorkoutStats.sessionsLastWeek(logs, now: now), 1);
  });

  test('distinctExerciseNames devuelve nombres únicos', () {
    final logs = [
      log('Press', DateTime(2026, 8, 17)),
      log('Press', DateTime(2026, 8, 18)),
      log('Curl', DateTime(2026, 8, 18)),
    ];
    expect(WorkoutStats.distinctExerciseNames(logs), {'Press', 'Curl'});
  });

  test('muscleGroupCounts cuenta por grupo muscular', () {
    final logs = [
      WorkoutLog(exerciseName: 'a', userId: 'u', muscleGroup: 'Piernas'),
      WorkoutLog(exerciseName: 'b', userId: 'u', muscleGroup: 'Piernas'),
      WorkoutLog(exerciseName: 'c', userId: 'u', muscleGroup: 'Pecho'),
    ];
    final counts = WorkoutStats.muscleGroupCounts(logs);
    expect(counts['Piernas'], 2);
    expect(counts['Pecho'], 1);
  });
}
