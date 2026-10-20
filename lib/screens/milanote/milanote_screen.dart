import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/board_element.dart';
import '../../providers/board_data_provider.dart';
import 'models/note_style_config.dart';
import 'painters/board_chalk_painter.dart';
import 'painters/note_shape_utils.dart';
import 'widgets/pizarron_color_picker_area.dart';
import 'widgets/pizarron_note_widget.dart';
import 'widgets/pizarron_sidebar_overlay.dart';

/// Pizarrón Infinito de F.U.R.I. reconstruido desde cero:
/// - Coordenadas infinitas reales y carga dinámica en chunks (2x el tamaño de pantalla).
/// - Un único botón verde opaco vibrante (`#2EE50F`) abajo a la derecha (cero barras extras).
/// - Al desplegar el `+` aparecen 3 opciones solo con iconos: Nota, Lista de tareas y Tuerca (ajustes de fondo y tiza).
/// - Dibujo con textura de tiza directamente en la capa de fondo del pizarrón (debajo de las notas).
/// - Desambiguación multitáctil profesional:
///   * 1 dedo en pizarrón vacío -> desplaza el pizarrón (o dibuja con tiza si está activo).
///   * 1 dedo arrastrando nota -> mueve la nota con fluidez 1:1 sin importar el nivel de zoom.
///   * 1 toque en nota -> hace zoom suave hacia la nota y abre el sidebar derecho de edición.
///   * 2 dedos sobre una misma nota -> agranda/achica la nota incrementalmente desde todos sus lados.
///   * 2 dedos en el pizarrón (incluso tocando accidentalmente una nota con un dedo) -> hace zoom del pizarrón.
class MilanoteScreen extends StatefulWidget {
  final Object? mode;

  const MilanoteScreen({
    super.key,
    this.mode,
  });

  @override
  State<MilanoteScreen> createState() => _MilanoteScreenState();
}

class _MilanoteScreenState extends State<MilanoteScreen>
    with SingleTickerProviderStateMixin {
  static const int _boardId = 1;
  static const double _minCameraScale = 0.18;
  static const double _maxCameraScale = 4.0;
  static const Color _vibrantGreen = Color(0xFF2EE50F);

  // Estado de cámara del mundo infinito: screenPt = worldPt * _cameraScale + _cameraPan
  Offset _cameraPan = const Offset(60.0, 80.0);
  double _cameraScale = 1.0;

  late AnimationController _cameraAnimController;
  Offset _animStartPan = Offset.zero;
  Offset _animTargetPan = Offset.zero;
  double _animStartScale = 1.0;
  double _animTargetScale = 1.0;

  // Estado de edición de nota
  int? _editingElementId;
  ActiveTextTarget _activeTextTarget = const ActiveTextTarget.title();

  // Estado del botón '+' y panel de tuerca (fondo + tiza)
  bool _plusMenuOpen = false;
  bool _settingsOpen = false;
  bool _chalkMode = false;
  String _chalkColorHex = '#FFFFFF';
  double _chalkStrokeWidth = 7.0;
  final List<Offset> _liveChalkPoints = [];

  // Seguimiento multitáctil para desambiguar pan, zoom, drag de nota y pinch-scale de nota
  final Map<int, Offset> _activePointers = {};
  int? _singlePointerId;
  Offset? _pointerDownScreenPos;
  bool _hasExceededTapSlop = false;

  // Si el gesto de 1 dedo inició sobre una nota
  int? _touchedNoteId;
  Offset? _noteStartWorldPos;
  bool _isDraggingNote = false;
  bool _isResizingCorner = false;

  // Estado para gesto de 2 dedos (zoom de pizarrón vs agrandar nota de todos sus lados)
  bool _isTwoFingerGesture = false;
  int? _pinchingNoteId;
  double _initialPinchDistance = 1.0;
  Offset _initialPinchMidScreen = Offset.zero;
  Offset _initialCameraPanOnPinch = Offset.zero;
  double _initialCameraScaleOnPinch = 1.0;
  Rect? _initialNoteRectOnPinch;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_cameraAnimController.value);
        setState(() {
          _cameraPan = Offset.lerp(_animStartPan, _animTargetPan, t)!;
          _cameraScale =
              _animStartScale + (_animTargetScale - _animStartScale) * t;
        });
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BoardDataProvider>().load();
      }
    });
  }

  @override
  void dispose() {
    _cameraAnimController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MATEMÁTICA DE CÁMARA Y CHUNKS (2X VIEWPORT)
  // ===========================================================================
  Offset _screenToWorld(Offset screenPt) {
    return (screenPt - _cameraPan) / _cameraScale;
  }

  Matrix4 get _worldToScreenMatrix {
    return Matrix4.identity()
      ..translateByDouble(_cameraPan.dx, _cameraPan.dy, 0.0, 1.0)
      ..scaleByDouble(_cameraScale, _cameraScale, 1.0, 1.0);
  }

  /// Calcula el rectángulo del chunk activo en coordenadas del mundo equivalente
  /// al DOBLE (2x) de las dimensiones mostradas actualmente en pantalla.
  Rect _computeActiveChunkWorldRect(Size screenSize) {
    final worldVisibleWidth = screenSize.width / _cameraScale;
    final worldVisibleHeight = screenSize.height / _cameraScale;
    final worldTopLeft = _screenToWorld(Offset.zero);
    final visibleWorldRect = Rect.fromLTWH(
      worldTopLeft.dx,
      worldTopLeft.dy,
      worldVisibleWidth,
      worldVisibleHeight,
    );
    // Expandir 0.5x a cada lado => ancho total = 2x viewport, alto total = 2x viewport
    return visibleWorldRect.inflate(
      math.max(worldVisibleWidth * 0.5, 200.0),
    );
  }

  void _animateCameraTo({
    required Offset targetPan,
    required double targetScale,
  }) {
    _cameraAnimController.stop();
    _animStartPan = _cameraPan;
    _animTargetPan = targetPan;
    _animStartScale = _cameraScale;
    _animTargetScale = targetScale.clamp(_minCameraScale, _maxCameraScale);
    _cameraAnimController.forward(from: 0.0);
  }

  /// Hace zoom suave hacia una nota para editarla, encuadrándola en el espacio disponible
  /// a la izquierda del sidebar derecho de personalización.
  void _focusAndEditElement(BoardElement el, Size screenSize) {
    const double sidebarReservedWidth = 290.0;
    final availableWidth =
        math.max(180.0, screenSize.width - sidebarReservedWidth);
    final availableHeight = screenSize.height * 0.82;

    final scaleX = (availableWidth * 0.78) / math.max(120.0, el.width);
    final scaleY = (availableHeight * 0.78) / math.max(100.0, el.height);
    final idealScale = math.min(scaleX, scaleY).clamp(0.85, 1.65);

    final noteCenterWorld = Offset(
      el.x + el.width / 2,
      el.y + el.height / 2,
    );
    final targetScreenCenter = Offset(
      availableWidth * 0.50,
      screenSize.height * 0.48,
    );
    final targetPan = targetScreenCenter - (noteCenterWorld * idealScale);

    setState(() {
      _editingElementId = el.id;
      _activeTextTarget = const ActiveTextTarget.title();
      _plusMenuOpen = false;
      _settingsOpen = false;
      _chalkMode = false;
    });

    _animateCameraTo(
      targetPan: targetPan,
      targetScale: idealScale,
    );
  }

  void _closeEditMode() {
    if (_editingElementId == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _editingElementId = null;
    });
  }

  // ===========================================================================
  // DETECCIÓN DE COLISIÓN (HIT TESTING EN COORDENADAS DEL MUNDO)
  // ===========================================================================
  BoardElement? _hitTestNoteAtWorld(
    Offset worldPt,
    List<BoardElement> elements,
  ) {
    // Recorrer de arriba hacia abajo (los últimos en la lista están visualmente arriba)
    for (int i = elements.length - 1; i >= 0; i--) {
      final el = elements[i];
      final rect = Rect.fromLTWH(el.x, el.y, el.width, el.height);
      if (!rect.inflate(8.0).contains(worldPt)) continue;

      final cfg = NoteStyleConfig.fromElement(
        fallbackColor: el.color,
        data: el.data,
      );
      final localPt = worldPt - Offset(el.x, el.y);
      final path = NoteShapeUtils.buildShapePath(
        cfg.shapeType,
        Size(el.width, el.height),
      );
      if (path.contains(localPt) || rect.contains(worldPt)) {
        return el;
      }
    }
    return null;
  }

  bool _isPointOnResizeHandle(Offset worldPt, BoardElement el) {
    final cfg = NoteStyleConfig.fromElement(
      fallbackColor: el.color,
      data: el.data,
    );
    final handleLocal = NoteShapeUtils.getResizeHandleCenter(
      cfg.shapeType,
      Size(el.width, el.height),
    );
    final handleWorld = Offset(el.x, el.y) + handleLocal;
    final hitRadius = 22.0 / _cameraScale.clamp(0.4, 2.5);
    return (worldPt - handleWorld).distance <= hitRadius;
  }

  // ===========================================================================
  // GESTIÓN UNIFICADA DE PUNTEROS (PAN, ZOOM, DRAG 1:1, PINCH-SCALE EN NOTA, TIZA)
  // ===========================================================================
  void _onPointerDown(
    PointerDownEvent event,
    List<BoardElement> visibleElements,
    BoardDataProvider provider,
  ) {
    _cameraAnimController.stop();
    _activePointers[event.pointer] = event.localPosition;

    if (_activePointers.length == 1) {
      // Primer dedo en pantalla
      _singlePointerId = event.pointer;
      _pointerDownScreenPos = event.localPosition;
      _hasExceededTapSlop = false;
      _isTwoFingerGesture = false;
      _isDraggingNote = false;
      _isResizingCorner = false;

      final worldPt = _screenToWorld(event.localPosition);
      final hitEl = _hitTestNoteAtWorld(worldPt, visibleElements);

      if (hitEl != null && hitEl.id != null) {
        _touchedNoteId = hitEl.id;
        _noteStartWorldPos = Offset(hitEl.x, hitEl.y);
        if (_isPointOnResizeHandle(worldPt, hitEl)) {
          _isResizingCorner = true;
        }
      } else {
        _touchedNoteId = null;
        _noteStartWorldPos = null;
        if (_chalkMode && _editingElementId == null) {
          setState(() {
            _liveChalkPoints
              ..clear()
              ..add(worldPt);
          });
        }
      }
    } else if (_activePointers.length == 2) {
      // Segundo dedo toca la pantalla -> Desambiguación inmediata:
      // Si el primer dedo había empezado a mover ligeramente una nota por accidente,
      // restauramos su posición inicial para no arrastrarla mientras se hace zoom.
      if (_touchedNoteId != null &&
          _noteStartWorldPos != null &&
          _isDraggingNote) {
        provider.updatePositionLocal(
          _touchedNoteId!,
          _noteStartWorldPos!.dx,
          _noteStartWorldPos!.dy,
        );
      }
      _isDraggingNote = false;
      _isResizingCorner = false;
      _liveChalkPoints.clear();
      _isTwoFingerGesture = true;

      final pts = _activePointers.values.toList();
      final p1Screen = pts[0];
      final p2Screen = pts[1];
      _initialPinchDistance = math.max(10.0, (p1Screen - p2Screen).distance);
      _initialPinchMidScreen = (p1Screen + p2Screen) * 0.5;
      _initialCameraPanOnPinch = _cameraPan;
      _initialCameraScaleOnPinch = _cameraScale;

      // Verificar si AMBOS dedos están pinchando sobre la MISMA nota
      final p1World = _screenToWorld(p1Screen);
      final p2World = _screenToWorld(p2Screen);
      final hit1 = _hitTestNoteAtWorld(p1World, visibleElements);
      final hit2 = _hitTestNoteAtWorld(p2World, visibleElements);

      if (hit1 != null && hit2 != null && hit1.id != null && hit1.id == hit2.id) {
        // Pinch con 2 dedos sobre una nota -> Agrandar/achicar la nota de todos sus lados
        _pinchingNoteId = hit1.id;
        _initialNoteRectOnPinch =
            Rect.fromLTWH(hit1.x, hit1.y, hit1.width, hit1.height);
      } else {
        // Al menos un dedo está fuera o en otra zona -> Zoom y desplazamiento del pizarrón
        _pinchingNoteId = null;
        _initialNoteRectOnPinch = null;
      }
    }
  }

  void _onPointerMove(
    PointerMoveEvent event,
    Size screenSize,
    BoardDataProvider provider,
  ) {
    if (!_activePointers.containsKey(event.pointer)) return;
    final prevScreenPos = _activePointers[event.pointer]!;
    _activePointers[event.pointer] = event.localPosition;
    final deltaScreen = event.localPosition - prevScreenPos;

    // --- CASO 1: GESTO MULTITÁCTIL DE 2 DEDOS ---
    if (_activePointers.length >= 2) {
      final pts = _activePointers.values.toList();
      final p1 = pts[0];
      final p2 = pts[1];
      final currentDist = math.max(10.0, (p1 - p2).distance);
      final scaleRatio = currentDist / _initialPinchDistance;

      if (_pinchingNoteId != null && _initialNoteRectOnPinch != null) {
        // Agrandar o achicar la nota incrementalmente desde todos sus lados
        final baseRect = _initialNoteRectOnPinch!;
        final newW = (baseRect.width * scaleRatio).clamp(130.0, 950.0);
        final newH = (baseRect.height * scaleRatio).clamp(110.0, 950.0);
        final center = baseRect.center;
        final newX = center.dx - newW / 2;
        final newY = center.dy - newH / 2;

        provider.updateGeometryLocal(
          _pinchingNoteId!,
          x: newX,
          y: newY,
          width: newW,
          height: newH,
        );
      } else {
        // Zoom y paneo del pizarrón alrededor del punto medio de los 2 dedos
        final currentMid = (p1 + p2) * 0.5;
        final newScale = (_initialCameraScaleOnPinch * scaleRatio)
            .clamp(_minCameraScale, _maxCameraScale);
        final focalWorld =
            (_initialPinchMidScreen - _initialCameraPanOnPinch) /
                _initialCameraScaleOnPinch;
        final newPan = currentMid - (focalWorld * newScale);

        setState(() {
          _cameraScale = newScale;
          _cameraPan = newPan;
        });
      }
      return;
    }

    // --- CASO 2: GESTO DE 1 SOLO DEDO ---
    if (_isTwoFingerGesture) return;
    if (_singlePointerId != event.pointer) return;

    if (!_hasExceededTapSlop && _pointerDownScreenPos != null) {
      if ((event.localPosition - _pointerDownScreenPos!).distance > 6.0) {
        _hasExceededTapSlop = true;
      }
    }

    // Si tocó el agarre de esquina inferior derecha -> Redimensionar nota
    if (_isResizingCorner && _touchedNoteId != null) {
      final idx =
          provider.elements.indexWhere((e) => e.id == _touchedNoteId);
      if (idx != -1) {
        final el = provider.elements[idx];
        final dw = deltaScreen.dx / _cameraScale;
        final dh = deltaScreen.dy / _cameraScale;
        provider.updateGeometryLocal(
          el.id!,
          width: (el.width + dw).clamp(130.0, 950.0),
          height: (el.height + dh).clamp(110.0, 950.0),
        );
      }
      return;
    }

    // Si presionó sobre una nota -> Mover la nota (salvo que sea la nota que se está editando)
    if (_touchedNoteId != null) {
      if (_editingElementId == _touchedNoteId) {
        // Mientras se edita esa nota, permitir interactuar con su texto sin arrastrarla
        return;
      }
      if (!_hasExceededTapSlop) return;
      _isDraggingNote = true;
      final idx =
          provider.elements.indexWhere((e) => e.id == _touchedNoteId);
      if (idx != -1) {
        final el = provider.elements[idx];
        // División exacta por la escala en vivo del pizarrón -> velocidad 1:1 con o sin zoom
        final dxWorld = deltaScreen.dx / _cameraScale;
        final dyWorld = deltaScreen.dy / _cameraScale;
        provider.updatePositionLocal(
          el.id!,
          el.x + dxWorld,
          el.y + dyWorld,
        );
      }
      return;
    }

    // Si presionó sobre el fondo vacío del pizarrón:
    if (_chalkMode && _editingElementId == null) {
      final worldPt = _screenToWorld(event.localPosition);
      setState(() {
        _liveChalkPoints.add(worldPt);
      });
      return;
    }

    // Desplazar la cámara por el pizarrón infinito
    if (_hasExceededTapSlop) {
      setState(() {
        _cameraPan += deltaScreen;
      });
    }
  }

  void _onPointerUpOrCancel(
    PointerEvent event,
    Size screenSize,
    BoardDataProvider provider,
  ) {
    _activePointers.remove(event.pointer);

    // Si estaba dibujando con tiza en el fondo, guardar el trazo
    if (_chalkMode && _liveChalkPoints.isNotEmpty && _activePointers.isEmpty) {
      final pts = List<Offset>.from(_liveChalkPoints);
      setState(() {
        _liveChalkPoints.clear();
      });
      provider.addChalkStroke(
        boardId: _boardId,
        points: pts,
        colorHex: _chalkColorHex,
        strokeWidth: _chalkStrokeWidth,
      );
    }

    // Si fue un toque limpio (sin arrastrar) con 1 solo dedo
    if (!_isTwoFingerGesture &&
        !_hasExceededTapSlop &&
        event is PointerUpEvent) {
      if (_touchedNoteId != null) {
        final idx =
            provider.elements.indexWhere((e) => e.id == _touchedNoteId);
        if (idx != -1) {
          final tappedEl = provider.elements[idx];
          if (_editingElementId != tappedEl.id) {
            _focusAndEditElement(tappedEl, screenSize);
          }
        }
      } else {
        // Toque en el fondo vacío del pizarrón
        if (_editingElementId != null) {
          _closeEditMode();
        } else if (_plusMenuOpen || _settingsOpen) {
          setState(() {
            _plusMenuOpen = false;
            _settingsOpen = false;
          });
        }
      }
    }

    if (_activePointers.isEmpty) {
      _singlePointerId = null;
      _touchedNoteId = null;
      _noteStartWorldPos = null;
      _isDraggingNote = false;
      _isResizingCorner = false;
      _isTwoFingerGesture = false;
      _pinchingNoteId = null;
      _initialNoteRectOnPinch = null;
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _cameraAnimController.stop();
      final zoomDelta = event.scrollDelta.dy < 0 ? 1.12 : 0.89;
      final newScale =
          (_cameraScale * zoomDelta).clamp(_minCameraScale, _maxCameraScale);
      final focalWorld = _screenToWorld(event.localPosition);
      final newPan = event.localPosition - (focalWorld * newScale);
      setState(() {
        _cameraScale = newScale;
        _cameraPan = newPan;
      });
    }
  }

  // ===========================================================================
  // CREACIÓN Y EDICIÓN DE ELEMENTOS (NOTA / LISTA DE TAREAS / IMÁGENES)
  // ===========================================================================
  Future<void> _createNewElement(
    String type,
    Size screenSize,
    BoardDataProvider provider,
  ) async {
    final centerWorld = _screenToWorld(
      Offset(screenSize.width / 2, screenSize.height / 2),
    );
    const width = 260.0;
    const height = 220.0;

    final defaultConfig = NoteStyleConfig(
      solidColor: type == 'checklist' ? '#1F2D1E' : '#1E2436',
      checklistItems: type == 'checklist'
          ? [
              {'text': '', 'done': false},
            ]
          : const [],
    );

    final created = await provider.addElement(
      boardId: _boardId,
      type: type,
      title: '',
      content: '',
      color: defaultConfig.solidColor,
      x: centerWorld.dx - width / 2,
      y: centerWorld.dy - height / 2,
      width: width,
      height: height,
      data: defaultConfig.toDataMap(),
    );

    if (!mounted) return;
    _focusAndEditElement(created, screenSize);
  }

  Future<void> _pickImageForEditingNote({
    required bool isBackground,
    required BoardElement element,
    required NoteStyleConfig currentConfig,
    required BoardDataProvider provider,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1100,
        maxHeight: 1100,
        imageQuality: 78,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);

      final updatedCfg = isBackground
          ? currentConfig.copyWith(
              baseMode: 'image',
              bgImageBase64: b64,
            )
          : currentConfig.copyWith(
              inlineImageBase64: b64,
            );

      await provider.updateElement(
        element.copyWith(
          color: updatedCfg.solidColor,
          data: updatedCfg.toDataMap(),
        ),
      );
    } catch (_) {}
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final provider = context.watch<BoardDataProvider>();

    // Chunk activo = 2x el tamaño de lo mostrado actualmente en pantalla
    final activeChunkWorldRect = _computeActiveChunkWorldRect(screenSize);

    // Filtrar solo notas/listas de tareas y trazos de tiza dentro del chunk 2x
    final chunkElements = provider.getInteractiveElementsInChunk(
      _boardId,
      activeChunkWorldRect,
      alwaysIncludeId: _editingElementId ?? _touchedNoteId,
    );
    final chunkChalkStrokes = provider.getChalkStrokesInChunk(
      _boardId,
      activeChunkWorldRect,
    );

    final boardBgHex = provider.getBoardBackgroundColor(_boardId);
    final boardBgColor = PizarronPalette.parseHex(
      boardBgHex,
      fallback: const Color(0xFF141820),
    );

    BoardElement? editingElement;
    if (_editingElementId != null) {
      final idx =
          provider.elements.indexWhere((e) => e.id == _editingElementId);
      if (idx != -1) {
        editingElement = provider.elements[idx];
      }
    }

    return Scaffold(
      backgroundColor: boardBgColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. LIENZO INFINITO (FONDO DE TIZA + OBJETOS DEL CHUNK ACTIVO)
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onPointerDown(e, chunkElements, provider),
            onPointerMove: (e) => _onPointerMove(e, screenSize, provider),
            onPointerUp: (e) => _onPointerUpOrCancel(e, screenSize, provider),
            onPointerCancel: (e) =>
                _onPointerUpOrCancel(e, screenSize, provider),
            onPointerSignal: _onPointerSignal,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // Capa 0: Fondo sólido + Puntos espaciales + Trazos de Tiza (debajo de las notas)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardChalkBackgroundPainter(
                      worldToScreenMatrix: _worldToScreenMatrix,
                      activeWorldChunkRect: activeChunkWorldRect,
                      boardBackgroundColor: boardBgColor,
                      activeChalkStrokes: chunkChalkStrokes,
                      currentLiveStroke: _liveChalkPoints,
                      currentChalkColorHex: _chalkColorHex,
                      currentChalkWidth: _chalkStrokeWidth,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // Capa 1: Notas y Listas de Tareas del chunk activo transformadas por la cámara
                Transform(
                  transform: _worldToScreenMatrix,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final el in chunkElements)
                        _buildPositionedElement(el, provider),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. OVERLAY LATERAL DERECHO (Solo cuando una nota está en modo edición)
          if (editingElement != null)
            Align(
              alignment: Alignment.centerRight,
              child: PizarronSidebarOverlay(
                config: NoteStyleConfig.fromElement(
                  fallbackColor: editingElement.color,
                  data: editingElement.data,
                ),
                activeTarget: _activeTextTarget,
                onTargetChanged: (t) => setState(() => _activeTextTarget = t),
                onConfigChanged: (updatedCfg) {
                  provider.updateElement(
                    editingElement!.copyWith(
                      color: updatedCfg.solidColor,
                      data: updatedCfg.toDataMap(),
                    ),
                  );
                },
                onPickBackgroundImage: () => _pickImageForEditingNote(
                  isBackground: true,
                  element: editingElement!,
                  currentConfig: NoteStyleConfig.fromElement(
                    fallbackColor: editingElement.color,
                    data: editingElement.data,
                  ),
                  provider: provider,
                ),
                onPickInlineImage: () => _pickImageForEditingNote(
                  isBackground: false,
                  element: editingElement!,
                  currentConfig: NoteStyleConfig.fromElement(
                    fallbackColor: editingElement.color,
                    data: editingElement.data,
                  ),
                  provider: provider,
                ),
                onDuplicate: () async {
                  final id = editingElement!.id;
                  if (id == null) return;
                  final copy = await provider.duplicateElement(id);
                  if (copy != null && mounted) {
                    _focusAndEditElement(copy, screenSize);
                  }
                },
                onDelete: () async {
                  final id = editingElement!.id;
                  _closeEditMode();
                  if (id != null) {
                    await provider.deleteElement(id);
                  }
                },
                onCloseEdit: _closeEditMode,
              ),
            ),

          // 3. ÚNICO BOTÓN '+' VERDE OPACO VIBRANTE ABAJO A LA DERECHA
          // (Oculto mientras se edita una nota para dejar lugar al sidebar derecho)
          if (editingElement == null)
            Positioned(
              right: 20,
              bottom: 24,
              child: _buildBottomRightSingleButtonCluster(
                screenSize,
                provider,
                boardBgHex,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPositionedElement(
    BoardElement el,
    BoardDataProvider provider,
  ) {
    final isEditing = _editingElementId != null && _editingElementId == el.id;
    final styleConfig = NoteStyleConfig.fromElement(
      fallbackColor: el.color,
      data: el.data,
    );

    return Positioned(
      key: ValueKey('pizarron_el_${el.id}'),
      left: el.x,
      top: el.y,
      width: el.width,
      height: el.height,
      child: RepaintBoundary(
        child: PizarronNoteWidget(
          element: el,
          styleConfig: styleConfig,
          isEditing: isEditing,
          getCurrentCanvasScale: () => _cameraScale,
          activeTarget: isEditing
              ? _activeTextTarget
              : const ActiveTextTarget.bodyDefault(),
          onActiveTargetChanged: (target) {
            if (isEditing) {
              setState(() => _activeTextTarget = target);
            }
          },
          onTapNote: () {
            if (!isEditing) {
              _focusAndEditElement(el, MediaQuery.of(context).size);
            }
          },
          onDragNote: (dx, dy) {
            if (el.id != null) {
              provider.updatePositionLocal(el.id!, el.x + dx, el.y + dy);
            }
          },
          onResizeNote: (dw, dh) {
            if (el.id != null) {
              provider.updateGeometryLocal(
                el.id!,
                width: (el.width + dw).clamp(130.0, 950.0),
                height: (el.height + dh).clamp(110.0, 950.0),
              );
            }
          },
          onPinchScaleNote: (scaleFactor, focalWorld) {},
          onTextChanged: (newTitle, newContent) {
            provider.updateElement(
              el.copyWith(
                title: newTitle,
                content: newContent,
              ),
            );
          },
          onStyleChanged: (updatedCfg) {
            provider.updateElement(
              el.copyWith(
                color: updatedCfg.solidColor,
                data: updatedCfg.toDataMap(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // CLUSTER DEL ÚNICO BOTÓN '+' ABAJO A LA DERECHA (100% ICONOS, CERO LETRAS)
  // ===========================================================================
  Widget _buildBottomRightSingleButtonCluster(
    Size screenSize,
    BoardDataProvider provider,
    String currentBoardBgHex,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Panel de Tuerca (Personalizar color sólido del pizarrón + Tiza en el fondo)
        if (_settingsOpen || _chalkMode) ...[
          Container(
            width: 228,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila superior: Color de fondo del pizarrón vs Modo Tiza
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallOptionButton(
                      icon: Icons.palette_rounded,
                      active: !_chalkMode,
                      onTap: () => setState(() => _chalkMode = false),
                    ),
                    _buildSmallOptionButton(
                      icon: Icons.edit_rounded,
                      active: _chalkMode,
                      activeColor: _vibrantGreen,
                      activeIconColor: const Color(0xFF141820),
                      onTap: () => setState(() => _chalkMode = !_chalkMode),
                    ),
                    if (_chalkMode) ...[
                      _buildSmallOptionButton(
                        icon: Icons.undo_rounded,
                        active: false,
                        onTap: () => provider.undoLastChalkStroke(_boardId),
                      ),
                      _buildSmallOptionButton(
                        icon: Icons.cleaning_services_rounded,
                        active: false,
                        onTap: () => provider.clearChalkStrokes(_boardId),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                if (!_chalkMode) ...[
                  // Selector con cuadrado de saturación, cuentagotas y recientes para el fondo
                  PizarronColorPickerArea(
                    currentColorHex: currentBoardBgHex,
                    sampledColors: PizarronPalette.boardColors,
                    onColorChanged: (hex) =>
                        provider.setBoardBackgroundColor(_boardId, hex),
                  ),
                ] else ...[
                  // Selector con cuadrado de saturación, cuentagotas y recientes para la tiza
                  PizarronColorPickerArea(
                    currentColorHex: _chalkColorHex,
                    sampledColors: PizarronPalette.chalkColors,
                    onColorChanged: (hex) =>
                        setState(() => _chalkColorHex = hex),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.line_weight_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            activeTrackColor: _vibrantGreen,
                            inactiveTrackColor: const Color(0xFF252C40),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _chalkStrokeWidth,
                            min: 3.0,
                            max: 20.0,
                            onChanged: (v) =>
                                setState(() => _chalkStrokeWidth = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Opciones al tocar el botón '+': Nota, Lista de Tareas y Tuerca (Ajustes)
        if (_plusMenuOpen) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Tuerca: personalizar fondo y tiza
                _buildOptionOrb(
                  key: const ValueKey('pizarron_opt_settings'),
                  icon: Icons.settings_rounded,
                  bgColor: _settingsOpen
                      ? const Color(0xFF7B2CBF)
                      : const Color(0xFF252C40),
                  iconColor: Colors.white,
                  onTap: () {
                    setState(() {
                      _settingsOpen = !_settingsOpen;
                      if (!_settingsOpen) _chalkMode = false;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // 2. Lista de tareas
                _buildOptionOrb(
                  key: const ValueKey('pizarron_opt_checklist'),
                  icon: Icons.checklist_rounded,
                  bgColor: const Color(0xFF252C40),
                  iconColor: Colors.white,
                  onTap: () => _createNewElement(
                    'checklist',
                    screenSize,
                    provider,
                  ),
                ),
                const SizedBox(height: 10),
                // 3. Nota
                _buildOptionOrb(
                  key: const ValueKey('pizarron_opt_note'),
                  icon: Icons.sticky_note_2_rounded,
                  bgColor: const Color(0xFF252C40),
                  iconColor: Colors.white,
                  onTap: () => _createNewElement(
                    'note',
                    screenSize,
                    provider,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Botón único principal '+' verde opaco vibrante
        GestureDetector(
          key: const ValueKey('pizarron_main_plus_button'),
          onTap: () {
            setState(() {
              if (_chalkMode) {
                _chalkMode = false;
                _settingsOpen = false;
                _plusMenuOpen = false;
              } else {
                _plusMenuOpen = !_plusMenuOpen;
                if (!_plusMenuOpen) {
                  _settingsOpen = false;
                }
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _vibrantGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              (_plusMenuOpen || _chalkMode)
                  ? Icons.close_rounded
                  : Icons.add_rounded,
              color: const Color(0xFF141820),
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionOrb({
    Key? key,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSmallOptionButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color activeColor = const Color(0xFF7B2CBF),
    Color activeIconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 40,
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0xFF252C40),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: active ? activeIconColor : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
