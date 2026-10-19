import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/board_element.dart';
import '../../providers/board_data_provider.dart';
import '../../theme/app_theme.dart';
import 'milanote_colors.dart';
import 'painters/connector_line_painter.dart';
import 'painters/milanote_grid_painter.dart';
import 'widgets/milanote_dock.dart';
import 'widgets/milanote_element_card.dart';

/// Pantalla principal del Tablero Milanote
class MilanoteScreen extends StatefulWidget {
  final AppMode mode;
  final int initialBoardId;

  const MilanoteScreen({
    super.key,
    this.mode = AppMode.dark,
    this.initialBoardId = 1,
  });

  @override
  State<MilanoteScreen> createState() => _MilanoteScreenState();
}

class _MilanoteScreenState extends State<MilanoteScreen> {
  final TransformationController _transformController = TransformationController();
  final double _boardWidth = 2400.0;
  final double _boardHeight = 1600.0;
  final double _gridSpacing = 28.0;

  int _currentBoardId = 1;
  final List<Map<String, dynamic>> _boardStack = [
    {'id': 1, 'title': 'Pizarrón'}
  ];

  int? _selectedElementId;
  BoardElement? _connectingSource;
  bool _snapToGrid = true;
  bool _isDraggingElement = false;
  final ValueNotifier<BoardElement?> _activeDragNotifier = ValueNotifier<BoardElement?>(null);

  @override
  void initState() {
    super.initState();
    _currentBoardId = widget.initialBoardId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
      context.read<BoardDataProvider>().load();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _activeDragNotifier.dispose();
    super.dispose();
  }

  void _centerView() {
    final size = MediaQuery.of(context).size;
    final scaleX = size.width / (_boardWidth * 0.85);
    final scaleY = size.height / (_boardHeight * 0.85);
    final initialScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.45, 0.95);
    final cx = (_boardWidth * initialScale - size.width) / 2;
    final cy = (_boardHeight * initialScale - size.height) / 2;

    _transformController.value = Matrix4.identity()
      ..scaleByDouble(initialScale, initialScale, 1.0, 1.0)
      ..translateByDouble(-cx / initialScale, -cy / initialScale, 0.0, 1.0);
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 2.5) {
      _transformController.value = _transformController.value.clone()
        ..scaleByDouble(1.25, 1.25, 1.0, 1.0);
      setState(() {});
    }
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.25) {
      _transformController.value = _transformController.value.clone()
        ..scaleByDouble(0.8, 0.8, 1.0, 1.0);
      setState(() {});
    }
  }

  void _resetZoom() {
    _centerView();
    setState(() {});
  }

  Offset _getViewportCenterInWorld() {
    final size = MediaQuery.of(context).size;
    final screenCenter = Offset(size.width / 2, size.height / 2);
    final inv = Matrix4.tryInvert(_transformController.value);
    if (inv == null) return Offset(_boardWidth / 2, _boardHeight / 2);
    final pt = MatrixUtils.transformPoint(inv, screenCenter);
    return Offset(
      pt.dx.clamp(60.0, _boardWidth - 60.0),
      pt.dy.clamp(60.0, _boardHeight - 60.0),
    );
  }

  double _snap(double val) {
    if (!_snapToGrid) return val;
    return (val / _gridSpacing).round() * _gridSpacing;
  }

  void _handleToolSelected(MilanoteToolType type) async {
    final pv = context.read<BoardDataProvider>();
    final center = _getViewportCenterInWorld();
    final spawnX = _snap((center.dx - 110).clamp(40.0, _boardWidth - 280.0));
    final spawnY = _snap((center.dy - 90).clamp(40.0, _boardHeight - 220.0));

    switch (type) {
      case MilanoteToolType.note:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'note',
          title: 'Nueva Nota',
          content: 'Escribe aquí tus ideas...',
          color: MilanotePalette.toHex(MilanotePalette.noteYellow),
          x: spawnX,
          y: spawnY,
          width: 230,
          height: 180,
        );
        break;

      case MilanoteToolType.board:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'board',
          title: 'Sub-Tablero',
          content: 'Espacio anidado para proyecto',
          color: MilanotePalette.toHex(MilanotePalette.noteBlue),
          x: spawnX,
          y: spawnY,
          width: 240,
          height: 150,
        );
        break;

      case MilanoteToolType.column:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'column',
          title: 'Por Hacer',
          content: '',
          color: MilanotePalette.toHex(const Color(0xFF2C2F36)),
          x: spawnX,
          y: spawnY,
          width: 260,
          height: 380,
        );
        break;

      case MilanoteToolType.checklist:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'checklist',
          title: 'Lista de Tareas',
          color: MilanotePalette.toHex(MilanotePalette.noteMint),
          x: spawnX,
          y: spawnY,
          width: 240,
          height: 220,
          data: {
            'items': [
              {'text': 'Primer paso del proyecto', 'checked': false},
              {'text': 'Segunda tarea', 'checked': false},
            ]
          },
        );
        break;

      case MilanoteToolType.connect:
        if (_selectedElementId != null) {
          final elements = pv.getElementsByBoard(_currentBoardId);
          final match = elements.firstWhere((e) => e.id == _selectedElementId, orElse: () => elements.first);
          setState(() {
            _connectingSource = match;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona primero una tarjeta para conectar'), duration: Duration(seconds: 2)),
          );
        }
        break;

      case MilanoteToolType.colorSwatch:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'colorSwatch',
          title: 'Paleta Creativa',
          color: MilanotePalette.toHex(MilanotePalette.notePeach),
          x: spawnX,
          y: spawnY,
          width: 170,
          height: 160,
          data: {'hex': '#FF8A65'},
        );
        break;

      case MilanoteToolType.image:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'image',
          title: 'Inspiración Visual',
          content: 'Referencia de diseño',
          color: MilanotePalette.toHex(MilanotePalette.noteWhite),
          x: spawnX,
          y: spawnY,
          width: 250,
          height: 230,
        );
        break;

      case MilanoteToolType.drawing:
        await pv.addElement(
          boardId: _currentBoardId,
          type: 'drawing',
          title: 'Boceto Rápido',
          color: MilanotePalette.toHex(MilanotePalette.notePurple),
          x: spawnX,
          y: spawnY,
          width: 240,
          height: 200,
        );
        break;
    }
  }

  void _onCardTap(BoardElement el) {
    if (_connectingSource != null) {
      if (_connectingSource!.id != el.id) {
        context.read<BoardDataProvider>().addConnection(
          boardId: _currentBoardId,
          fromElementId: _connectingSource!.id!,
          toElementId: el.id!,
        );
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _connectingSource = null;
      });
      return;
    }

    setState(() {
      _selectedElementId = el.id;
    });
  }

  void _enterSubBoard(int subBoardId, String title) {
    setState(() {
      _currentBoardId = subBoardId;
      _boardStack.add({'id': subBoardId, 'title': title.isEmpty ? 'Sub-Tablero' : title});
      _selectedElementId = null;
      _connectingSource = null;
    });
    _centerView();
  }

  void _navigateToBreadcrumb(int index) {
    setState(() {
      _boardStack.removeRange(index + 1, _boardStack.length);
      _currentBoardId = _boardStack[index]['id'] as int;
      _selectedElementId = null;
      _connectingSource = null;
    });
    _centerView();
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<BoardDataProvider>();
    final elements = pv.getElementsByBoard(_currentBoardId);
    final cardElements = elements.where((e) => e.type != 'connection').toList();

    return Scaffold(
      backgroundColor: MilanotePalette.canvasDark,
      body: SafeArea(
        child: Stack(
          children: [
            // LIENZO FINITO
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedElementId = null;
                    _connectingSource = null;
                  });
                },
                child: InteractiveViewer(
                  transformationController: _transformController,
                  panEnabled: !_isDraggingElement,
                  scaleEnabled: !_isDraggingElement,
                  minScale: 0.25,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(60),
                  constrained: false,
                  child: Container(
                    width: _boardWidth,
                    height: _boardHeight,
                    decoration: BoxDecoration(
                      color: MilanotePalette.canvasDark,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Cuadrícula punteada Milanote finita optimizada con RepaintBoundary
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: MilanoteGridPainter(
                                width: _boardWidth,
                                height: _boardHeight,
                                gridSpacing: _gridSpacing,
                              ),
                            ),
                          ),
                        ),

                        // Líneas y flechas conectoras que escuchan el elemento en arrastre en tiempo real
                        Positioned.fill(
                          child: ValueListenableBuilder<BoardElement?>(
                            valueListenable: _activeDragNotifier,
                            builder: (context, activeEl, _) {
                              return CustomPaint(
                                painter: ConnectorLinePainter(
                                  elements: elements,
                                  activeDraggedElement: activeEl,
                                ),
                              );
                            },
                          ),
                        ),

                        // Elementos / Tarjetas
                        ...cardElements.map((el) {
                          return MilanoteElementCard(
                            key: ValueKey(el.id),
                            element: el,
                            canvasScale: _transformController.value.getMaxScaleOnAxis(),
                            isSelected: _selectedElementId == el.id,
                            isConnectingSource: _connectingSource?.id == el.id,
                            onTap: () => _onCardTap(el),
                            onDragStart: () {
                              if (!_isDraggingElement) {
                                setState(() => _isDraggingElement = true);
                              }
                            },
                            onDragUpdate: (worldDx, worldDy, totalDx, totalDy) {
                              _activeDragNotifier.value = el.copyWith(
                                x: el.x + totalDx,
                                y: el.y + totalDy,
                              );
                            },
                            onDragEnd: (totalDx, totalDy) {
                              _activeDragNotifier.value = null;
                              setState(() => _isDraggingElement = false);
                              if (el.id != null) {
                                final finalX = _snap((el.x + totalDx).clamp(20.0, _boardWidth - el.width - 20.0));
                                final finalY = _snap((el.y + totalDy).clamp(20.0, _boardHeight - el.height - 20.0));
                                pv.updatePositionLocal(el.id!, finalX, finalY);
                              }
                            },
                            onDelete: () {
                              if (el.id != null) pv.deleteElement(el.id!);
                            },
                            onDuplicate: () {
                              if (el.id != null) pv.duplicateElement(el.id!);
                            },
                            onStartConnect: () {
                              setState(() {
                                _connectingSource = el;
                              });
                            },
                            onUpdate: (updated) {
                              pv.updateElement(updated);
                            },
                            onOpenSubBoard: _enterSubBoard,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // BARRA SUPERIOR: BREADCRUMBS & NAVEGACIÓN
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  // Botón Volver a la App Principal
                  _circleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),

                  // Breadcrumbs de tableros anidados
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: MilanotePalette.dockBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_boardStack.length, (idx) {
                            final item = _boardStack[idx];
                            final isLast = idx == _boardStack.length - 1;
                            return Row(
                              children: [
                                InkWell(
                                  onTap: () => _navigateToBreadcrumb(idx),
                                  child: Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      color: isLast ? const Color(0xFF00E5FF) : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.chevron_right, size: 16, color: Colors.white38),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Toggle Snap a Grilla
                  _circleButton(
                    icon: _snapToGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                    color: _snapToGrid ? const Color(0xFF39FF14) : Colors.white60,
                    tooltip: _snapToGrid ? 'Ajuste a Grilla Activo' : 'Ajuste a Grilla Libre',
                    onTap: () {
                      setState(() => _snapToGrid = !_snapToGrid);
                    },
                  ),
                ],
              ),
            ),

            // CONTROLES DE ZOOM LATERALES (HUD)
            Positioned(
              right: 14,
              bottom: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: MilanotePalette.dockBackground,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white70, size: 20),
                      tooltip: 'Acercar Zoom',
                      onPressed: _zoomIn,
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_center_focus_rounded, color: Colors.white70, size: 18),
                      tooltip: 'Centrar Vista',
                      onPressed: _resetZoom,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: Colors.white70, size: 20),
                      tooltip: 'Alejar Zoom',
                      onPressed: _zoomOut,
                    ),
                  ],
                ),
              ),
            ),

            // DOCK INFERIOR MILANOTE
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Center(
                child: MilanoteDock(
                  onToolSelected: _handleToolSelected,
                  isConnectingMode: _connectingSource != null,
                  onCancelConnect: () {
                    setState(() => _connectingSource = null);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: MilanotePalette.dockBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
