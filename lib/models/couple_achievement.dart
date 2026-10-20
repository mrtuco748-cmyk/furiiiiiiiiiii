import 'achievement_snapshot.dart';
import 'couple_achievement_definitions.dart';

export 'achievement_snapshot.dart';
export 'couple_achievement_definitions.dart';

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
  static const all = CoupleAchievementDefinitions.all;

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
