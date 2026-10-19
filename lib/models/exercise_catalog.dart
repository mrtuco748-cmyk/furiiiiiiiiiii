/// Catálogo predefinido de ejercicios clasificados por grupo muscular.
/// Permite autocompletar nombre y grupo muscular con 1 tap, sin forzar
/// al usuario (puede escribir nombres y grupos libres).
class ExerciseCatalog {
  ExerciseCatalog._();

  static const Map<String, List<String>> _catalog = {
    'Pecho': [
      'Press de banca',
      'Press inclinado con mancuernas',
      'Press declinado',
      'Aperturas con mancuernas',
      'Cruces en polea',
      'Fondos en paralelas (pecho)',
      'Flexiones de brazos',
    ],
    'Espalda': [
      'Dominadas',
      'Jalón al pecho',
      'Remo con barra',
      'Remo con mancuerna',
      'Remo en polea baja (gironda)',
      'Pull-over en polea alta',
      'Peso muerto tradicional',
    ],
    'Piernas': [
      'Sentadillas',
      'Prensa de piernas',
      'Sentadilla búlgara',
      'Zancadas (estocadas)',
      'Sillón de cuádriceps (extensiones)',
      'Camilla de isquiotibiales (curl)',
      'Elevación de talones (gemelos)',
      'Hip thrust',
    ],
    'Hombros': [
      'Press militar con barra',
      'Press de hombros con mancuernas',
      'Elevaciones laterales',
      'Pájaros (deltoide posterior)',
      'Face pull',
      'Encogimientos con barra (trapecio)',
    ],
    'Brazos': [
      'Curl de bíceps con barra',
      'Curl martillo',
      'Curl concentrado con mancuerna',
      'Press francés para tríceps',
      'Extensiones de tríceps en polea',
      'Fondos en banco',
    ],
    'Core': [
      'Plancha abdominal',
      'Crunch en colchoneta',
      'Elevación de piernas colgado',
      'Rueda abdominal',
      'Giros rusos',
    ],
    'Cardio': [
      'Cinta (correr / trotar)',
      'Bicicleta fija',
      'Caminata inclinada',
      'Salto a la soga',
      'Remo ergómetro',
    ],
  };

  static List<String> get groups => _catalog.keys.toList();

  static List<String> exercisesFor(String group) =>
      _catalog[group] ?? const [];

  static String? suggestGroupFor(String exerciseName) {
    final lower = exerciseName.trim().toLowerCase();
    for (final entry in _catalog.entries) {
      for (final ex in entry.value) {
        if (ex.toLowerCase() == lower ||
            ex.toLowerCase().contains(lower) ||
            lower.contains(ex.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
