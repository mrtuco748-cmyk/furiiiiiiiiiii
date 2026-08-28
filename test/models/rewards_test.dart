import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/models/rewards.dart';

void main() {
  PointsEntry e({String user = 'facu', int delta = 10, String reason = 'mood'}) =>
      PointsEntry(userId: user, delta: delta, reason: reason);

  group('PointsStats', () {
    test('balanceOf suma los deltas de un usuario', () {
      final l = [e(user: 'facu', delta: 10), e(user: 'facu', delta: -5), e(user: 'rocio', delta: 7)];
      expect(PointsStats.balanceOf(l, 'facu'), 5);
      expect(PointsStats.balanceOf(l, 'rocio'), 7);
    });

    test('total suma todos los deltas', () {
      final l = [e(delta: 10), e(user: 'rocio', delta: -3), e(delta: 5)];
      expect(PointsStats.total(l), 12);
    });

    test('pointsEarned suma solo deltas positivos', () {
      final l = [e(delta: 10), e(delta: -5), e(user: 'rocio', delta: 7)];
      expect(PointsStats.pointsEarned(l, 'facu'), 10);
    });

    test('balance vacío es 0', () {
      expect(PointsStats.total(const []), 0);
    });
  });

  group('CoupleReward', () {
    test('fromMap parsea y default fulfilled=false', () {
      final r = CoupleReward.fromMap({
        'id': 1,
        'title': 'Película',
        'emoji': '🎬',
        'cost': 20,
      });
      expect(r.title, 'Película');
      expect(r.cost, 20);
      expect(r.fulfilled, isFalse);
    });

    test('toMap incluye fulfilled y emoji', () {
      final m = CoupleReward(title: 'Masaje', emoji: '💆', cost: 30, fulfilled: true).toMap();
      expect(m['title'], 'Masaje');
      expect(m['cost'], 30);
      expect(m['fulfilled'], isTrue);
    });
  });

  group('PointsEntry', () {
    test('fromMap/toMap round-trip', () {
      final ent = PointsEntry.fromMap({'id': 1, 'user_id': 'rocio', 'reason': 'trivia', 'delta': 3});
      expect(ent.userId, 'rocio');
      expect(ent.reason, 'trivia');
      final m = ent.toMap();
      expect(m['user_id'], 'rocio');
      expect(m['delta'], 3);
      expect(m.containsKey('id'), isFalse);
    });
  });
}