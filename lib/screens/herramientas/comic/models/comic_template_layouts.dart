import 'dart:ui';
import 'comic_panel.dart';
import 'comic_template.dart';

/// Generador geométrico de paneles para las 12 plantillas útiles y clásicas de cómic.
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
          panels.add(ComicPanel(
            id: 'p_${timestamp}_$i',
            normalizedRect: Rect.fromLTWH(0.04, 0.04 + i * (h + gutter), 0.92, h),
          ));
        }
        break;

      case ComicTemplateType.fourKoma:
        final h = (0.92 - (gutter * 3)) / 4;
        for (int i = 0; i < 4; i++) {
          panels.add(ComicPanel(
            id: 'p_${timestamp}_$i',
            normalizedRect: Rect.fromLTWH(0.04, 0.04 + i * (h + gutter), 0.92, h),
          ));
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

      case ComicTemplateType.nineGrid:
        final w = (0.92 - (gutter * 2)) / 3;
        final h = (0.92 - (gutter * 2)) / 3;
        int count9 = 0;
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            panels.add(ComicPanel(
              id: 'p_${timestamp}_${count9++}',
              normalizedRect: Rect.fromLTWH(0.04 + col * (w + gutter), 0.04 + row * (h + gutter), w, h),
            ));
          }
        }
        break;

      case ComicTemplateType.comicHeroSplit:
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

      case ComicTemplateType.shonenSlash:
        panels.add(ComicPanel(
          id: 'p_${timestamp}_top',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.34),
        ));
        final halfW = (0.92 - gutter) / 2;
        panels.add(ComicPanel(
          id: 'p_${timestamp}_slash_left',
          normalizedRect: Rect.fromLTWH(0.04, 0.04 + 0.34 + gutter, halfW, 0.56),
          panelShape: ComicPanelShape.slantedRight,
          skewX: -0.12,
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_slash_right',
          normalizedRect: Rect.fromLTWH(0.04 + halfW + gutter, 0.04 + 0.34 + gutter, halfW, 0.56),
          panelShape: ComicPanelShape.slantedLeft,
          skewX: 0.12,
        ));
        break;

      case ComicTemplateType.actionManga5:
        final halfW = (0.92 - gutter) / 2;
        final topH = 0.26;
        final midH = 0.34;
        final botH = 0.92 - topH - midH - (gutter * 2);

        panels.add(ComicPanel(id: 'p_${timestamp}_t1', normalizedRect: Rect.fromLTWH(0.04, 0.04, halfW, topH)));
        panels.add(ComicPanel(id: 'p_${timestamp}_t2', normalizedRect: Rect.fromLTWH(0.04 + halfW + gutter, 0.04, halfW, topH)));

        panels.add(ComicPanel(id: 'p_${timestamp}_mid', normalizedRect: Rect.fromLTWH(0.04, 0.04 + topH + gutter, 0.92, midH)));

        final botY = 0.04 + topH + gutter + midH + gutter;
        panels.add(ComicPanel(id: 'p_${timestamp}_b1', normalizedRect: Rect.fromLTWH(0.04, botY, halfW, botH)));
        panels.add(ComicPanel(id: 'p_${timestamp}_b2', normalizedRect: Rect.fromLTWH(0.04 + halfW + gutter, botY, halfW, botH)));
        break;

      case ComicTemplateType.mangaClimax:
        panels.add(ComicPanel(
          id: 'p_${timestamp}_tension',
          normalizedRect: const Rect.fromLTWH(0.04, 0.04, 0.92, 0.24),
        ));
        panels.add(ComicPanel(
          id: 'p_${timestamp}_splash',
          normalizedRect: Rect.fromLTWH(0.04, 0.04 + 0.24 + gutter, 0.92, 0.92 - 0.24 - gutter),
        ));
        break;

      case ComicTemplateType.dailyStrip:
        final stripH = 0.32;
        final startY = (1.0 - stripH) / 2;
        final w3 = (0.92 - (gutter * 2)) / 3;
        for (int i = 0; i < 3; i++) {
          panels.add(ComicPanel(
            id: 'p_${timestamp}_daily_$i',
            normalizedRect: Rect.fromLTWH(0.04 + i * (w3 + gutter), startY, w3, stripH),
          ));
        }
        break;

      case ComicTemplateType.webtoonScroll:
        final h = (0.92 - (gutter * 3)) / 3;
        for (int i = 0; i < 3; i++) {
          panels.add(ComicPanel(
            id: 'p_${timestamp}_web_$i',
            normalizedRect: Rect.fromLTWH(0.06, 0.04 + i * (h + gutter * 1.5), 0.88, h),
            panelShape: ComicPanelShape.roundedRect,
            borderRadius: 14.0,
          ));
        }
        break;
    }

    return panels;
  }
}
