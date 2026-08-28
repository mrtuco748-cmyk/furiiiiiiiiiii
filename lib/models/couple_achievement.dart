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
    return earned;
  }
}