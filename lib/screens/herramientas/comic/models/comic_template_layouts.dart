import 'dart:ui';
import 'comic_panel.dart';
import 'comic_template.dart';

/// Generador geométrico de paneles para las 14 plantillas dinámicas y divertidas de cómic.
abstract final class ComicTemplateLayouts {
  static List<ComicPanel> generate(ComicTemplateType type, {double gutter = 0.02}) {
    final List<ComicPanel> panels = [];
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    switch (type) {
      case ComicTemplateType.singleFull:
        panels.add(ComicPanel(
          id: 'p_${timestamp}_1',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.92),
        ));
        break;

      case ComicTemplateType.twoHorizontal:
        final h = (0.92 - gutter) / 2;
        panels.add(ComicPanel(id: 'p_${timestamp}_1', normalizedRect: Rect.fromLTWH(0.04, 0.04, 0.92, h)));
        panels.add(ComicPanel(id: 'p_${timestamp}_2', normalizedRect: Rect.fromLTWH(0.04, 0.04 + h + gutter, 0.92, h)));
        break;

      case ComicTemplateType.threeTiers:
        final h = (0.92 - (gutter * 2)) / 3;
        for (int i = 0; i < 3; i++) {
          panels.add(ComicPanel(id: 'p_${timestamp}_$i', normalizedRect: Rect.fromLTWH(0.04, 0.04 + i * (h + gutter), 0.92, h)));
        }
        break;

      case ComicTemplateType.fourKoma:
        final h = (0.92 - (gutter * 3)) / 4;
        for (int i = 0; i < 4; i++) {
          panels.add(ComicPanel(id: 'p_${timestamp}_$i', normalizedRect: Rect.fromLTWH(0.04, 0.04 + i * (h + gutter), 0.92, h)));
        }
        break;

      case ComicTemplateType.sixGrid:
        final w = (0.92 - gutter) / 2;
        final h = (0.92 - (gutter * 2)) / 3;
        int count = 0;
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 2; col++) {
            panels.add(ComicPanel(
              id: 'p_${timestamp}_${count++}',
              normalizedRect: Rect.fromLTWH(0.04 + col * (w + gutter), 0.04 + row * (h + gutter), w, h),
            ));
          }
        }
        break;

      case ComicTemplateType.shonenSlash:
        // Viñeta superior de preparación, corte central diagonal shonen, y viñeta inferior de remate
        panels.add(ComicPanel(
          id: 'p_${timestamp}_1',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.24),
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_2',
          normalizedRect: const Rect.fromLTWH(0.04, 0.30, 0.92, 0.38),
          panelShape: ComicPanelShape.slantedRight,
          skewX: -0.15,
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_3',
          normalizedRect: const Rect.fromLTWH(0.04, 0.70, 0.92, 0.26),
        ));
        break;

      case ComicTemplateType.comicHeroSplit:
        // 1 gran viñeta vertical izquierda heroica + 3 cuadradas a la derecha
        final wLeft = 0.52;
        final wRight = 0.92 - wLeft - gutter;
        final hRight = (0.92 - (gutter * 2)) / 3;
        panels.add(ComicPanel(
          id: 'p_${timestamp}_hero',
          normalizedRect: Rect.fromLTWH(0.04, 0.04, wLeft, 0.92),
        ));
        for (int i = 0; i < 3; i++) {
          panels.add(ComicPanel(
            id: 'p_${timestamp}_sub_$i',
            normalizedRect: Rect.fromLTWH(0.04 + wLeft + gutter, 0.04 + i * (hRight + gutter), wRight, hRight),
          ));
        }
        break;

      case ComicTemplateType.webtoonScroll:
        // 3 viñetas verticales cinematográficas alternadas
        panels.add(ComicPanel(
          id: 'p_${timestamp}_w1',
          normalizedRect: const Rect.fromLTWH(0.06, 0.04, 0.88, 0.28),
          panelShape: ComicPanelShape.roundedRect,
          borderRadius: 14.0,
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_w2',
          normalizedRect: const Rect.fromLTWH(0.12, 0.35, 0.82, 0.28),
          panelShape: ComicPanelShape.roundedRect,
          borderRadius: 14.0,
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_w3',
          normalizedRect: const Rect.fromLTWH(0.06, 0.66, 0.88, 0.30),
          panelShape: ComicPanelShape.roundedRect,
          borderRadius: 14.0,
        ));
        break;

      case ComicTemplateType.funnyGagChaos:
        // Caos cómico: 2 paneles arriba, micro-panel central de reacción absurda, y gran panel de sorpresa abajo
        final halfW = (0.92 - gutter) / 2;
        panels.add(ComicPanel(id: 'p_${timestamp}_g1', normalizedRect: Rect.fromLTWH(0.04, 0.04, halfW, 0.26)));
        panels.add(ComicPanel(id: 'p_${timestamp}_g2', normalizedRect: Rect.fromLTWH(0.04 + halfW + gutter, 0.04, halfW, 0.26)));
        // Micro-panel sorpresa
        panels.add(ComicPanel(
          id: 'p_${timestamp}_shock',
          normalizedRect: const Rect.fromLTWH(0.32, 0.32, 0.36, 0.20),
          panelShape: ComicPanelShape.diamond,
          borderColor: const Color(0xFFFFDE59),
          borderWidth: 3.5,
        ));
        // Gran panel cómico
        panels.add(ComicPanel(
          id: 'p_${timestamp}_punchline',
          normalizedRect: const Rect.fromLTWH(0.04, 0.54, 0.92, 0.42),
          panelShape: ComicPanelShape.trapezoidBottom,
        ));
        break;

      case ComicTemplateType.overlappingImpact:
        // Gran splash de fondo con viñeta flotante de primer plano superpuesta
        panels.add(ComicPanel(
          id: 'p_${timestamp}_background_splash',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.92),
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_floating_focus',
          normalizedRect: const Rect.fromLTWH(0.48, 0.44, 0.44, 0.46),
          borderWidth: 4.5,
          borderColor: const Color(0xFF00D4FF),
          panelShape: ComicPanelShape.slantedLeft,
        ));
        break;

      case ComicTemplateType.cinematicWidescreen:
        // 3 viñetas estilo cine panorámico anamórfico
        final h = (0.92 - (gutter * 2)) / 3;
        for (int i = 0; i < 3; i++) {
          panels.add(ComicPanel(
            id: 'p_${timestamp}_cine_$i',
            normalizedRect: Rect.fromLTWH(0.04, 0.04 + i * (h + gutter), 0.92, h),
            backgroundColor: const Color(0xFF141414),
            borderColor: const Color(0xFFFFFFFF),
            borderWidth: 2.0,
          ));
        }
        break;

      case ComicTemplateType.shoujoDream:
        // Shojo Romántico: viñeta alta vertical estilizada con 2 paneles suaves superpuestos
        panels.add(ComicPanel(
          id: 'p_${timestamp}_dream_main',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.56, 0.92),
          panelShape: ComicPanelShape.roundedRect,
          borderRadius: 20.0,
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_dream_top',
          normalizedRect: const Rect.fromLTWH(0.62, 0.08, 0.34, 0.38),
          panelShape: ComicPanelShape.roundedRect,
          borderRadius: 16.0,
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_dream_bottom',
          normalizedRect: const Rect.fromLTWH(0.62, 0.50, 0.34, 0.42),
          panelShape: ComicPanelShape.roundedRect,
          borderRadius: 16.0,
        ));
        break;

      case ComicTemplateType.actionClimax5:
        // Panel de tensión superior, 3 viñetas diagonales de choque en el medio, y resolución inferior
        panels.add(ComicPanel(
          id: 'p_${timestamp}_prep',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.22),
        ));
        final midW = (0.92 - (gutter * 2)) / 3;
        for (int i = 0; i < 3; i++) {
          panels.add(ComicPanel(
            id: 'p_${timestamp}_rush_$i',
            normalizedRect: Rect.fromLTWH(0.04 + i * (midW + gutter), 0.28, midW, 0.38),
            panelShape: i == 1 ? ComicPanelShape.parallelogram : ComicPanelShape.slantedRight,
          ));
        }
        panels.add(ComicPanel(
          id: 'p_${timestamp}_strike',
          normalizedRect: const Rect.fromLTWH(0.04, 0.68, 0.92, 0.28),
        ));
        break;

      case ComicTemplateType.crossroadsMosaic:
        // Mosaico cruzado asimétrico (5 viñetas)
        panels.add(ComicPanel(id: 'p_${timestamp}_m1', normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.44, 0.40)));
        panels.add(ComicPanel(id: 'p_${timestamp}_m2', normalizedRect: const Rect.fromLTWH(0.50, 0.04, 0.46, 0.26)));
        panels.add(ComicPanel(id: 'p_${timestamp}_m3', normalizedRect: const Rect.fromLTWH(0.50, 0.32, 0.46, 0.36)));
        panels.add(ComicPanel(id: 'p_${timestamp}_m4', normalizedRect: const Rect.fromLTWH(0.04, 0.46, 0.44, 0.50)));
        panels.add(ComicPanel(id: 'p_${timestamp}_m5', normalizedRect: const Rect.fromLTWH(0.50, 0.70, 0.46, 0.26)));
        break;
    }

    return panels;
  }
}
