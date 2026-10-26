import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../helpers/drawing_render_exporter.dart';
import '../models/canvas_background_type.dart';
import '../models/drawing_lasso_selection.dart';
import '../models/drawing_layer.dart';
import '../models/drawing_point.dart';
import '../models/drawing_project.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_symmetry_mode.dart';
import '../models/drawing_tool_type.dart';
import 'drawing_action.dart';
import 'drawing_lasso_operations.dart';
import 'drawing_layer_operations.dart';
import 'drawing_stroke_operations.dart';
import 'drawing_stroke_stabilizer.dart';

/// Controlador central del taller de dibujo con soporte de simetría,
/// formas geométricas, estabilización anti-temblores y trazo predictivo.
class DrawingController extends ChangeNotifier {
  String _projectId;
  String _projectTitle = 'Sin Título';
  CanvasBackgroundType _backgroundType = CanvasBackgroundType.blank;
  List<DrawingLayer> _layers = [];
  int _activeLayerIndex = 0;

  DrawingToolType _selectedTool = DrawingToolType.pen;
  DrawingToolType _previousDrawingTool = DrawingToolType.pen;
  Color _selectedColor = const Color(0xFF111111);
  double _strokeWidth = DrawingToolType.pen.defaultWidth;
  double _strokeOpacity = DrawingToolType.pen.defaultOpacity;

  // Estabilización, Trazo Predictivo y Guía Visual de Pincel
  final _stabilizer = DrawingStrokeStabilizer();
  bool _isPredictiveStrokeEnabled = false;
  int _predictiveStrokeLevel = 5;
  bool _showBrushCursor = true;

  DrawingSymmetryMode _symmetryMode = DrawingSymmetryMode.none;
  Size _canvasSize = const Size(2000, 2000);
  bool _isRotationLocked = false, _isFlippedHorizontal = false, _isFlippedVertical = false;

  DrawingLassoSelection? _activeSelection;
  DrawingStroke? _activeStroke;
  List<DrawingStroke> _activeMirroredStrokes = [];
  final List<DrawingAction> _undoStack = [], _redoStack = [];

  DrawingController({DrawingProject? initialProject})
      : _projectId = initialProject?.id ?? 'proj_${DateTime.now().millisecondsSinceEpoch}' {
    if (initialProject != null) {
      loadProject(initialProject);
    } else {
      _layers = [DrawingLayer(id: 'layer_${DateTime.now().microsecondsSinceEpoch}', name: 'Capa 1', strokes: [])];
    }
  }

  String get projectId => _projectId;
  String get projectTitle => _projectTitle;
  DrawingProject get project => toProject();
  double get canvasWidth => _canvasSize.width;
  double get canvasHeight => _canvasSize.height;
  CanvasBackgroundType get backgroundType => _backgroundType;
  List<DrawingLayer> get layers => _layers;
  int get activeLayerIndex => _activeLayerIndex;
  DrawingLayer get activeLayer =>
      _layers.isNotEmpty ? _layers[_activeLayerIndex] : DrawingLayer(id: '0', name: '1', strokes: []);

  DrawingToolType get selectedTool => _selectedTool;
  DrawingToolType get previousDrawingTool => _previousDrawingTool;
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  double get strokeOpacity => _strokeOpacity;
  DrawingStroke? get activeStroke => _activeStroke;
  List<DrawingStroke> get activeMirroredStrokes => _activeMirroredStrokes;
  DrawingLassoSelection? get activeSelection => _activeSelection;
  bool get hasSelection => _activeSelection != null;
  set activeSelection(DrawingLassoSelection? sel) { _activeSelection = sel; notifyListeners(); }

  bool get isPredictiveStrokeEnabled => _isPredictiveStrokeEnabled;
  int get predictiveStrokeLevel => _predictiveStrokeLevel;
  void setPredictiveStrokeEnabled(bool val) { _isPredictiveStrokeEnabled = val; notifyListeners(); }
  void setPredictiveStrokeLevel(int level) { _predictiveStrokeLevel = level.clamp(1, 10); notifyListeners(); }
  bool get showBrushCursor => _showBrushCursor;
  void setShowBrushCursor(bool val) { _showBrushCursor = val; notifyListeners(); }
  void toggleShowBrushCursor() { _showBrushCursor = !_showBrushCursor; notifyListeners(); }

  DrawingSymmetryMode get symmetryMode => _symmetryMode;
  Size get canvasSize => _canvasSize;
  bool get isRotationLocked => _isRotationLocked;
  bool get isFlippedHorizontal => _isFlippedHorizontal;
  bool get isFlippedVertical => _isFlippedVertical;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setTitle(String title) { _projectTitle = title; notifyListeners(); }
  void setBackgroundType(CanvasBackgroundType type) { _backgroundType = type; notifyListeners(); }
  void setCanvasSize(Size s) { if (_canvasSize != s) { _canvasSize = s; notifyListeners(); } }
  void setSymmetryMode(DrawingSymmetryMode m) { _symmetryMode = m; notifyListeners(); }
  void toggleRotationLock() { _isRotationLocked = !_isRotationLocked; notifyListeners(); }
  void flipCanvasHorizontal() { _isFlippedHorizontal = !_isFlippedHorizontal; notifyListeners(); }
  void flipCanvasVertical() { _isFlippedVertical = !_isFlippedVertical; notifyListeners(); }

  void loadProject(DrawingProject project) {
    _projectId = project.id;
    _projectTitle = project.title;
    if (project.canvasWidth > 0 && project.canvasHeight > 0) {
      _canvasSize = Size(project.canvasWidth, project.canvasHeight);
    }
    _layers = List<DrawingLayer>.from(project.layers.isEmpty ? [DrawingLayer(id: 'l1', name: 'Capa 1', strokes: [])] : project.layers);
    _activeLayerIndex = 0;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  DrawingProject toProject({String? thumbnailBase64}) => DrawingProject(
        id: _projectId, title: _projectTitle, canvasWidth: _canvasSize.width,
        canvasHeight: _canvasSize.height, updatedAt: DateTime.now(),
        layers: List<DrawingLayer>.from(_layers), thumbnailBase64: thumbnailBase64,
      );

  void cancelActiveStroke() {
    _activeStroke = null;
    _activeMirroredStrokes = [];
    _stabilizer.reset();
    notifyListeners();
  }

  void selectTool(DrawingToolType tool) {
    if (!tool.isEraser && !tool.isSmudge && !tool.isShape && !tool.isLasso && !tool.isFill) {
      _previousDrawingTool = tool;
    }
    _selectedTool = tool;
    _strokeWidth = tool.defaultWidth;
    _strokeOpacity = tool.defaultOpacity;
    if (tool != DrawingToolType.lasso && _activeSelection != null) _activeSelection = null;
    notifyListeners();
  }

  void toggleTool(DrawingToolType tool) =>
      selectTool(_selectedTool == tool ? _previousDrawingTool : tool);

  void updateActiveLayerStrokes(List<DrawingStroke> strokes) { _layers[_activeLayerIndex] = activeLayer.copyWith(strokes: strokes); notifyListeners(); }
  void recordStrokesUpdate(List<DrawingStroke> prev, List<DrawingStroke> next) { _undoStack.add(UpdateLayerStrokesAction(_activeLayerIndex, prev, next)); _redoStack.clear(); }
  void addDirectStroke(DrawingStroke stroke) => _addDirectStroke(stroke);
  void moveSelection(Offset delta) => DrawingLassoOperations.applyMoveSelection(this, delta);
  void duplicateSelection() => DrawingLassoOperations.applyDuplicateSelection(this);
  void deleteSelection() => DrawingLassoOperations.applyDeleteSelection(this);
  void fillSelection() => DrawingLassoOperations.applyFillSelection(this);
  void flipSelectionHorizontal() => DrawingLassoOperations.applyFlipSelectionHorizontal(this);
  void clearSelection() { if (_activeSelection != null) { _activeSelection = null; notifyListeners(); } }
  void setColor(Color c) { _selectedColor = c; notifyListeners(); }
  void setStrokeWidth(double w) { _strokeWidth = w; notifyListeners(); }
  void setOpacity(double o) { _strokeOpacity = o; notifyListeners(); }
  void setStrokeOpacity(double o) => setOpacity(o);

  void setActiveLayer(int i) { if (i >= 0 && i < _layers.length) { _activeLayerIndex = i; notifyListeners(); } }
  void addLayer({String? name}) { final res = DrawingLayerOperations.addLayer(_layers, name: name); _layers = res.$1; _activeLayerIndex = res.$2; notifyListeners(); }
  bool removeLayer(int i) {
    final res = DrawingLayerOperations.removeLayer(_layers, _activeLayerIndex, i);
    if (res == null) return false;
    _layers = res.$1; _activeLayerIndex = res.$2; notifyListeners();
    return true;
  }
  void toggleLayerVisibility(int i) { _layers = DrawingLayerOperations.toggleVisibility(_layers, i); notifyListeners(); }
  void duplicateActiveLayer() { final res = DrawingLayerOperations.duplicateLayer(_layers, _activeLayerIndex); _layers = res.$1; _activeLayerIndex = res.$2; notifyListeners(); }
  void rotateActiveLayer90() { _layers = DrawingLayerOperations.rotateLayer90(_layers, _activeLayerIndex, _canvasSize); notifyListeners(); }
  void invertActiveLayerColors() { _layers = DrawingLayerOperations.invertLayerColors(_layers, _activeLayerIndex); notifyListeners(); }
  void cycleBackgroundPattern() => setBackgroundType(switch (_backgroundType) {
    CanvasBackgroundType.blank => CanvasBackgroundType.grid,
    CanvasBackgroundType.grid => CanvasBackgroundType.dots,
    CanvasBackgroundType.dots => CanvasBackgroundType.dark,
    CanvasBackgroundType.dark => CanvasBackgroundType.blank,
  });
  void setLayerOpacity(int i, double o) { _layers = DrawingLayerOperations.setOpacity(_layers, i, o); notifyListeners(); }

  void clearActiveLayer() {
    if (_layers.isEmpty || activeLayer.strokes.isEmpty) return;
    final prev = List<DrawingStroke>.from(activeLayer.strokes);
    _layers[_activeLayerIndex] = activeLayer.copyWith(strokes: []);
    _undoStack.add(ClearLayerAction(_activeLayerIndex, prev));
    _redoStack.clear();
    notifyListeners();
  }

  void _addDirectStroke(DrawingStroke stroke) {
    _layers[_activeLayerIndex] = activeLayer.copyWith(strokes: List<DrawingStroke>.from(activeLayer.strokes)..add(stroke));
    _undoStack.add(AddStrokeAction(_activeLayerIndex, stroke));
    _redoStack.clear();
    notifyListeners();
  }

  void floodFill(Offset p, Color c) {
    if (_layers.isEmpty || !activeLayer.isVisible || activeLayer.isLocked) return;
    _addDirectStroke(DrawingStrokeOperations.createFloodFill(p, c, _strokeOpacity));
  }
  void applyGradient(Offset s, Offset e, Color c) {
    if (_layers.isEmpty || !activeLayer.isVisible || activeLayer.isLocked) return;
    _addDirectStroke(DrawingStrokeOperations.createGradient(s, e, c, _strokeOpacity));
  }

  void startStroke(Offset localPosition, [double pressure = 1.0]) {
    if (_layers.isEmpty || !activeLayer.isVisible || activeLayer.isLocked) return;
    final ts = DateTime.now().microsecondsSinceEpoch;
    _stabilizer.start(localPosition);
    _activeStroke = DrawingStroke(
      id: 'stroke_$ts',
      tool: _selectedTool,
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      opacity: _strokeOpacity,
      points: [DrawingPoint(offset: localPosition, pressure: pressure)],
    );
    _activeMirroredStrokes = DrawingStrokeOperations.buildMirroredStrokes(
      tool: _selectedTool, color: _selectedColor, width: _strokeWidth, opacity: _strokeOpacity,
      mode: _symmetryMode, point: localPosition, pressure: pressure, canvasSize: _canvasSize, timestamp: ts,
    );
    notifyListeners();
  }

  void updateStroke(Offset localPosition, [double pressure = 1.0]) {
    if (_activeStroke == null) return;
    if (_selectedTool.requiresDragVector) {
      final first = _activeStroke!.points.first;
      _activeStroke = _activeStroke!.copyWith(points: [first, DrawingPoint(offset: localPosition, pressure: pressure)]);
    } else {
      final (nextPoint, shouldSkip) = _stabilizer.update(
        localPosition,
        isPredictiveEnabled: _isPredictiveStrokeEnabled,
        predictiveLevel: _predictiveStrokeLevel,
      );
      if (shouldSkip) return;

      final updated = List<DrawingPoint>.from(_activeStroke!.points)
        ..add(DrawingPoint(offset: nextPoint, pressure: pressure));
      _activeStroke = _activeStroke!.copyWith(points: updated);
    }

    if (_symmetryMode != DrawingSymmetryMode.none && _activeMirroredStrokes.isNotEmpty) {
      final projected = _symmetryMode.projectPoints(_activeStroke!.points.map((p) => p.offset).toList(), _canvasSize);
      for (int i = 0; i < projected.length && i < _activeMirroredStrokes.length; i++) {
        final pts = projected[i].map((pt) => DrawingPoint(offset: pt, pressure: pressure)).toList();
        _activeMirroredStrokes[i] = _activeMirroredStrokes[i].copyWith(points: pts);
      }
    }
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke == null) return;
    var stroke = _activeStroke!;
    final mirrors = List<DrawingStroke>.from(_activeMirroredStrokes);
    _activeStroke = null;
    _activeMirroredStrokes = [];

    if (!_selectedTool.requiresDragVector) {
      final ending = _stabilizer.finish(stroke.points.isNotEmpty ? stroke.points.last.pressure : 1.0);
      if (ending.isNotEmpty) {
        stroke = stroke.copyWith(points: List<DrawingPoint>.from(stroke.points)..addAll(ending));
      }
    } else {
      _stabilizer.reset();
    }

    if (stroke.tool == DrawingToolType.lasso) {
      if (stroke.points.length >= 3) {
        final poly = stroke.points.map((p) => p.offset).toList();
        _activeSelection = DrawingLassoOperations.createSelection(poly, activeLayer.strokes);
      }
      notifyListeners();
      return;
    }

    final allStrokes = [stroke, ...mirrors];
    final updatedStrokes = List<DrawingStroke>.from(activeLayer.strokes)..addAll(allStrokes);
    _layers[_activeLayerIndex] = activeLayer.copyWith(strokes: updatedStrokes);

    _undoStack.add(AddStrokesGroupAction(_activeLayerIndex, allStrokes));
    _redoStack.clear();
    notifyListeners();
  }

  void undo() { if (!canUndo) return; final a = _undoStack.removeLast(); a.undo(this); _redoStack.add(a); notifyListeners(); }
  void redo() { if (!canRedo) return; final a = _redoStack.removeLast(); a.redo(this); _undoStack.add(a); notifyListeners(); }
  Future<Uint8List?> exportToPng({Size size = const Size(1080, 1080)}) =>
      DrawingRenderExporter.exportToPng(layers: _layers, backgroundType: _backgroundType, size: size, canvasSize: _canvasSize);
}
