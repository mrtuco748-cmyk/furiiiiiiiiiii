import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_alignment_guide.dart';

/// Resultado del cálculo magnético de alineación inteligente estilo Canva/Figma.
class ComicSnapResult {
  final Offset snappedCenter;
  final List<ComicAlignmentGuide> guides;

  const ComicSnapResult({
    required this.snappedCenter,
    required this.guides,
  });
}

class _GuideTarget {
  final double pos;
  final ComicGuideType type;
  final String? label;

  const _GuideTarget(this.pos, this.type, [this.label]);
}

/// Motor de guías magnéticas inteligentes para alinear elementos entre sí y con los centros del lienzo.
abstract final class ComicSmartGuidesEngine {
  static ComicSnapResult snap({
    required Size pageSize,
    required Rect candidateRect,
    required ComicController controller,
    String? currentElementId,
    double snapThreshold = 2.5,
  }) {
    final xTargets = <_GuideTarget>[
      _GuideTarget(pageSize.width * 0.5, ComicGuideType.pageCenter, 'Centro'),
      _GuideTarget(pageSize.width * 0.05, ComicGuideType.pageMargin, 'Margen'),
      _GuideTarget(pageSize.width * 0.95, ComicGuideType.pageMargin, 'Margen'),
    ];

    final yTargets = <_GuideTarget>[
      _GuideTarget(pageSize.height * 0.5, ComicGuideType.pageCenter, 'Centro'),
      _GuideTarget(pageSize.height * 0.05, ComicGuideType.pageMargin, 'Margen'),
      _GuideTarget(pageSize.height * 0.95, ComicGuideType.pageMargin, 'Margen'),
    ];

    // Objetivos de otras viñetas
    for (final p in controller.activePage.panels) {
      if (p.id == currentElementId) continue;
      final pr = Rect.fromLTWH(
        p.normalizedRect.left * pageSize.width,
        p.normalizedRect.top * pageSize.height,
        p.normalizedRect.width * pageSize.width,
        p.normalizedRect.height * pageSize.height,
      );
      xTargets.add(_GuideTarget(pr.center.dx, ComicGuideType.elementCenter));
      xTargets.add(_GuideTarget(pr.left, ComicGuideType.elementEdge));
      xTargets.add(_GuideTarget(pr.right, ComicGuideType.elementEdge));

      yTargets.add(_GuideTarget(pr.center.dy, ComicGuideType.elementCenter));
      yTargets.add(_GuideTarget(pr.top, ComicGuideType.elementEdge));
      yTargets.add(_GuideTarget(pr.bottom, ComicGuideType.elementEdge));
    }

    // Objetivos de otros globos de diálogo
    for (final b in controller.activePage.bubbles) {
      if (b.id == currentElementId) continue;
      final br = Rect.fromCenter(
        center: Offset(b.x * pageSize.width, b.y * pageSize.height),
        width: b.width,
        height: b.height,
      );
      xTargets.add(_GuideTarget(br.center.dx, ComicGuideType.elementCenter));
      xTargets.add(_GuideTarget(br.left, ComicGuideType.elementEdge));
      xTargets.add(_GuideTarget(br.right, ComicGuideType.elementEdge));

      yTargets.add(_GuideTarget(br.center.dy, ComicGuideType.elementCenter));
      yTargets.add(_GuideTarget(br.top, ComicGuideType.elementEdge));
      yTargets.add(_GuideTarget(br.bottom, ComicGuideType.elementEdge));
    }

    // Evaluar snap en Eje X
    double bestDeltaX = 0.0;
    double minDiffX = snapThreshold + 1.0;
    ComicAlignmentGuide? bestGuideX;

    final candCenter = candidateRect.center;
    final candXPoints = [
      (candCenter.dx, true),
      (candidateRect.left, false),
      (candidateRect.right, false),
    ];

    for (final target in xTargets) {
      for (final (candX, isCenter) in candXPoints) {
        final diff = target.pos - candX;
        final absDiff = diff.abs();
        final priorityBonus = isCenter ? -0.5 : 0.0;
        if (absDiff <= snapThreshold && (absDiff + priorityBonus) < minDiffX) {
          minDiffX = absDiff + priorityBonus;
          bestDeltaX = diff;
          bestGuideX = ComicAlignmentGuide(
            position: target.pos,
            orientation: ComicGuideOrientation.vertical,
            type: target.type,
            label: target.label,
          );
        }
      }
    }

    // Evaluar snap en Eje Y
    double bestDeltaY = 0.0;
    double minDiffY = snapThreshold + 1.0;
    ComicAlignmentGuide? bestGuideY;

    final candYPoints = [
      (candCenter.dy, true),
      (candidateRect.top, false),
      (candidateRect.bottom, false),
    ];

    for (final target in yTargets) {
      for (final (candY, isCenter) in candYPoints) {
        final diff = target.pos - candY;
        final absDiff = diff.abs();
        final priorityBonus = isCenter ? -0.5 : 0.0;
        if (absDiff <= snapThreshold && (absDiff + priorityBonus) < minDiffY) {
          minDiffY = absDiff + priorityBonus;
          bestDeltaY = diff;
          bestGuideY = ComicAlignmentGuide(
            position: target.pos,
            orientation: ComicGuideOrientation.horizontal,
            type: target.type,
            label: target.label,
          );
        }
      }
    }

    final guides = <ComicAlignmentGuide>[
      ?bestGuideX,
      ?bestGuideY,
    ];

    // Fuerza magnética suave con amortiguamiento del 40% para preservar máxima fluidez táctil
    final snappedCenter = candCenter + Offset(bestDeltaX * 0.40, bestDeltaY * 0.40);
    return ComicSnapResult(snappedCenter: snappedCenter, guides: guides);
  }
}
