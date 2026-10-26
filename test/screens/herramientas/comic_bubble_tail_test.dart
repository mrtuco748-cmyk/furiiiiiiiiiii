import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_bubble.dart';
import 'package:furi_app/screens/herramientas/comic/painters/comic_bubble_painter.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_transform_resolver.dart';

void main() {
  group('Comic Bubble Tail Geometry Tests', () {
    test('Top tail extends smoothly upward beyond y = 0 without inner kinks', () {
      final bubble = ComicBubble(
        id: 'bubble_top',
        text: 'Top Tail Test',
        width: 160.0,
        height: 90.0,
        tailDirection: ComicTailDirection.top,
      );

      final path = ComicBubblePainter.getBubblePath(const Size(160, 90), bubble);
      final bounds = path.getBounds();

      // Debe proyectarse hacia arriba (y negativo)
      expect(bounds.top, lessThan(-20.0));
      // No debe distorsionar el ancho base
      expect(bounds.left, greaterThanOrEqualTo(-5.0));
      expect(bounds.right, lessThanOrEqualTo(165.0));
      expect(bounds.bottom, greaterThanOrEqualTo(90.0));

      // El path debe estar cerrado y ser continuo
      final metrics = path.computeMetrics().toList();
      expect(metrics.isNotEmpty, isTrue);
      expect(metrics.first.isClosed, isTrue);
    });

    test('Left tail points horizontally to the left beyond x = 0 without bottom drooping', () {
      final bubble = ComicBubble(
        id: 'bubble_left',
        text: 'Left Tail Test',
        width: 160.0,
        height: 90.0,
        tailDirection: ComicTailDirection.left,
      );

      final path = ComicBubblePainter.getBubblePath(const Size(160, 90), bubble);
      final bounds = path.getBounds();

      // Debe proyectarse a la izquierda (x negativo)
      expect(bounds.left, lessThan(-20.0));
      // No debe salirse por arriba ni caer por debajo del suelo de forma rota
      expect(bounds.top, greaterThanOrEqualTo(-5.0));
      expect(bounds.bottom, lessThanOrEqualTo(100.0));

      final metrics = path.computeMetrics().toList();
      expect(metrics.isNotEmpty, isTrue);
      expect(metrics.first.isClosed, isTrue);
    });

    test('Right and Bottom tails project cleanly in their designated directions', () {
      final rightBubble = ComicBubble(
        id: 'bubble_right',
        text: 'Right Tail',
        width: 160.0,
        height: 90.0,
        tailDirection: ComicTailDirection.right,
      );
      final rightPath = ComicBubblePainter.getBubblePath(const Size(160, 90), rightBubble);
      final rightBounds = rightPath.getBounds();
      expect(rightBounds.right, greaterThan(180.0));

      final bottomBubble = ComicBubble(
        id: 'bubble_bottom',
        text: 'Bottom Tail',
        width: 160.0,
        height: 90.0,
        tailDirection: ComicTailDirection.bottom,
      );
      final bottomPath = ComicBubblePainter.getBubblePath(const Size(160, 90), bottomBubble);
      final bottomBounds = bottomPath.getBounds();
      expect(bottomBounds.bottom, greaterThan(110.0));
    });

    test('Thought cloud dots render cleanly for top, left, right and bottom directions', () {
      for (final dir in ComicTailDirection.values) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final bubble = ComicBubble(
          id: 'thought_${dir.name}',
          text: 'Thinking...',
          type: ComicBubbleType.thoughtCloud,
          tailDirection: dir,
        );
        // No debe lanzar excepciones al pintar en ninguna dirección
        expect(
          () => ComicBubblePainter.paintBubble(canvas, const Size(160, 90), bubble),
          returnsNormally,
        );
      }
    });

    test('ComicTransformResolver detects taps near extended tail', () {
      final controller = ComicController(blankPage: true);
      controller.addBubble(
        text: 'Tap Near Tail',
        x: 0.5,
        y: 0.5,
      );
      final b = controller.activePage.bubbles.first.copyWith(
        tailDirection: ComicTailDirection.top,
      );
      controller.updateBubble(b);

      const pageSize = Size(400, 600);
      final bubbleCenter = Offset(b.x * pageSize.width, b.y * pageSize.height);
      // Toque justo encima del globo (en la zona de la cola superior)
      final topTailPos = Offset(bubbleCenter.dx, bubbleCenter.dy - b.height / 2 - 25);

      final hitBubble = ComicTransformResolver.findTappedBubble(controller, topTailPos, pageSize);
      expect(hitBubble, isNotNull);
      expect(hitBubble!.id, b.id);
    });
  });
}
