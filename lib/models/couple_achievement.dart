/// Definición de un logro de pareja: metadatos estáticos + código único.
class CoupleAchievement {
  final String code;
  final String emoji;
  final String title;
  final String description;

  const CoupleAchievement({
    required this.code,
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// Estado actual de la pareja usado para evaluar qué logros se alcanzan.
class AchievementSnapshot {
  final int coupleStreak;
  final int bestCoupleStreak;
  final bool bothLoggedMood;
  final bool bothWorkedOut;
  final bool hasDeckMatch;
  final int totalMessages;

  /// Racha de días en que AMBOS registraron mood (mérito extra).
  final int moodCoupleStreak;
  /// Total de sesiones de entrenamiento entre ambos.
  final int totalWorkouts;
  /// Ambos compartieron su ubicación (`couple_locations`).
  final bool bothSharedLocation;
  /// Hubo al menos una recompensa cumplida.
  final bool hasFulfilledReward;
  /// Un día (alguno) donde ambos respondieron la trivia.
  final bool bothAnsweredTrivia;

  /// ─── Nuevos campos para los logros ampliados ───
  /// Total de cartas enviadas/recibidas entre ambos.
  final int totalLetters;
  /// Total de retos completados entre ambos.
  final int totalChallengesCompleted;
  /// Total de metas completadas entre ambos.
  final int totalGoalsCompleted;
  /// Total de fotos en la galería entre ambos.
  final int totalGalleryItems;
  /// Total de favoritos guardados entre ambos.
  final int totalFavorites;
  /// Total de respuestas de trivia de ambos usuarios.
  final int totalTriviaAnswers;
  /// Total de recompensas cumplidas.
  final int totalRewardsFulfilled;
  /// Total de puntos de pareja acumulados.
  final int totalCouplePoints;
  /// Número de matches del mazo (FURI!!) que han tenido.
  final int matchCount;
  /// Distancia máxima registrada entre ambos (km).
  final double distanceKm;
  /// Ambos completaron un reto (al menos uno).
  final bool hasCompletedChallenge;
  /// Ambos completaron una meta (al menos una).
  final bool hasCompletedGoal;
  /// Al menos una carta fue enviada por cualquiera.
  final bool hasSentLetter;
  /// Al menos una foto fue subida a la galería.
  final bool hasGalleryPhoto;

  const AchievementSnapshot({
    this.coupleStreak = 0,
    this.bestCoupleStreak = 0,
    this.bothLoggedMood = false,
    this.bothWorkedOut = false,
    this.hasDeckMatch = false,
    this.totalMessages = 0,
    this.moodCoupleStreak = 0,
    this.totalWorkouts = 0,
    this.bothSharedLocation = false,
    this.hasFulfilledReward = false,
    this.bothAnsweredTrivia = false,
    this.totalLetters = 0,
    this.totalChallengesCompleted = 0,
    this.totalGoalsCompleted = 0,
    this.totalGalleryItems = 0,
    this.totalFavorites = 0,
    this.totalTriviaAnswers = 0,
    this.totalRewardsFulfilled = 0,
    this.totalCouplePoints = 0,
    this.matchCount = 0,
    this.distanceKm = 0.0,
    this.hasCompletedChallenge = false,
    this.hasCompletedGoal = false,
    this.hasSentLetter = false,
    this.hasGalleryPhoto = false,
  });

  AchievementSnapshot copyWith({
    int? coupleStreak,
    int? bestCoupleStreak,
    bool? bothLoggedMood,
    bool? bothWorkedOut,
    bool? hasDeckMatch,
    int? totalMessages,
    int? moodCoupleStreak,
    int? totalWorkouts,
    bool? bothSharedLocation,
    bool? hasFulfilledReward,
    bool? bothAnsweredTrivia,
    int? totalLetters,
    int? totalChallengesCompleted,
    int? totalGoalsCompleted,
    int? totalGalleryItems,
    int? totalFavorites,
    int? totalTriviaAnswers,
    int? totalRewardsFulfilled,
    int? totalCouplePoints,
    int? matchCount,
    double? distanceKm,
    bool? hasCompletedChallenge,
    bool? hasCompletedGoal,
    bool? hasSentLetter,
    bool? hasGalleryPhoto,
  }) =>
      AchievementSnapshot(
        coupleStreak: coupleStreak ?? this.coupleStreak,
        bestCoupleStreak: bestCoupleStreak ?? this.bestCoupleStreak,
        bothLoggedMood: bothLoggedMood ?? this.bothLoggedMood,
        bothWorkedOut: bothWorkedOut ?? this.bothWorkedOut,
        hasDeckMatch: hasDeckMatch ?? this.hasDeckMatch,
        totalMessages: totalMessages ?? this.totalMessages,
        moodCoupleStreak: moodCoupleStreak ?? this.moodCoupleStreak,
        totalWorkouts: totalWorkouts ?? this.totalWorkouts,
        bothSharedLocation: bothSharedLocation ?? this.bothSharedLocation,
        hasFulfilledReward: hasFulfilledReward ?? this.hasFulfilledReward,
        bothAnsweredTrivia: bothAnsweredTrivia ?? this.bothAnsweredTrivia,
        totalLetters: totalLetters ?? this.totalLetters,
        totalChallengesCompleted:
            totalChallengesCompleted ?? this.totalChallengesCompleted,
        totalGoalsCompleted: totalGoalsCompleted ?? this.totalGoalsCompleted,
        totalGalleryItems: totalGalleryItems ?? this.totalGalleryItems,
        totalFavorites: totalFavorites ?? this.totalFavorites,
        totalTriviaAnswers: totalTriviaAnswers ?? this.totalTriviaAnswers,
        totalRewardsFulfilled:
            totalRewardsFulfilled ?? this.totalRewardsFulfilled,
        totalCouplePoints: totalCouplePoints ?? this.totalCouplePoints,
        matchCount: matchCount ?? this.matchCount,
        distanceKm: distanceKm ?? this.distanceKm,
        hasCompletedChallenge:
            hasCompletedChallenge ?? this.hasCompletedChallenge,
        hasCompletedGoal: hasCompletedGoal ?? this.hasCompletedGoal,
        hasSentLetter: hasSentLetter ?? this.hasSentLetter,
        hasGalleryPhoto: hasGalleryPhoto ?? this.hasGalleryPhoto,
      );
}

/// Un logro otorgado y persistido en `couple_achievements`.
class EarnedAchievement {
  final int? id;
  final String code;
  final DateTime awardedAt;

  EarnedAchievement({this.id, required this.code, DateTime? awardedAt})
      : awardedAt = awardedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'achievement_code': code,
      };

  factory EarnedAchievement.fromMap(Map<String, dynamic> m) =>
      EarnedAchievement(
        id: _parseInt(m['id']),
        code: m['achievement_code']?.toString() ?? '',
        awardedAt: _parseDt(m['awarded_at']),
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime _parseDt(dynamic v) {
    if (v == null) return DateTime.now();
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

/// Reglas de logros de pareja, evalúa con lógica pura testeable.
abstract final class CoupleAchievements {
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

  static CoupleAchievement? byCode(String? code) {
    if (code == null) return null;
    for (final a in all) {
      if (a.code == code) return a;
    }
    return null;
  }

  /// Códigos de logros alcanzados según el estado actual de la pareja.
  static Set<String> earnedCodes(AchievementSnapshot s) {
    final earned = <String>{};
    // ── Logros originales ──
    if (s.bothLoggedMood) earned.add('first_mood');
    if (s.bothWorkedOut) earned.add('workout_both');
    if (s.hasDeckMatch) earned.add('furi_first');
    if (s.coupleStreak >= 3) earned.add('streak_3');
    if (s.coupleStreak >= 7) earned.add('streak_7');
    if (s.bestCoupleStreak >= 14) earned.add('best_streak_14');
    if (s.totalMessages >= 100) earned.add('messages_100');
    if (s.totalMessages >= 1000) earned.add('messages_1000');
    if (s.moodCoupleStreak >= 7) earned.add('mood_streak_7');
    if (s.totalWorkouts >= 50) earned.add('workouts_50');
    if (s.bothSharedLocation) earned.add('location_shared');
    if (s.hasFulfilledReward) earned.add('reward_fulfilled');
    if (s.bothAnsweredTrivia) earned.add('trivia_day');

    // ── Mensajes ──
    if (s.totalMessages >= 500) earned.add('messages_500');
    if (s.totalMessages >= 2000) earned.add('messages_2000');
    if (s.totalMessages >= 5000) earned.add('messages_5000');

    // ── Racha de mood ──
    if (s.moodCoupleStreak >= 14) earned.add('mood_streak_14');
    if (s.moodCoupleStreak >= 30) earned.add('mood_streak_30');

    // ── Entrenamiento ──
    if (s.totalWorkouts >= 100) earned.add('workout_100');
    if (s.totalWorkouts >= 200) earned.add('workout_200');

    // ── Trivia ──
    if (s.totalTriviaAnswers >= 7) earned.add('trivia_7');
    if (s.totalTriviaAnswers >= 30) earned.add('trivia_30');
    if (s.totalTriviaAnswers >= 100) earned.add('trivia_100');

    // ── Cartas ──
    if (s.hasSentLetter) earned.add('first_letter');
    if (s.totalLetters >= 10) earned.add('letters_10');
    if (s.totalLetters >= 50) earned.add('letters_50');

    // ── Retos y metas ──
    if (s.hasCompletedChallenge) earned.add('first_challenge');
    if (s.totalChallengesCompleted >= 3) earned.add('challenges_3');
    if (s.hasCompletedGoal) earned.add('first_goal');
    if (s.totalGoalsCompleted >= 5) earned.add('goals_5');

    // ── Mazo ──
    if (s.matchCount >= 3) earned.add('furi_3');
    if (s.matchCount >= 10) earned.add('furi_10');

    // ── Recompensas y puntos ──
    if (s.totalRewardsFulfilled >= 1) earned.add('first_reward');
    if (s.totalRewardsFulfilled >= 3) earned.add('rewards_3');
    if (s.totalCouplePoints >= 100) earned.add('points_100');
    if (s.totalCouplePoints >= 500) earned.add('points_500');
    if (s.totalCouplePoints >= 1000) earned.add('points_1000');

    // ── Galería y favoritos ──
    if (s.hasGalleryPhoto) earned.add('first_photo');
    if (s.totalGalleryItems >= 10) earned.add('photos_10');
    if (s.totalFavorites >= 1) earned.add('first_favorite');
    if (s.totalFavorites >= 10) earned.add('favorites_10');

    // ── Distancia ──
    if (s.distanceKm >= 1) earned.add('distance_1km');
    if (s.distanceKm >= 100) earned.add('distance_100km');

    // ── Primera vez ──
    if (s.bothLoggedMood && s.bothWorkedOut) earned.add('first_activity_both');

    return earned;
  }
}