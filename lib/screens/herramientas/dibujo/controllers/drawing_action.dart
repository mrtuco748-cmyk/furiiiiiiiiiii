import '../models/drawing_stroke.dart';
import 'drawing_controller.dart';

/// Interfaz para comandos ejecutables en el historial de Deshacer / Rehacer.
abstract class DrawingAction {
  void undo(DrawingController c);
  void redo(DrawingController c);
}

/// Acción de agregado de un nuevo trazo a una capa específica.
class AddStrokeAction implements DrawingAction {
  final int layerIndex;
  final DrawingStroke stroke;

  AddStrokeAction(this.layerIndex, this.stroke);

  @override
  void undo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      final list = List<DrawingStroke>.from(c.layers[layerIndex].strokes);
      list.removeWhere((s) => s.id == stroke.id);
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(strokes: list);
    }
  }

  @override
  void redo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      final list = List<DrawingStroke>.from(c.layers[layerIndex].strokes)..add(stroke);
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(strokes: list);
    }
  }
}

/// Acción de agregado atómico de múltiples trazos (ej. trazo con simetría espejada).
class AddStrokesGroupAction implements DrawingAction {
  final int layerIndex;
  final List<DrawingStroke> strokes;

  AddStrokesGroupAction(this.layerIndex, this.strokes);

  @override
  void undo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      final ids = strokes.map((s) => s.id).toSet();
      final list = List<DrawingStroke>.from(c.layers[layerIndex].strokes)
        ..removeWhere((s) => ids.contains(s.id));
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(strokes: list);
    }
  }

  @override
  void redo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      final list = List<DrawingStroke>.from(c.layers[layerIndex].strokes)..addAll(strokes);
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(strokes: list);
    }
  }
}

/// Acción de vaciado de trazos en una capa.
class ClearLayerAction implements DrawingAction {
  final int layerIndex;
  final List<DrawingStroke> previousStrokes;

  ClearLayerAction(this.layerIndex, this.previousStrokes);

  @override
  void undo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(
        strokes: List<DrawingStroke>.from(previousStrokes),
      );
    }
  }

  @override
  void redo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(strokes: []);
    }
  }
}

/// Acción de reemplazo de trazos en una capa (ej. transformación con lazo).
class UpdateLayerStrokesAction implements DrawingAction {
  final int layerIndex;
  final List<DrawingStroke> previousStrokes;
  final List<DrawingStroke> nextStrokes;

  UpdateLayerStrokesAction(this.layerIndex, this.previousStrokes, this.nextStrokes);

  @override
  void undo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(
        strokes: List<DrawingStroke>.from(previousStrokes),
      );
    }
  }

  @override
  void redo(DrawingController c) {
    if (layerIndex >= 0 && layerIndex < c.layers.length) {
      c.layers[layerIndex] = c.layers[layerIndex].copyWith(
        strokes: List<DrawingStroke>.from(nextStrokes),
      );
    }
  }
}
