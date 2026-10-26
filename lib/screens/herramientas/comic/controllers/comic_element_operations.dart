import 'dart:ui';
import '../models/comic_bubble.dart';
import '../models/comic_page.dart';
import '../models/comic_panel.dart';
import '../models/comic_project.dart';
import '../models/comic_sticker.dart';
import '../models/comic_template.dart';

/// Operaciones puras para globos de diálogo, SFX y páginas del cómic.
abstract final class ComicElementOperations {
  // --- Páginas ---
  static ComicProject addPage(ComicProject project, {ComicTemplateType? template, bool blank = false}) {
    final nextNumber = project.pages.length + 1;
    final panels = blank ? <ComicPanel>[] : (template ?? ComicTemplateType.fourKoma).createPanels();
    final newPage = ComicPage(
      id: 'page_${DateTime.now().microsecondsSinceEpoch}',
      pageNumber: nextNumber,
      panels: panels,
      bubbles: [],
      sfxStickers: [],
    );
    final updatedPages = List<ComicPage>.from(project.pages)..add(newPage);
    return project.copyWith(pages: updatedPages, activePageIndex: updatedPages.length - 1);
  }

  static ComicProject? removePage(ComicProject project, int index) {
    if (project.pages.length <= 1) return null;
    final updatedPages = List<ComicPage>.from(project.pages)..removeAt(index);
    final nextIndex = index >= updatedPages.length ? updatedPages.length - 1 : index;
    return project.copyWith(pages: updatedPages, activePageIndex: nextIndex);
  }

  // --- Globos ---
  static (ComicPage, ComicBubble) addBubble(
    ComicPage page, {
    ComicBubbleType type = ComicBubbleType.mangaOval,
    String text = '¡Hola!',
    double x = 0.5,
    double y = 0.4,
    ComicBubble? bubble,
  }) {
    final b = bubble ?? ComicBubble(
      id: 'bubble_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      text: text,
      x: x,
      y: y,
    );
    final updated = List<ComicBubble>.from(page.bubbles)..add(b);
    return (page.copyWith(bubbles: updated), b);
  }

  static ComicPage updateBubble(ComicPage page, ComicBubble bubble) {
    final updated = page.bubbles.map((b) => b.id == bubble.id ? bubble : b).toList();
    return page.copyWith(bubbles: updated);
  }

  static ComicPage moveBubble(ComicPage page, String id, double x, double y) {
    final updated = page.bubbles.map((b) {
      if (b.id != id) return b;
      return b.copyWith(x: x.clamp(0.05, 0.95), y: y.clamp(0.05, 0.95));
    }).toList();
    return page.copyWith(bubbles: updated);
  }

  static ComicPage deleteBubble(ComicPage page, String id) {
    final updated = List<ComicBubble>.from(page.bubbles)..removeWhere((b) => b.id == id);
    return page.copyWith(bubbles: updated);
  }

  // --- Onomatopeyas SFX ---
  static (ComicPage, ComicSticker) addSfx(
    ComicPage page,
    String text, {
    double x = 0.5,
    double y = 0.5,
    Color? color,
    Color? outlineColor,
    String? font,
  }) {
    final sfx = ComicSticker(
      id: 'sfx_${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      x: x,
      y: y,
      color: color ?? const Color(0xFFFFDE59),
      outlineColor: outlineColor ?? const Color(0xFF111111),
      fontFamily: font ?? 'Bangers',
    );
    final updated = List<ComicSticker>.from(page.sfxStickers)..add(sfx);
    return (page.copyWith(sfxStickers: updated), sfx);
  }

  static ComicPage updateSfx(ComicPage page, ComicSticker sfx) {
    final updated = page.sfxStickers.map((s) => s.id == sfx.id ? sfx : s).toList();
    return page.copyWith(sfxStickers: updated);
  }

  static ComicPage moveSfx(ComicPage page, String id, double x, double y) {
    final updated = page.sfxStickers.map((s) {
      if (s.id != id) return s;
      return s.copyWith(x: x.clamp(0.05, 0.95), y: y.clamp(0.05, 0.95));
    }).toList();
    return page.copyWith(sfxStickers: updated);
  }

  static ComicPage deleteSfx(ComicPage page, String id) {
    final updated = List<ComicSticker>.from(page.sfxStickers)..removeWhere((s) => s.id == id);
    return page.copyWith(sfxStickers: updated);
  }
}
