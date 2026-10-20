import 'dart:developer' as developer;

import '../../models/deck_card.dart';
import '../../supabase_config.dart';

/// Consultas a Supabase para métricas de cartas, retos, metas, galería, puntos y mazo.
class AchievementFeatureCounts {
  static const _deckTable = 'deck_cards';
  static const _rewardsTable = 'couple_rewards';
  static const _triviaTable = 'question_answers';

  static Future<int> countLetters() async {
    try {
      final data = await SupabaseConfig.client
          .from('letters')
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countLetters error: $e');
      return 0;
    }
  }

  static Future<int> countChallengesCompleted() async {
    try {
      final data = await SupabaseConfig.client
          .from('challenges')
          .select('id')
          .eq('completed', true)
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countChallengesCompleted error: $e');
      return 0;
    }
  }

  static Future<int> countGoalsCompleted() async {
    try {
      final data = await SupabaseConfig.client
          .from('goals')
          .select('id')
          .eq('completed', true)
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countGoalsCompleted error: $e');
      return 0;
    }
  }

  static Future<int> countGalleryItems() async {
    try {
      final data = await SupabaseConfig.client
          .from('gallery')
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countGalleryItems error: $e');
      return 0;
    }
  }

  static Future<int> countFavorites() async {
    try {
      final data = await SupabaseConfig.client
          .from('favorites')
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countFavorites error: $e');
      return 0;
    }
  }

  static Future<int> countTriviaAnswers() async {
    try {
      final data = await SupabaseConfig.client
          .from(_triviaTable)
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countTriviaAnswers error: $e');
      return 0;
    }
  }

  static Future<int> countRewardsFulfilled() async {
    try {
      final data = await SupabaseConfig.client
          .from(_rewardsTable)
          .select('id')
          .eq('fulfilled', true)
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countRewardsFulfilled error: $e');
      return 0;
    }
  }

  static Future<int> countCouplePoints() async {
    try {
      final data = await SupabaseConfig.client
          .from('couple_points')
          .select('delta')
          .timeout(const Duration(seconds: 10));
      int total = 0;
      for (final r in data as List) {
        total += ((r as Map)['delta'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (e) {
      developer.log('CoupleAchievements._countCouplePoints error: $e');
      return 0;
    }
  }

  static Future<int> countMatches() async {
    try {
      final data = await SupabaseConfig.client
          .from(_deckTable)
          .select('reactions')
          .timeout(const Duration(seconds: 10));
      int count = 0;
      for (final r in data as List) {
        final raw = (r as Map)['reactions'];
        if (raw is Map) {
          final values = raw.values.toList();
          if (values.length >= 2 &&
              values.every((v) => v == DeckReaction.encanta)) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      developer.log('CoupleAchievements._countMatches error: $e');
      return 0;
    }
  }

  static Future<bool> hasCompletedChallenge() async {
    try {
      final data = await SupabaseConfig.client
          .from('challenges')
          .select('id')
          .eq('completed', true)
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasCompletedChallenge error: $e');
      return false;
    }
  }

  static Future<bool> hasCompletedGoal() async {
    try {
      final data = await SupabaseConfig.client
          .from('goals')
          .select('id')
          .eq('completed', true)
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasCompletedGoal error: $e');
      return false;
    }
  }

  static Future<bool> hasSentLetter() async {
    try {
      final data = await SupabaseConfig.client
          .from('letters')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasSentLetter error: $e');
      return false;
    }
  }

  static Future<bool> hasGalleryPhoto() async {
    try {
      final data = await SupabaseConfig.client
          .from('gallery')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasGalleryPhoto error: $e');
      return false;
    }
  }
}
