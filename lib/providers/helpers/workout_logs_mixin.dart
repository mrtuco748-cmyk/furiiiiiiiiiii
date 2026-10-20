import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../models/workout_log.dart';
import '../../models/workout_social.dart';
import 'workout_database_service.dart';
import 'workout_social_service.dart';

mixin WorkoutLogsMixin on ChangeNotifier {
  List<WorkoutLog> _logs = [];
  List<WorkoutLog> get logs => _logs;

  void setLogs(List<WorkoutLog> items) {
    _logs = items;
  }

  String get myId;
  void setWorkoutError(String? msg);

  Future<void> addLog(WorkoutLog log) async {
    setWorkoutError(null);
    try {
      await WorkoutDatabaseService.insertLog(log.copyWith(userId: myId));
      _logs = await WorkoutDatabaseService.fetchLogs();
      notifyListeners();
    } catch (e) {
      setWorkoutError('No se pudo registrar el ejercicio');
      developer.log('WorkoutLogsMixin.addLog error: $e');
    }
  }

  Future<void> updateLog(WorkoutLog log) async {
    if (log.id == null) return;
    setWorkoutError(null);
    try {
      await WorkoutDatabaseService.updateLog(log);
      _logs = await WorkoutDatabaseService.fetchLogs();
      notifyListeners();
    } catch (e) {
      setWorkoutError('No se pudo actualizar el ejercicio');
      developer.log('WorkoutLogsMixin.updateLog error: $e');
    }
  }

  Future<void> deleteLog(int id) async {
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
    try {
      await WorkoutDatabaseService.deleteLog(id);
    } catch (e) {
      setWorkoutError('No se pudo eliminar el ejercicio');
      developer.log('WorkoutLogsMixin.deleteLog error: $e');
      _logs = await WorkoutDatabaseService.fetchLogs();
      notifyListeners();
    }
  }

  Future<bool> toggleLogReaction(int id, String key) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx == -1 || _logs[idx].id == null) return false;
    final prev = _logs[idx];
    final next = prev.toggleReaction(userId: myId, key: key);
    if (identical(next, prev)) return false;
    _logs[idx] = next;
    notifyListeners();
    final authoritative = await WorkoutSocialService.reactViaRpc(
      table: WorkoutDatabaseService.logsTable,
      id: id,
      key: key,
      userId: myId,
    );
    if (authoritative == null) {
      _logs[idx] = prev;
      setWorkoutError('No se pudo guardar la reacción');
      return false;
    }
    _logs[idx] = next.copyWith(
      social: WorkoutSocial(reactions: authoritative, comments: next.social.comments),
    );
    notifyListeners();
    return true;
  }

  Future<void> addLogComment(int id, String text, {String? replyToId}) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx == -1 || text.trim().isEmpty || _logs[idx].id == null) return;
    final prev = _logs[idx];
    final comment = WorkoutComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: myId,
      text: text.trim(),
      createdAt: DateTime.now(),
      replyToId: replyToId,
    ).toMap();
    _logs[idx] = prev.copyWith(
      social: prev.social.addComment(
        id: comment['id'] as String,
        userId: myId,
        text: text.trim(),
        replyToId: replyToId,
      ),
    );
    notifyListeners();
    final auth = await WorkoutSocialService.commentViaRpc(
      table: WorkoutDatabaseService.logsTable,
      id: id,
      action: 'add',
      comment: comment,
    );
    if (auth == null) {
      _logs[idx] = prev;
      setWorkoutError('No se pudo guardar el comentario');
    } else {
      _logs[idx] = _logs[idx].copyWith(
        social: WorkoutSocial(reactions: _logs[idx].social.reactions, comments: auth.comments),
      );
      notifyListeners();
    }
  }

  Future<void> deleteLogComment(int id, String commentId) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx == -1 || _logs[idx].id == null) return;
    final prev = _logs[idx];
    _logs[idx] = prev.copyWith(social: prev.social.deleteComment(commentId));
    notifyListeners();
    final auth = await WorkoutSocialService.commentViaRpc(
      table: WorkoutDatabaseService.logsTable,
      id: id,
      action: 'delete',
      commentId: commentId,
    );
    if (auth == null) {
      _logs[idx] = prev;
      setWorkoutError('No se pudo guardar el comentario');
    } else {
      _logs[idx] = _logs[idx].copyWith(
        social: WorkoutSocial(reactions: _logs[idx].social.reactions, comments: auth.comments),
      );
      notifyListeners();
    }
  }
}
