import 'couple_achievement.dart';

/// Catálogo completo y estático de definiciones de logros de pareja.
abstract final class CoupleAchievementDefinitions {
  static const all = <CoupleAchievement>[
    // ═══════════ Logros originales ═══════════
    CoupleAchievement(
      code: 'first_mood',
      emoji: '🌅',
      title: 'Primer día',
      description: 'Ambos registraron su estado de ánimo.',
    ),
    CoupleAchievement(
      code: 'workout_both',
      emoji: '💪',
      title: 'Equipo activo',
      description: 'Ambos entrenaron algún día.',
    ),
    CoupleAchievement(
      code: 'furi_first',
      emoji: '🃏',
      title: 'Primer FURI!!',
      description: 'Consiguieron su primer match en el mazo.',
    ),
    CoupleAchievement(
      code: 'streak_3',
      emoji: '🔥',
      title: 'Racha en marcha',
      description: '3 días de racha de pareja.',
    ),
    CoupleAchievement(
      code: 'streak_7',
      emoji: '🔥',
      title: 'Una semana completa',
      description: '7 días de racha de pareja.',
    ),
    CoupleAchievement(
      code: 'best_streak_14',
      emoji: '🌟',
      title: 'Medio mes',
      description: 'Alcanzaron una mejor racha de pareja de 14 días.',
    ),
    CoupleAchievement(
      code: 'messages_100',
      emoji: '💬',
      title: 'Conversadores',
      description: 'Llegaron a 100 mensajes.',
    ),
    CoupleAchievement(
      code: 'messages_1000',
      emoji: '💬',
      title: 'No se callan nada',
      description: 'Llegaron a 1000 mensajes.',
    ),
    CoupleAchievement(
      code: 'mood_streak_7',
      emoji: '🌅',
      title: 'Ánimo en pareja',
      description: '7 días seguidos registrando el ánimo ambos.',
    ),
    CoupleAchievement(
      code: 'workouts_50',
      emoji: '🏋️',
      title: 'En racha',
      description: '50 sesiones de entrenamiento entre ambos.',
    ),
    CoupleAchievement(
      code: 'location_shared',
      emoji: '📍',
      title: 'Cerca tuyo',
      description: 'Ambos compartieron su ubicación.',
    ),
    CoupleAchievement(
      code: 'reward_fulfilled',
      emoji: '🎁',
      title: 'Deseo cumplido',
      description: 'Cumplieron su primera recompensa de la cajita.',
    ),
    CoupleAchievement(
      code: 'trivia_day',
      emoji: '🎯',
      title: 'Se conocen',
      description: 'Un día donde ambos respondieron la trivia.',
    ),
    // ═══════════ Mensajes ═══════════
    CoupleAchievement(
      code: 'messages_500',
      emoji: '💬',
      title: 'Charla larga',
      description: 'Llegaron a 500 mensajes.',
    ),
    CoupleAchievement(
      code: 'messages_2000',
      emoji: '💬',
      title: 'Devotos',
      description: 'Llegaron a 2000 mensajes.',
    ),
    CoupleAchievement(
      code: 'messages_5000',
      emoji: '💬',
      title: 'Inseparables',
      description: 'Llegaron a 5000 mensajes.',
    ),
    // ═══════════ Racha de mood ═══════════
    CoupleAchievement(
      code: 'mood_streak_14',
      emoji: '🌅',
      title: 'Quince días',
      description: '14 días seguidos registrando el ánimo ambos.',
    ),
    CoupleAchievement(
      code: 'mood_streak_30',
      emoji: '🌙',
      title: 'Mes completo',
      description: '30 días seguidos registrando el ánimo ambos.',
    ),
    // ═══════════ Entrenamiento ═══════════
    CoupleAchievement(
      code: 'workout_100',
      emoji: '🏋️',
      title: 'Cien veces',
      description: '100 sesiones de entrenamiento entre ambos.',
    ),
    CoupleAchievement(
      code: 'workout_200',
      emoji: '💪',
      title: 'Doscientas',
      description: '200 sesiones de entrenamiento entre ambos.',
    ),
    // ═══════════ Trivia ═══════════
    CoupleAchievement(
      code: 'trivia_7',
      emoji: '🎯',
      title: 'Semana de sabios',
      description: '7 días seguidos respondiendo la trivia ambos.',
    ),
    CoupleAchievement(
      code: 'trivia_30',
      emoji: '🧠',
      title: 'Maestros',
      description: '30 días seguidos respondiendo la trivia ambos.',
    ),
    CoupleAchievement(
      code: 'trivia_100',
      emoji: '🧠',
      title: 'Genios',
      description: '100 respuestas de trivia entre ambos.',
    ),
    // ═══════════ Cartas ═══════════
    CoupleAchievement(
      code: 'first_letter',
      emoji: '💌',
      title: 'Primera carta',
      description: 'Enviaron su primera carta.',
    ),
    CoupleAchievement(
      code: 'letters_10',
      emoji: '💌',
      title: 'Decálogo',
      description: '10 cartas enviadas entre ambos.',
    ),
    CoupleAchievement(
      code: 'letters_50',
      emoji: '📜',
      title: 'Epistolario',
      description: '50 cartas enviadas entre ambos.',
    ),
    // ═══════════ Retos y metas ═══════════
    CoupleAchievement(
      code: 'first_challenge',
      emoji: '🚩',
      title: 'Reto nacido',
      description: 'Crearon su primer reto juntos.',
    ),
    CoupleAchievement(
      code: 'challenges_3',
      emoji: '🏆',
      title: 'Triunfadores',
      description: '3 retos completados entre ambos.',
    ),
    CoupleAchievement(
      code: 'first_goal',
      emoji: '🏅',
      title: 'Primera meta',
      description: 'Completaron su primera meta juntos.',
    ),
    CoupleAchievement(
      code: 'goals_5',
      emoji: '🏆',
      title: 'Cinco estrellas',
      description: '5 metas completadas entre ambos.',
    ),
    // ═══════════ Mazo ═══════════
    CoupleAchievement(
      code: 'furi_3',
      emoji: '🃏',
      title: 'Tres FURI',
      description: '3 matches del mazo.',
    ),
    CoupleAchievement(
      code: 'furi_10',
      emoji: '🃏',
      title: 'Decapitado',
      description: '10 matches del mazo.',
    ),
    // ═══════════ Recompensas y puntos ═══════════
    CoupleAchievement(
      code: 'first_reward',
      emoji: '🎁',
      title: 'Deseo #1',
      description: 'Cumplieron su primera recompensa de la cajita.',
    ),
    CoupleAchievement(
      code: 'rewards_3',
      emoji: '🎁',
      title: 'Cajita llena',
      description: '3 recompensas cumplidas.',
    ),
    CoupleAchievement(
      code: 'points_100',
      emoji: '🪙',
      title: 'Cien puntos',
      description: '100 puntos de pareja acumulados.',
    ),
    CoupleAchievement(
      code: 'points_500',
      emoji: '🪙',
      title: 'Quinientos',
      description: '500 puntos de pareja acumulados.',
    ),
    CoupleAchievement(
      code: 'points_1000',
      emoji: '🪙',
      title: 'Mil points',
      description: '1000 puntos de pareja acumulados.',
    ),
    // ═══════════ Galería y favoritos ═══════════
    CoupleAchievement(
      code: 'first_photo',
      emoji: '🖼️',
      title: 'Primera foto',
      description: 'Subieron su primera foto a la galería.',
    ),
    CoupleAchievement(
      code: 'photos_10',
      emoji: '📷',
      title: 'Álbum pequeño',
      description: '10 fotos en la galería.',
    ),
    CoupleAchievement(
      code: 'first_favorite',
      emoji: '⭐',
      title: 'Favorito',
      description: 'Guardaron su primer favorito.',
    ),
    CoupleAchievement(
      code: 'favorites_10',
      emoji: '⭐',
      title: 'Coleccionistas',
      description: '10 favoritos guardados entre ambos.',
    ),
    // ═══════════ Distancia ═══════════
    CoupleAchievement(
      code: 'distance_1km',
      emoji: '📍',
      title: 'Cerca',
      description: 'Se separaron al menos 1 km.',
    ),
    CoupleAchievement(
      code: 'distance_100km',
      emoji: '🌎',
      title: 'Lejos pero juntos',
      description: 'Se separaron al menos 100 km.',
    ),
    // ═══════════ Primera vez ═══════════
    CoupleAchievement(
      code: 'first_activity_both',
      emoji: '🎉',
      title: 'En movimiento',
      description: 'Ambos registraron mood y entrenaron el mismo día.',
    ),
  ];
}
