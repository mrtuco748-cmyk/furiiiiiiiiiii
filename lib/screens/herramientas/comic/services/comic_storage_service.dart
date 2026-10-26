import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/comic_project.dart';

/// Servicio de persistencia local para guardar, cargar y listar
/// cómics e historias completas creadas por la pareja.
abstract final class ComicStorageService {
  static const String _folderName = 'furi_comics/projects';

  static Future<Directory> _getDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Guarda o actualiza un cómic en formato JSON.
  static Future<bool> saveProject(ComicProject project) async {
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/${project.id}.json');
      await file.writeAsString(project.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving comic project: $e');
      return false;
    }
  }

  /// Carga un cómic por su ID.
  static Future<ComicProject?> loadProject(String id) async {
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/$id.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return ComicProject.fromJson(content);
    } catch (e) {
      debugPrint('Error loading comic project $id: $e');
      return null;
    }
  }

  /// Lista todos los cómics guardados, ordenados por fecha de modificación descendente.
  static Future<List<ComicProject>> listProjects() async {
    try {
      final dir = await _getDirectory();
      final entities = dir.listSync();
      final List<ComicProject> projects = [];

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            projects.add(ComicProject.fromJson(content));
          } catch (e) {
            debugPrint('Error reading comic file ${entity.path}: $e');
          }
        }
      }

      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (e) {
      debugPrint('Error listing comic projects: $e');
      return [];
    }
  }

  /// Lista todas las carpetas únicas disponibles.
  static Future<List<String>> listFolders() async {
    final projects = await listProjects();
    final folders = {'General'};
    for (final p in projects) {
      if (p.folderName.trim().isNotEmpty) {
        folders.add(p.folderName.trim());
      }
    }
    return folders.toList();
  }

  /// Lista los cómics pertenecientes a una carpeta específica.
  static Future<List<ComicProject>> listProjectsInFolder(String folderName) async {
    final projects = await listProjects();
    return projects.where((p) => p.folderName == folderName).toList();
  }

  /// Elimina un cómic por su ID.
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
      debugPrint('Error deleting comic project $id: $e');
      return false;
    }
  }

  /// Duplica un cómic existente.
  static Future<ComicProject?> duplicateProject(String id) async {
    try {
      final existing = await loadProject(id);
      if (existing == null) return null;

      final duplicated = existing.copyWith(
        id: 'comic_${DateTime.now().millisecondsSinceEpoch}',
        title: '${existing.title} (Copia)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveProject(duplicated);
      return duplicated;
    } catch (e) {
      debugPrint('Error duplicating comic project $id: $e');
      return null;
    }
  }
}
