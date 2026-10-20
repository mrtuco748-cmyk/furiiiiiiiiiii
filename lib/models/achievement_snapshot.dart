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
