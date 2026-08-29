import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/models/couple_achievement.dart';

void main() {
  group('definiciones', () {
    test('todos los logros tienen códigos únicos', () {
      final codes = CoupleAchievements.all.map((a) => a.code).toSet();
      expect(codes.length, CoupleAchievements.all.length);
    });

    test('byCode resuelve cada código y null para inexistente', () {
      for (final a in CoupleAchievements.all) {
        expect(CoupleAchievements.byCode(a.code)?.code, a.code);
      }
      expect(CoupleAchievements.byCode('nope'), isNull);
    });

    test('cada logro tiene emoji, título y descripción', () {
      for (final a in CoupleAchievements.all) {
        expect(a.emoji, isNotEmpty);
        expect(a.title, isNotEmpty);
        expect(a.description, isNotEmpty);
      }
    });

    test('total de logros es al menos 42', () {
      expect(CoupleAchievements.all.length, greaterThanOrEqualTo(42));
    });
  });

  group('CoupleAchievements.earnedCodes', () {
    const empty = AchievementSnapshot();

    test('snapshot vacío → ningún logro', () {
      expect(CoupleAchievements.earnedCodes(empty), isEmpty);
    });

    test('ambos con mood → first_mood', () {
      final s = empty.copyWith(bothLoggedMood: true);
      expect(CoupleAchievements.earnedCodes(s), {'first_mood'});
    });

    test('ambos entrenaron → workout_both', () {
      final s = empty.copyWith(bothWorkedOut: true);
      expect(CoupleAchievements.earnedCodes(s), {'workout_both'});
    });

    test('racha 3 → streak_3, aún no streak_7', () {
      final s = empty.copyWith(coupleStreak: 3);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('streak_3'));
      expect(earned, isNot(contains('streak_7')));
    });

    test('racha 7 → habilita streak_3 y streak_7', () {
      final s = empty.copyWith(coupleStreak: 7);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, containsAll(['streak_3', 'streak_7']));
    });

    test('mejor racha 14 → best_streak_14', () {
      final s = empty.copyWith(bestCoupleStreak: 14);
      expect(CoupleAchievements.earnedCodes(s), {'best_streak_14'});
    });

    test('match del mazo → furi_first', () {
      final s = empty.copyWith(hasDeckMatch: true);
      expect(CoupleAchievements.earnedCodes(s), {'furi_first'});
    });

    test('100 mensajes → messages_100', () {
      final s = empty.copyWith(totalMessages: 100);
      expect(CoupleAchievements.earnedCodes(s), {'messages_100'});
    });

    test('1000 mensajes → messages_100 y messages_1000', () {
      final s = empty.copyWith(totalMessages: 1200);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, containsAll(['messages_100', 'messages_1000']));
    });

    test('racha de ánimo 7 → mood_streak_7', () {
      final s = empty.copyWith(moodCoupleStreak: 7);
      expect(CoupleAchievements.earnedCodes(s), {'mood_streak_7'});
    });

    test('50 sesiones entre ambos → workouts_50', () {
      final s = empty.copyWith(totalWorkouts: 50);
      expect(CoupleAchievements.earnedCodes(s), {'workouts_50'});
    });

    test('ambos compartieron ubicación → location_shared', () {
      final s = empty.copyWith(bothSharedLocation: true);
      expect(CoupleAchievements.earnedCodes(s), {'location_shared'});
    });

    test('recompensa cumplida → reward_fulfilled', () {
      final s = empty.copyWith(hasFulfilledReward: true);
      expect(CoupleAchievements.earnedCodes(s), {'reward_fulfilled'});
    });

    test('trivia respondida por ambos → trivia_day', () {
      final s = empty.copyWith(bothAnsweredTrivia: true);
      expect(CoupleAchievements.earnedCodes(s), {'trivia_day'});
    });

    // ─── Logros nuevos: mensajes (umbrales acumulativos) ───
    test('500 mensajes → incluye messages_500 (y messages_100)', () {
      final s = empty.copyWith(totalMessages: 500);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('messages_500'));
      expect(earned, contains('messages_100'));
    });

    test('2000 mensajes → incluye messages_2000', () {
      final s = empty.copyWith(totalMessages: 2000);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('messages_2000'));
      expect(earned, contains('messages_1000'));
    });

    test('5000 mensajes → incluye messages_5000', () {
      final s = empty.copyWith(totalMessages: 5000);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('messages_5000'));
    });

    // ─── Logros nuevos: racha de mood ───
    test('racha de ánimo 14 → mood_streak_14', () {
      final s = empty.copyWith(moodCoupleStreak: 14);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('mood_streak_14'));
      expect(earned, contains('mood_streak_7'));
    });

    test('racha de ánimo 30 → mood_streak_30', () {
      final s = empty.copyWith(moodCoupleStreak: 30);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('mood_streak_30'));
    });

    // ─── Logros nuevos: entrenamiento ───
    test('100 sesiones → workout_100 (y workouts_50)', () {
      final s = empty.copyWith(totalWorkouts: 100);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('workout_100'));
      expect(earned, contains('workouts_50'));
    });

    test('200 sesiones → workout_200', () {
      final s = empty.copyWith(totalWorkouts: 200);
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, contains('workout_200'));
    });

    // ─── Logros nuevos: trivia ───
    test('7 respuestas de trivia → trivia_7', () {
      final s = empty.copyWith(totalTriviaAnswers: 7);
      expect(CoupleAchievements.earnedCodes(s), contains('trivia_7'));
    });

    test('30 respuestas → trivia_30', () {
      final s = empty.copyWith(totalTriviaAnswers: 30);
      expect(CoupleAchievements.earnedCodes(s), contains('trivia_30'));
    });

    test('100 respuestas → trivia_100', () {
      final s = empty.copyWith(totalTriviaAnswers: 100);
      expect(CoupleAchievements.earnedCodes(s), contains('trivia_100'));
    });

    // ─── Logros nuevos: cartas ───
    test('primera carta → first_letter', () {
      final s = empty.copyWith(hasSentLetter: true);
      expect(CoupleAchievements.earnedCodes(s), {'first_letter'});
    });

    test('10 cartas → letters_10', () {
      final s = empty.copyWith(totalLetters: 10);
      expect(CoupleAchievements.earnedCodes(s), contains('letters_10'));
    });

    test('50 cartas → letters_50', () {
      final s = empty.copyWith(totalLetters: 50);
      expect(CoupleAchievements.earnedCodes(s), contains('letters_50'));
    });

    // ─── Logros nuevos: retos y metas ───
    test('primer reto completado → first_challenge', () {
      final s = empty.copyWith(hasCompletedChallenge: true);
      expect(CoupleAchievements.earnedCodes(s), {'first_challenge'});
    });

    test('3 retos completados → challenges_3', () {
      final s = empty.copyWith(totalChallengesCompleted: 3);
      expect(CoupleAchievements.earnedCodes(s), contains('challenges_3'));
    });

    test('primera meta → first_goal', () {
      final s = empty.copyWith(hasCompletedGoal: true);
      expect(CoupleAchievements.earnedCodes(s), {'first_goal'});
    });

    test('5 metas → goals_5', () {
      final s = empty.copyWith(totalGoalsCompleted: 5);
      expect(CoupleAchievements.earnedCodes(s), contains('goals_5'));
    });

    // ─── Logros nuevos: mazo ───
    test('3 matches → furi_3', () {
      final s = empty.copyWith(matchCount: 3);
      expect(CoupleAchievements.earnedCodes(s), contains('furi_3'));
    });

    test('10 matches → furi_10', () {
      final s = empty.copyWith(matchCount: 10);
      expect(CoupleAchievements.earnedCodes(s), contains('furi_10'));
    });

    // ─── Logros nuevos: recompensas y puntos ───
    test('1 recompensa cumplida → first_reward', () {
      final s = empty.copyWith(totalRewardsFulfilled: 1);
      expect(CoupleAchievements.earnedCodes(s), {'first_reward'});
    });

    test('3 recompensas → rewards_3', () {
      final s = empty.copyWith(totalRewardsFulfilled: 3);
      expect(CoupleAchievements.earnedCodes(s), contains('rewards_3'));
    });

    test('100 puntos → points_100', () {
      final s = empty.copyWith(totalCouplePoints: 100);
      expect(CoupleAchievements.earnedCodes(s), {'points_100'});
    });

    test('500 puntos → points_500', () {
      final s = empty.copyWith(totalCouplePoints: 500);
      expect(CoupleAchievements.earnedCodes(s), contains('points_500'));
    });

    test('1000 puntos → points_1000', () {
      final s = empty.copyWith(totalCouplePoints: 1000);
      expect(CoupleAchievements.earnedCodes(s), contains('points_1000'));
    });

    // ─── Logros nuevos: galería y favoritos ───
    test('primera foto → first_photo', () {
      final s = empty.copyWith(hasGalleryPhoto: true);
      expect(CoupleAchievements.earnedCodes(s), {'first_photo'});
    });

    test('10 fotos → photos_10', () {
      final s = empty.copyWith(totalGalleryItems: 10);
      expect(CoupleAchievements.earnedCodes(s), contains('photos_10'));
    });

    test('1 favorito → first_favorite', () {
      final s = empty.copyWith(totalFavorites: 1);
      expect(CoupleAchievements.earnedCodes(s), {'first_favorite'});
    });

    test('10 favoritos → favorites_10', () {
      final s = empty.copyWith(totalFavorites: 10);
      expect(CoupleAchievements.earnedCodes(s), contains('favorites_10'));
    });

    // ─── Logros nuevos: distancia ───
    test('1 km → distance_1km', () {
      final s = empty.copyWith(distanceKm: 1.0);
      expect(CoupleAchievements.earnedCodes(s), contains('distance_1km'));
    });

    test('100 km → distance_100km', () {
      final s = empty.copyWith(distanceKm: 100.0);
      expect(CoupleAchievements.earnedCodes(s), contains('distance_100km'));
    });

    // ─── Logros nuevos: primera vez ───
    test('ambos registraron mood y entrenaron → first_activity_both', () {
      final s = empty.copyWith(bothLoggedMood: true, bothWorkedOut: true);
      expect(CoupleAchievements.earnedCodes(s), contains('first_activity_both'));
    });

    test('logro no alcanzado no se otorga', () {
      final s = empty.copyWith(coupleStreak: 2, totalMessages: 99, hasDeckMatch: false);
      expect(CoupleAchievements.earnedCodes(s), isEmpty);
    });

    test('snapshot combinado otorga todos los alcanzados', () {
      final s = AchievementSnapshot(
        coupleStreak: 8,
        bestCoupleStreak: 20,
        bothLoggedMood: true,
        bothWorkedOut: true,
        hasDeckMatch: true,
        totalMessages: 1500,
        moodCoupleStreak: 14,
        totalWorkouts: 100,
        bothSharedLocation: true,
        hasFulfilledReward: true,
        bothAnsweredTrivia: true,
        totalLetters: 12,
        totalChallengesCompleted: 2,
        totalGoalsCompleted: 3,
        totalGalleryItems: 5,
        totalFavorites: 3,
        totalTriviaAnswers: 15,
        totalRewardsFulfilled: 2,
        totalCouplePoints: 250,
        matchCount: 5,
        distanceKm: 50.0,
        hasCompletedChallenge: true,
        hasCompletedGoal: true,
        hasSentLetter: true,
        hasGalleryPhoto: true,
      );
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, containsAll([
        'first_mood', 'workout_both', 'streak_3', 'streak_7',
        'best_streak_14', 'furi_first', 'messages_100', 'messages_1000',
        'messages_500', 'mood_streak_7', 'mood_streak_14',
        'workouts_50', 'workout_100', 'location_shared',
        'reward_fulfilled', 'trivia_day', 'trivia_7',
        'first_letter', 'letters_10',
        'first_challenge', 'first_goal',
        'furi_3', 'first_reward', 'points_100',
        'first_photo', 'first_favorite', 'distance_1km',
        'first_activity_both',
      ]));
    });
  });

  group('EarnedAchievement', () {
    test('fromMap parsea y toMap serializa', () {
      final fromMap = EarnedAchievement.fromMap({
        'id': 3,
        'achievement_code': 'streak_7',
        'awarded_at': '2026-08-25T10:00:00.000Z',
      });
      expect(fromMap.id, 3);
      expect(fromMap.code, 'streak_7');

      final toMap = fromMap.toMap();
      expect(toMap['achievement_code'], 'streak_7');
      expect(toMap.containsKey('id'), isFalse);
    });

    test('fromMap tolera awarded_at nulo', () {
      final a = EarnedAchievement.fromMap({
        'id': 1,
        'achievement_code': 'first_mood',
        'awarded_at': null,
      });
      expect(a.awardedAt, isNotNull);
    });
  });

  group('AchievementSnapshot copyWith', () {
    test('copyWith preserva valores no sobreescritos', () {
      final s = AchievementSnapshot(totalLetters: 5, totalWorkouts: 10);
      final copied = s.copyWith(totalLetters: 20);
      expect(copied.totalLetters, 20);
      expect(copied.totalWorkouts, 10);
    });

    test('copyWith con todos los campos nuevos', () {
      final s = AchievementSnapshot(
        matchCount: 3,
        distanceKm: 10.0,
        hasCompletedChallenge: true,
        hasCompletedGoal: false,
        hasSentLetter: true,
        hasGalleryPhoto: false,
      );
      final copied = s.copyWith(
        matchCount: 5,
        distanceKm: 100.0,
        hasCompletedChallenge: false,
        hasCompletedGoal: true,
        hasSentLetter: false,
        hasGalleryPhoto: true,
      );
      expect(copied.matchCount, 5);
      expect(copied.distanceKm, 100.0);
      expect(copied.hasCompletedChallenge, false);
      expect(copied.hasCompletedGoal, true);
      expect(copied.hasSentLetter, false);
      expect(copied.hasGalleryPhoto, true);
    });
  });
}
