import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/drawing_project.dart';

/// Servicio de persistencia local para guardar, cargar y listar
/// proyectos y lienzos de dibujo con todas sus capas editables.
abstract final class DrawingStorageService {
  static const String _folderName = 'furi_drawings/projects';

  static Future<Directory> _getDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Guarda o actualiza un proyecto en formato JSON.
  static Future<bool> saveProject(DrawingProject project) async {
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/${project.id}.json');
      await file.writeAsString(project.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving drawing project: $e');
      return false;
    }
  }

  /// Carga un proyecto por su ID.
  static Future<DrawingProject?> loadProject(String id) async {
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/$id.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return DrawingProject.fromJson(content);
    } catch (e) {
      debugPrint('Error loading drawing project $id: $e');
      return null;
    }
  }

  /// Lista todos los proyectos guardados, ordenados por fecha de modificación descendente.
  static Future<List<DrawingProject>> listProjects() async {
    try {
      final dir = await _getDirectory();
      final entities = dir.listSync();
      final List<DrawingProject> projects = [];

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            projects.add(DrawingProject.fromJson(content));
          } catch (e) {
            debugPrint('Error reading project file ${entity.path}: $e');
          }
        }
      }

      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (e) {
      debugPrint('Error listing drawing projects: $e');
      return [];
    }
  }

  /// Elimina un proyecto por su ID.
  static Future<bool> deleteProject(String id) async {
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting drawing project $id: $e');
      return false;
    }
  }

  /// Duplica un proyecto existente.
  static Future<DrawingProject?> duplicateProject(String id) async {
    try {
      final existing = await loadProject(id);
      if (existing == null) return null;

      final duplicated = existing.copyWith(
        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
        title: '${existing.title} (Copia)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveProject(duplicated);
      return duplicated;
    } catch (e) {
      debugPrint('Error duplicating drawing project $id: $e');
      return null;
    }
  }
}
