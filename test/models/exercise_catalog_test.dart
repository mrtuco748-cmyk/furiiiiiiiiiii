import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/exercise_catalog.dart';

void main() {
  test('ExerciseCatalog tiene grupos musculares principales', () {
    final groups = ExerciseCatalog.groups;
    expect(groups, contains('Pecho'));
    expect(groups, contains('Espalda'));
    expect(groups, contains('Piernas'));
    expect(groups, contains('Hombros'));
    expect(groups, contains('Brazos'));
    expect(groups, contains('Core'));
    expect(groups, contains('Cardio'));
  });

  test('cada grupo tiene ejercicios predefinidos', () {
    for (final g in ExerciseCatalog.groups) {
      final list = ExerciseCatalog.exercisesFor(g);
      expect(list, isNotEmpty, reason: 'El grupo $g debe tener ejercicios');
    }
    expect(ExerciseCatalog.exercisesFor('Pecho'), contains('Press de banca'));
    expect(ExerciseCatalog.exercisesFor('Piernas'), contains('Sentadillas'));
    expect(ExerciseCatalog.exercisesFor('Espalda'), contains('Dominadas'));
  });

  test('suggestGroupFor deduce el grupo a partir del nombre o retorna null', () {
    expect(ExerciseCatalog.suggestGroupFor('Press de banca'), 'Pecho');
    expect(ExerciseCatalog.suggestGroupFor('Sentadilla búlgara'), 'Piernas');
    expect(ExerciseCatalog.suggestGroupFor('Cualquier cosa rara'), isNull);
  });
}
