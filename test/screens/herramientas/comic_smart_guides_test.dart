import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/helpers/comic_smart_guides_engine.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_alignment_guide.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_editor_gesture_helper.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_selection_handles.dart';

void main() {
  group('Comic Smart Alignment Guides Tests (Canva / Figma style)', () {
    const pageSize = Size(400, 600);

    test('Snaps to page horizontal and vertical centers when near center', () {
      final controller = ComicController(blankPage: true);

      // Elemento con centro casi en el centro de la página (200, 300)
      // Centro candidato: (202.5, 298.0) -> a menos de 6px de (200, 300)
      final candidateRect = Rect.fromCenter(
        center: const Offset(202.5, 298.0),
        width: 100,
        height: 60,
      );

      final snap = ComicSmartGuidesEngine.snap(
        pageSize: pageSize,
        candidateRect: candidateRect,
        controller: controller,
      );

      // Debe haber atraído exactamente a los centros de la hoja (200.0, 300.0)
      expect(snap.snappedCenter.dx, closeTo(200.0, 0.001));
      expect(snap.snappedCenter.dy, closeTo(300.0, 0.001));

      // Debe haber generado las guías de centro de página
      expect(snap.guides.length, 2);
      final xGuide = snap.guides.firstWhere((g) => g.isVertical);
      final yGuide = snap.guides.firstWhere((g) => g.isHorizontal);

      expect(xGuide.position, closeTo(200.0, 0.001));
      expect(xGuide.isPageCenter, isTrue);
      expect(xGuide.label, 'Centro');

      expect(yGuide.position, closeTo(300.0, 0.001));
      expect(yGuide.isPageCenter, isTrue);
      expect(yGuide.label, 'Centro');
    });

    test('Snaps to edges and centers of other panels and bubbles', () {
      final controller = ComicController(blankPage: true);

      // Agregar un panel de referencia en la mitad izquierda
      controller.addPanel(
        normalizedRect: const Rect.fromLTWH(0.10, 0.10, 0.35, 0.35),
      );
      expect(controller.activePage.panels, isNotEmpty);

      // El panel está de X: 40 a 180 (ancho 140, centro 110)
      // Si colocamos un globo cerca del centro X del panel (ej. 112.0)
      final bubbleRect = Rect.fromCenter(
        center: const Offset(112.0, 450.0),
        width: 100,
        height: 60,
      );

      final snap = ComicSmartGuidesEngine.snap(
        pageSize: pageSize,
        candidateRect: bubbleRect,
        controller: controller,
      );

      // Debe alinear con el centro de la viñeta (110.0)
      expect(snap.snappedCenter.dx, closeTo(110.0, 0.001));
      final elementGuide = snap.guides.firstWhere((g) => g.isVertical);
      expect(elementGuide.type, ComicGuideType.elementCenter);
      expect(elementGuide.position, closeTo(110.0, 0.001));
    });

    test('Snaps to margins when near page boundaries', () {
      final controller = ComicController(blankPage: true);

      // Margen izquierdo = 400 * 0.05 = 20.0
      // Candidato con borde izquierdo en 22.0
      final candidateRect = Rect.fromLTWH(22.0, 100.0, 120.0, 80.0);

      final snap = ComicSmartGuidesEngine.snap(
        pageSize: pageSize,
        candidateRect: candidateRect,
        controller: controller,
      );

      // El borde izquierdo debe alinearse con el margen de 20.0
      final snappedRect = Rect.fromCenter(
        center: snap.snappedCenter,
        width: 120.0,
        height: 80.0,
      );
      expect(snappedRect.left, closeTo(20.0, 0.001));
      expect(snap.guides.any((g) => g.type == ComicGuideType.pageMargin), isTrue);
    });

    test('ComicEditorGestureHelper.applyMoveWithSnap moves and activates guides', () {
      final controller = ComicController(blankPage: true);
      controller.addBubble(
        text: 'Snap Bubble',
        x: 0.48, // 192 px en 400 px
        y: 0.48, // 288 px en 600 px
      );
      expect(controller.selectedBubble, isNotNull);

      // Mover 7 px hacia la derecha para acercarse al centro (192 + 7 = 199 px, a 1px de 200)
      final guides = ComicEditorGestureHelper.applyMoveWithSnap(
        controller: controller,
        details: DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(7.0, 11.0), // 288 + 11 = 299 px, a 1px de 300
        ),
        pageSize: pageSize,
      );

      // Debe haber hecho snap exacto al centro de página (0.50, 0.50)
      expect(controller.selectedBubble!.x, closeTo(0.50, 0.005));
      expect(controller.selectedBubble!.y, closeTo(0.50, 0.005));
      expect(guides.length, 2);
      expect(guides.every((g) => g.isPageCenter), isTrue);
    });

    test('ComicSelectionBoxPainter paints smart guides and pills without throwing', () {
      const transform = ComicElementTransform(
        center: Offset(200, 300),
        halfW: 60,
        halfH: 40,
        rotation: 0.0,
      );

      const guides = [
        ComicAlignmentGuide(
          position: 200.0,
          orientation: ComicGuideOrientation.vertical,
          type: ComicGuideType.pageCenter,
          label: 'Centro',
        ),
        ComicAlignmentGuide(
          position: 300.0,
          orientation: ComicGuideOrientation.horizontal,
          type: ComicGuideType.pageCenter,
          label: 'Centro',
        ),
        ComicAlignmentGuide(
          position: 80.0,
          orientation: ComicGuideOrientation.vertical,
          type: ComicGuideType.elementEdge,
        ),
      ];

      final painter = ComicSelectionBoxPainter(
        transform: transform,
        guides: guides,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, pageSize), returnsNormally);
    });
  });
}
