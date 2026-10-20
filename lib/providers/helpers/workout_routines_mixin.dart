import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../models/workout_routine.dart';
import '../../models/workout_social.dart';
import 'workout_database_service.dart';
import 'workout_social_service.dart';

mixin WorkoutRoutinesMixin on ChangeNotifier {
  List<WorkoutRoutine> _routines = [];
  List<WorkoutRoutine> get routines => _routines;

  void setRoutines(List<WorkoutRoutine> items) {
    _routines = items;
  }

  String get myId;
  void setWorkoutError(String? msg);

  Future<void> addRoutine(WorkoutRoutine routine) async {
    setWorkoutError(null);
    try {
      await WorkoutDatabaseService.insertRoutine(routine.copyWith(userId: myId));
      _routines = await WorkoutDatabaseService.fetchRoutines();
      notifyListeners();
    } catch (e) {
      setWorkoutError('No se pudo crear la rutina');
      developer.log('WorkoutRoutinesMixin.addRoutine error: $e');
    }
  }

  Future<void> updateRoutine(WorkoutRoutine routine) async {
    if (routine.id == null) return;
    setWorkoutError(null);
    try {
      await WorkoutDatabaseService.updateRoutine(routine);
      _routines = await WorkoutDatabaseService.fetchRoutines();
      notifyListeners();
    } catch (e) {
      setWorkoutError('No se pudo actualizar la rutina');
      developer.log('WorkoutRoutinesMixin.updateRoutine error: $e');
    }
  }

  Future<void> deleteRoutine(int id) async {
    _routines.removeWhere((r) => r.id == id);
    notifyListeners();
    try {
      await WorkoutDatabaseService.deleteRoutine(id);
    } catch (e) {
      setWorkoutError('No se pudo eliminar la rutina');
      developer.log('WorkoutRoutinesMixin.deleteRoutine error: $e');
      _routines = await WorkoutDatabaseService.fetchRoutines();
      notifyListeners();
    }
  }

  Future<bool> toggleRoutineReaction(int id, String key) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1 || _routines[idx].id == null) return false;
    final prev = _routines[idx];
    final next = prev.toggleReaction(userId: myId, key: key);
    if (identical(next, prev)) return false;
    _routines[idx] = next;
    notifyListeners();
    final authoritative = await WorkoutSocialService.reactViaRpc(
      table: WorkoutDatabaseService.routinesTable,
      id: id,
      key: key,
      userId: myId,
    );
    if (authoritative == null) {
      _routines[idx] = prev;
      setWorkoutError('No se pudo guardar la reacción');
      return false;
    }
    _routines[idx] = next.copyWith(
      social: WorkoutSocial(reactions: authoritative, comments: next.social.comments),
    );
    notifyListeners();
    return true;
  }

  Future<void> addRoutineComment(int id, String text) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1 || text.trim().isEmpty || _routines[idx].id == null) return;
    final prev = _routines[idx];
    final comment = WorkoutComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: myId,
      text: text.trim(),
      createdAt: DateTime.now(),
    ).toMap();
    _routines[idx] = prev.copyWith(
      social: prev.social.addComment(id: comment['id'] as String, userId: myId, text: text.trim()),
    );
    notifyListeners();
    final auth = await WorkoutSocialService.commentViaRpc(
      table: WorkoutDatabaseService.routinesTable,
      id: id,
      action: 'add',
      comment: comment,
    );
    if (auth == null) {
      _routines[idx] = prev;
      setWorkoutError('No se pudo guardar el comentario');
    } else {
      _routines[idx] = _routines[idx].copyWith(
        social: WorkoutSocial(reactions: _routines[idx].social.reactions, comments: auth.comments),
      );
      notifyListeners();
    }
  }

  Future<void> deleteRoutineComment(int id, String commentId) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1 || _routines[idx].id == null) return;
    final prev = _routines[idx];
    _routines[idx] = prev.copyWith(social: prev.social.deleteComment(commentId));
    notifyListeners();
    final auth = await WorkoutSocialService.commentViaRpc(
      table: WorkoutDatabaseService.routinesTable,
      id: id,
      action: 'delete',
      commentId: commentId,
    );
    if (auth == null) {
      _routines[idx] = prev;
      setWorkoutError('No se pudo guardar el comentario');
    } else {
      _routines[idx] = _routines[idx].copyWith(
        social: WorkoutSocial(reactions: _routines[idx].social.reactions, comments: auth.comments),
      );
      notifyListeners();
    }
  }
}
