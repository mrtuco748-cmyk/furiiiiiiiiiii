import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';
import '../../../app_state.dart';
import '../renderers/board_element_renderer.dart';
import '../renderers/board_connector_renderer.dart';

const _dotColor = Color(0xFF333333);

class BoardCanvas extends StatefulWidget {
  final TransformationController transformController;
  final ValueNotifier<Rect> visibleRect;
  final BoardProviderV2 provider;
  final int? selectedId;
  final Function(int?) onSelectElement;
  final VoidCallback onDoubleTapEmpty;
  final bool connectorMode;
  final int? connectorFromId;

  const BoardCanvas({
    super.key,
    required this.transformController,
    required this.visibleRect,
    required this.provider,
    required this.selectedId,
    required this.onSelectElement,
    required this.onDoubleTapEmpty,
    this.connectorMode = false,
    this.connectorFromId,
  });

  @override
  State<BoardCanvas> createState() => _BoardCanvasState();
}

class _BoardCanvasState extends State<BoardCanvas> {
  final Map<int, bool> _editingElements = {};

  @override
  Widget build(BuildContext context) {
    if (widget.provider.loading) {
      return _buildSkeleton();
    }

    if (widget.provider.hasError && widget.provider.elements.isEmpty) {
      return _buildError();
    }

    return Stack(
      children: [
        // Grid always visible in background
        ValueListenableBuilder<Rect>(
          valueListenable: widget.visibleRect,
          builder: (context, rect, _) => CustomPaint(
            painter: _GridPainter(transform: widget.transformController.value),
            size: MediaQuery.of(context).size,
          ),
        ),
        // InteractiveViewer with elements
        InteractiveViewer(
          transformationController: widget.transformController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          minScale: 0.1,
          maxScale: 5.0,
          panEnabled: widget.selectedId == null && !widget.connectorMode,
          child: GestureDetector(
            onTap: () => widget.onSelectElement(null),
            onDoubleTap: widget.onDoubleTapEmpty,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: 50000,
              height: 50000,
              child: ValueListenableBuilder<Rect>(
                valueListenable: widget.visibleRect,
                builder: (context, rect, _) {
                  final viewport = rect.inflate(500);
                  final elements = widget.provider.elements;
                  final connectors = elements
                      .where((e) => e.type == BoardElementType.connector)
                      .toList();
                  final items = elements
                      .where((e) => e.type != BoardElementType.connector)
                      .where((e) {
                    final w = e.width ?? 180;
                    final h = e.height ?? 110;
                    return e.x < viewport.right &&
                        e.x + w > viewport.left &&
                        e.y < viewport.bottom &&
                        e.y + h > viewport.top;
                  }).toList()
                    ..sort((a, b) => a.z.compareTo(b.z));

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Connector layer (behind elements)
                      if (connectors.isNotEmpty)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MultiConnectorPainter(
                              connectors: connectors,
                              allElements: elements,
                            ),
                          ),
                        ),
                      // Element layer
                      for (final el in items)
                        _buildElement(el, viewport),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildElement(BoardElementV2 el, Rect viewport) {
    final id = el.id ?? (el.createdAt.millisecondsSinceEpoch % 1000000);
    final isSelected = widget.selectedId == id;
    final isConnectorOrigin = widget.connectorFromId == id;
    final isEditing = _editingElements[id] == true;

    return Positioned(
      left: el.x,
      top: el.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Captura gestos en toda el área del elemento
        onTap: () {
          HapticFeedback.selectionClick();
          // Video con selección activa: segundo tap abre el video
          if (isSelected && el.type == BoardElementType.video) {
            _openVideo(el);
            return;
          }
          widget.onSelectElement(id);
        },
        onDoubleTap: () {
          // Absorbe el doble tap en el elemento: para notas alterna
          // edición; para el resto solo selecciona, así el doble tap no
          // cae al fondo (que crearía notas espurias).
          if (el.type == BoardElementType.note) {
            setState(() => _editingElements[id] = !(_editingElements[id] ?? false));
          } else {
            widget.onSelectElement(id);
          }
        },
        onPanUpdate: el.isLocked
            ? null
            : (d) {
                // Get live element from provider to avoid stale state
                final liveEl = _liveElement(el);
                widget.provider.moveLocal(
                  liveEl,
                  liveEl.x + d.delta.dx,
                  liveEl.y + d.delta.dy,
                );
              },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Element renderer
            BoardElementRenderer(
              element: el,
              isEditing: isEditing,
              onRequestEdit: () => setState(() => _editingElements[id] = true),
              onDataChanged: (data) {
                final liveEl = _liveElement(el);
                if (data.containsKey('_content')) {
                  final updated = liveEl.copyWith(content: data['_content'] as String);
                  widget.provider.update(updated);
                } else {
                  final updated = liveEl.copyWith(data: {...liveEl.data, ...data});
                  widget.provider.update(updated);
                }
              },
            ),
            // Selection border
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _userColor(),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            // Connector origin highlight
            if (isConnectorOrigin)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 3,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            // Author badge
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _authorColor(el),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0A0A0A),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    el.authorInitial,
                    style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            // Inline reactions
            if (_reactionsOf(el).isNotEmpty)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
                  ),
                  child: Text(
                    _reactionsOf(el),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            // NEW badge
            if (el.isNew)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NUEVO',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            // Locked icon
            if (el.isLocked)
              Positioned(
                right: 4,
                top: 4,
                child: const Icon(
                  Icons.lock,
                  color: Colors.white54,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _userColor() {
    final identity = (AppState.identity ?? '').toLowerCase();
    if (identity.contains('facu')) return const Color(0xFF4FC3F7);
    if (identity.contains('rocio')) return const Color(0xFFCE93D8);
    return const Color(0xFF4FC3F7);
  }

  /// Busca la copia viva del elemento en el provider.
  /// Prioridad: id → createdAt. Fallback: el propio elemento (los gestos
  /// siguen funcionando aunque el drag no persista).
  BoardElementV2 _liveElement(BoardElementV2 el) {
    final searchId = el.id ?? (el.createdAt.millisecondsSinceEpoch % 1000000);
    for (final e in widget.provider.elements) {
      final eId = e.id ?? (e.createdAt.millisecondsSinceEpoch % 1000000);
      if (eId == searchId) return e;
    }
    return el;
  }

  Future<void> _openVideo(BoardElementV2 el) async {
    final data = VideoData.fromMap(el.data);
    if (data.url.isEmpty) return;
    final uri = Uri.tryParse(data.url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el video', style: TextStyle(fontFamily: 'monospace')),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    }
  }

  Color _authorColor(BoardElementV2 el) {
    final uid = (el.userId ?? '').toLowerCase();
    if (uid.contains('facu')) return const Color(0xFF4FC3F7);
    if (uid.contains('rocio')) return const Color(0xFFCE93D8);
    return const Color(0xFF4FC3F7);
  }

  String _reactionsOf(BoardElementV2 el) {
    final reactions = el.data['reactions'];
    if (reactions is! Map) return '';
    return reactions.keys.map((k) => k.toString()).join(' ');
  }

  Widget _buildSkeleton() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            6,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: 180 + (i % 3) * 40,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF5757), size: 40),
          const SizedBox(height: 12),
          Text(
            widget.provider.error ?? 'Error',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.provider.load(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Color(0xFF0A0A0A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Matrix4 transform;
  _GridPainter({Matrix4? transform})
      : transform = transform ?? Matrix4.identity();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _dotColor..strokeWidth = 1.5;
    const spacing = 30.0;
    final inv = Matrix4.inverted(transform);
    final tl = MatrixUtils.transformPoint(inv, Offset.zero);
    final br = MatrixUtils.transformPoint(
      inv,
      Offset(size.width, size.height),
    );
    final startX = (tl.dx / spacing).floor() * spacing;
    final startY = (tl.dy / spacing).floor() * spacing;
    final endX = (br.dx / spacing).ceil() * spacing;
    final endY = (br.dy / spacing).ceil() * spacing;
    for (double x = startX; x <= endX; x += spacing) {
      for (double y = startY; y <= endY; y += spacing) {
        final p = MatrixUtils.transformPoint(transform, Offset(x, y));
        canvas.drawCircle(p, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.transform != transform;
}
