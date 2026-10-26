import '../models/comic_page.dart';

/// Historial inmutable de estados de página para Deshacer (Undo) y Rehacer (Redo).
class ComicHistory {
  final List<ComicPage> _undoStack = [];
  final List<ComicPage> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void recordSnapshot(ComicPage page) {
    _undoStack.add(page);
    _redoStack.clear();
  }

  ComicPage? undo(ComicPage currentPage) {
    if (!canUndo) return null;
    final prev = _undoStack.removeLast();
    _redoStack.add(currentPage);
    return prev;
  }

  ComicPage? redo(ComicPage currentPage) {
    if (!canRedo) return null;
    final next = _redoStack.removeLast();
    _undoStack.add(currentPage);
    return next;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
