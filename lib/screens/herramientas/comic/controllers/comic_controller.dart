import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../helpers/comic_image_cache.dart';
import '../helpers/comic_render_exporter.dart';
import '../models/comic_bubble.dart';
import '../models/comic_interaction_mode.dart';
import '../models/comic_page.dart';
import '../models/comic_panel.dart';
import '../models/comic_project.dart';
import '../models/comic_sticker.dart';
import '../models/comic_template.dart';
import 'comic_element_operations.dart';
import 'comic_history.dart';
import 'comic_panel_operations.dart';

/// Controlador reactivo del taller de cómics con historial undo/redo,
/// creación libre de viñetas con gestos, manipulación directa y modos de interacción.
class ComicController extends ChangeNotifier {
  ComicProject _project;
  String? _selectedPanelId;
  String? _selectedBubbleId;
  String? _selectedSfxId;
  ComicInteractionMode _interactionMode = ComicInteractionMode.normal;
  final Map<String, ui.Image> _panelImages = {};
  final ComicHistory _history = ComicHistory();

  ComicController({ComicProject? initialProject, bool blankPage = false})
      : _project = initialProject ??
            ComicProject(
              id: 'comic_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Mi Primer Cómic',
              pages: [
                ComicPage(
                  id: 'page_1',
                  pageNumber: 1,
                  panels: blankPage ? [] : ComicTemplateType.fourKoma.createPanels(),
                  bubbles: [],
                  sfxStickers: [],
                ),
              ],
            ) {
    ComicImageCache.decodeAll(activePage, _panelImages, notifyListeners);
  }

  ComicProject get project => _project;
  ComicPage get activePage => _project.activePage;
  int get activePageIndex => _project.activePageIndex;
  String? get selectedPanelId => _selectedPanelId;
  String? get selectedBubbleId => _selectedBubbleId;
  String? get selectedSfxId => _selectedSfxId;
  ComicInteractionMode get interactionMode => _interactionMode;
  Map<String, ui.Image> get panelImages => _panelImages;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  ComicPanel? get selectedPanel => activePage.panels.where((p) => p.id == _selectedPanelId).firstOrNull;
  ComicBubble? get selectedBubble => activePage.bubbles.where((b) => b.id == _selectedBubbleId).firstOrNull;
  ComicSticker? get selectedSfx => activePage.sfxStickers.where((s) => s.id == _selectedSfxId).firstOrNull;

  void recordHistory() => _history.recordSnapshot(activePage);

  void setInteractionMode(ComicInteractionMode mode) { _interactionMode = mode; notifyListeners(); }

  void undo() {
    final prev = _history.undo(activePage);
    if (prev != null) _applyPageSnapshot(prev);
  }

  void redo() {
    final next = _history.redo(activePage);
    if (next != null) _applyPageSnapshot(next);
  }

  void _applyPageSnapshot(ComicPage page) {
    final pages = List<ComicPage>.from(_project.pages)..[_project.activePageIndex] = page;
    _project = _project.copyWith(pages: pages, updatedAt: DateTime.now());
    deselectAll();
    ComicImageCache.decodeAll(activePage, _panelImages, notifyListeners);
    notifyListeners();
  }

  void setTitle(String title) {
    _project = _project.copyWith(title: title);
    notifyListeners();
  }

  void setCoverImage(String base64) => _project = _project.copyWith(coverImageBase64: base64);

  void loadProject(ComicProject project) {
    _project = project;
    _history.clear();
    deselectAll();
    _panelImages.clear();
    ComicImageCache.decodeAll(activePage, _panelImages, notifyListeners);
    notifyListeners();
  }

  void selectElement({String? panelId, String? bubbleId, String? sfxId}) {
    _selectedPanelId = panelId; _selectedBubbleId = bubbleId; _selectedSfxId = sfxId;
    notifyListeners();
  }

  void selectPanel(String? id) => selectElement(panelId: id);
  void selectBubble(String? id) => selectElement(bubbleId: id);
  void selectSfx(String? id) => selectElement(sfxId: id);
  void deselectAll() => selectElement();

  // --- Páginas ---
  void goToPage(int index) {
    if (index >= 0 && index < _project.pages.length) {
      _project = _project.copyWith(activePageIndex: index);
      _history.clear();
      deselectAll();
      ComicImageCache.decodeAll(activePage, _panelImages, notifyListeners);
      notifyListeners();
    }
  }

  void addPage({ComicTemplateType? template, bool blank = false}) {
    _project = ComicElementOperations.addPage(_project, template: template, blank: blank);
    _history.clear();
    deselectAll();
    notifyListeners();
  }

  bool removePage(int index) {
    final updated = ComicElementOperations.removePage(_project, index);
    if (updated == null) return false;
    _project = updated;
    _history.clear();
    deselectAll();
    ComicImageCache.decodeAll(activePage, _panelImages, notifyListeners);
    notifyListeners();
    return true;
  }

  // --- Paneles y Viñetas Dinámicas ---
  void addPanel({ComicPanelShape shape = ComicPanelShape.rectangle, Rect? normalizedRect}) {
    _history.recordSnapshot(activePage);
    final count = activePage.panels.length;
    final r = normalizedRect ?? (count == 0
        ? const Rect.fromLTWH(0.08, 0.08, 0.84, 0.38)
        : count == 1
            ? const Rect.fromLTWH(0.08, 0.50, 0.84, 0.42)
            : Rect.fromLTWH(0.08, (0.05 + count * 0.15).clamp(0.05, 0.7), 0.84, 0.25));
    final p = ComicPanel(id: 'panel_${DateTime.now().microsecondsSinceEpoch}', normalizedRect: r, panelShape: shape);
    _updateActivePage(activePage.copyWith(panels: List<ComicPanel>.from(activePage.panels)..add(p)));
    selectPanel(p.id);
  }

  void addPanelFromRect(Rect normalizedRect, {ComicPanelShape shape = ComicPanelShape.rectangle}) {
    _history.recordSnapshot(activePage);
    final res = ComicPanelOperations.addPanelFromRect(activePage, normalizedRect, shape: shape);
    _updateActivePage(res.$1);
    selectPanel(res.$2.id);
    _interactionMode = ComicInteractionMode.normal;
  }

  void movePanel(String panelId, double dxNorm, double dyNorm) =>
      _updateActivePage(ComicPanelOperations.movePanel(activePage, panelId, dxNorm, dyNorm));

  void updatePanelRect(String panelId, Rect newRect) =>
      _updateActivePage(ComicPanelOperations.updatePanelRect(activePage, panelId, newRect));

  void updatePanelBorder(String panelId, {double? borderWidth, Color? borderColor, double? borderRadius}) {
    _history.recordSnapshot(activePage);
    _updateActivePage(ComicPanelOperations.updatePanelBorder(
      activePage,
      panelId,
      borderWidth: borderWidth,
      borderColor: borderColor,
      borderRadius: borderRadius,
    ));
  }

  void slicePanelWithLine(String panelId, Offset p1, Offset p2) {
    final res = ComicPanelOperations.slicePanelWithLine(activePage, panelId, p1, p2);
    if (res != null) {
      _history.recordSnapshot(activePage);
      _updateActivePage(res.$1);
      _selectedPanelId = res.$2;
      _interactionMode = ComicInteractionMode.normal;
    }
  }

  void applyTemplateToActivePage(ComicTemplateType template) {
    _history.recordSnapshot(activePage);
    _updateActivePage(activePage.copyWith(panels: template.createPanels()));
  }

  void updatePanel(ComicPanel panel) {
    _history.recordSnapshot(activePage);
    final updated = activePage.panels.map((p) => p.id == panel.id ? panel : p).toList();
    _updateActivePage(activePage.copyWith(panels: updated));
  }

  void setPanelDrawing(String panelId, String? projectId, String? pngBase64) {
    _history.recordSnapshot(activePage);
    final updatedPanels = activePage.panels.map((p) {
      if (p.id == panelId) {
        return p.copyWith(
          drawingProjectId: projectId,
          drawingPngBase64: pngBase64,
          clearDrawing: pngBase64 == null,
        );
      }
      return p;
    }).toList();
    _updateActivePage(activePage.copyWith(panels: updatedPanels));
    if (pngBase64 != null) {
      ComicImageCache.decodeSingle(panelId, pngBase64, _panelImages, notifyListeners);
    } else {
      _panelImages.remove(panelId);
      notifyListeners();
    }
  }

  void setPanelTransform(String panelId, {double? scale, double? dx, double? dy}) =>
      _updateActivePage(ComicPanelOperations.setPanelTransform(activePage, panelId, scale: scale, dx: dx, dy: dy));

  void splitPanel(String panelId, {bool vertical = false}) {
    final result = ComicPanelOperations.splitPanel(activePage, panelId, vertical: vertical);
    if (result != null) {
      _history.recordSnapshot(activePage);
      _updateActivePage(result.$1);
      _selectedPanelId = result.$2;
    }
  }

  void deletePanel(String panelId) {
    _history.recordSnapshot(activePage);
    final updated = List<ComicPanel>.from(activePage.panels)..removeWhere((p) => p.id == panelId);
    if (_selectedPanelId == panelId) _selectedPanelId = null;
    _panelImages.remove(panelId);
    _updateActivePage(activePage.copyWith(panels: updated));
  }

  // --- Globos y Bocadillos ---
  void addBubble({ComicBubbleType type = ComicBubbleType.mangaOval, String text = '¡Hola!', double x = 0.5, double y = 0.4, ComicBubble? bubble}) {
    _history.recordSnapshot(activePage);
    final res = ComicElementOperations.addBubble(activePage, type: type, text: text, x: x, y: y, bubble: bubble);
    _updateActivePage(res.$1);
    selectBubble(res.$2.id);
  }

  void updateBubble(ComicBubble bubble) {
    _history.recordSnapshot(activePage);
    _updateActivePage(ComicElementOperations.updateBubble(activePage, bubble));
  }

  void moveBubble(String id, double x, double y) =>
      _updateActivePage(ComicElementOperations.moveBubble(activePage, id, x, y));

  void deleteBubble(String id) {
    _history.recordSnapshot(activePage);
    if (_selectedBubbleId == id) _selectedBubbleId = null;
    _updateActivePage(ComicElementOperations.deleteBubble(activePage, id));
  }

  // --- Onomatopeyas SFX ---
  void addSfx(String text, {double x = 0.5, double y = 0.5, Color? color, Color? outlineColor, String? font}) {
    _history.recordSnapshot(activePage);
    final res = ComicElementOperations.addSfx(activePage, text, x: x, y: y, color: color, outlineColor: outlineColor, font: font);
    _updateActivePage(res.$1);
    selectSfx(res.$2.id);
  }

  void updateSfx(ComicSticker sfx) {
    _history.recordSnapshot(activePage);
    _updateActivePage(ComicElementOperations.updateSfx(activePage, sfx));
  }

  void moveSfx(String id, double x, double y) =>
      _updateActivePage(ComicElementOperations.moveSfx(activePage, id, x, y));

  void deleteSfx(String id) {
    _history.recordSnapshot(activePage);
    if (_selectedSfxId == id) _selectedSfxId = null;
    _updateActivePage(ComicElementOperations.deleteSfx(activePage, id));
  }

  void _updateActivePage(ComicPage page) {
    final pages = List<ComicPage>.from(_project.pages);
    pages[_project.activePageIndex] = page;
    _project = _project.copyWith(pages: pages, updatedAt: DateTime.now());
    notifyListeners();
  }

  Future<Uint8List?> exportPageToPng(int pageIndex, {Size size = const Size(1200, 1697)}) async {
    if (pageIndex < 0 || pageIndex >= _project.pages.length) return null;
    final page = _project.pages[pageIndex];
    final images = await ComicImageCache.ensureDecoded(page, _panelImages);
    return ComicRenderExporter.exportPageToPng(page, images, size: size);
  }
}
