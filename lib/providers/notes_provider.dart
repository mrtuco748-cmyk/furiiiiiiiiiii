import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  bool _loading = false;
  String? _error;

  List<Note> get notes => _notes;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => !loading && _notes.isEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query('notes', orderBy: 'updated_at DESC');
      _notes = result.map((map) => Note.fromMap(map)).toList();
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  Future<void> add(Note note) async {
    try {
      final db = await DatabaseHelper().database;
      final map = note.toMap();
      map['created_at'] = DateTime.now().toIso8601String();
      map['updated_at'] = map['created_at'];
      await db.insert('notes', map);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(Note note) async {
    try {
      if (note.id == null) return;
      final db = await DatabaseHelper().database;
      final map = note.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      await db.update('notes', map, where: 'id = ?', whereArgs: [note.id]);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAll() async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('notes');
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void upsert(Note note) async {
    if (note.id == null) {
      await add(note);
    } else {
      await update(note);
    }
  }
}