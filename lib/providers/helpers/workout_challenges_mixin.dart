import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../models/workout_challenge.dart';
import '../../models/workout_social.dart';
import 'workout_database_service.dart';
import 'workout_social_service.dart';

mixin WorkoutChallengesMixin on ChangeNotifier {
  List<WorkoutChallenge> _challenges = [];
  List<WorkoutChallenge> get challenges => _challenges;

  void setChallenges(List<WorkoutChallenge> items) {
    _challenges = items;
  }

  String get myId;
  void setWorkoutError(String? msg);

  Future<void> addChallenge(WorkoutChallenge challenge) async {
    setWorkoutError(null);
    try {
      await WorkoutDatabaseService.insertChallenge(challenge.copyWith(createdBy: myId));
      _challenges = await WorkoutDatabaseService.fetchChallenges();
      notifyListeners();
    } catch (e) {
      setWorkoutError('No se pudo crear el reto');
      developer.log('WorkoutChallengesMixin.addChallenge error: $e');
    }
  }

  Future<void> deleteChallenge(int id) async {
    _challenges.removeWhere((c) => c.id == id);
    notifyListeners();
    try {
      await WorkoutDatabaseService.deleteChallenge(id);
    } catch (e) {
      setWorkoutError('No se pudo eliminar el reto');
      developer.log('WorkoutChallengesMixin.deleteChallenge error: $e');
      _challenges = await WorkoutDatabaseService.fetchChallenges();
      notifyListeners();
    }
  }

  Future<void> toggleChallengeApproval(int id) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    await _saveChallenge(_challenges[idx].toggleApproval(myId), idx);
  }

  Future<void> toggleChallengeCompletion(int id) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    await _saveChallenge(_challenges[idx].toggleCompletion(myId), idx);
  }

  Future<bool> toggleChallengeReaction(int id, String key) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1 || _challenges[idx].id == null) return false;
    final prev = _challenges[idx];
    final next = prev.toggleReaction(userId: myId, key: key);
    if (identical(next, prev)) return false;
    _challenges[idx] = next;
    notifyListeners();
    final authoritative = await WorkoutSocialService.reactViaRpc(
      table: WorkoutDatabaseService.challengesTable,
      id: id,
      key: key,
      userId: myId,
    );
    if (authoritative == null) {
      _challenges[idx] = prev;
      setWorkoutError('No se pudo guardar la reacción');
      return false;
    }
    _challenges[idx] = next.copyWith(
      social: WorkoutSocial(reactions: authoritative, comments: next.social.comments),
    );
    notifyListeners();
    return true;
  }

  Future<void> addChallengeComment(int id, String text) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1 || text.trim().isEmpty || _challenges[idx].id == null) return;
    final prev = _challenges[idx];
    final comment = WorkoutComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: myId,
      text: text.trim(),
      createdAt: DateTime.now(),
    ).toMap();
    _challenges[idx] = prev.copyWith(
      social: prev.social.addComment(id: comment['id'] as String, userId: myId, text: text.trim()),
    );
    notifyListeners();
    final auth = await WorkoutSocialService.commentViaRpc(
      table: WorkoutDatabaseService.challengesTable,
      id: id,
      action: 'add',
      comment: comment,
    );
    if (auth == null) {
      _challenges[idx] = prev;
      setWorkoutError('No se pudo guardar el comentario');
    } else {
      _challenges[idx] = _challenges[idx].copyWith(
        social: WorkoutSocial(reactions: _challenges[idx].social.reactions, comments: auth.comments),
      );
      notifyListeners();
    }
  }

  Future<void> deleteChallengeComment(int id, String commentId) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1 || _challenges[idx].id == null) return;
    final prev = _challenges[idx];
    _challenges[idx] = prev.copyWith(social: prev.social.deleteComment(commentId));
    notifyListeners();
    final auth = await WorkoutSocialService.commentViaRpc(
      table: WorkoutDatabaseService.challengesTable,
      id: id,
      action: 'delete',
      commentId: commentId,
    );
    if (auth == null) {
      _challenges[idx] = prev;
      setWorkoutError('No se pudo guardar el comentario');
    } else {
      _challenges[idx] = _challenges[idx].copyWith(
        social: WorkoutSocial(reactions: _challenges[idx].social.reactions, comments: auth.comments),
      );
      notifyListeners();
    }
  }

  Future<bool> _saveChallenge(WorkoutChallenge next, int idx) async {
    final prev = _challenges[idx];
    _challenges[idx] = next;
    notifyListeners();
    try {
      await WorkoutDatabaseService.updateChallenge(next);
      return true;
    } catch (e) {
      _challenges[idx] = prev;
      setWorkoutError('No se pudo guardar el reto');
      developer.log('WorkoutChallengesMixin._saveChallenge error: $e');
      return false;
    }
  }
}
