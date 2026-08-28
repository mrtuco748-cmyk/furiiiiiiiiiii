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
      );
      final earned = CoupleAchievements.earnedCodes(s);
      expect(earned, {
        'first_mood', 'workout_both', 'streak_3', 'streak_7',
        'best_streak_14', 'furi_first', 'messages_100', 'messages_1000',
      });
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
}