import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/board_element.dart';
import '../models/note_style_config.dart';
import '../painters/note_card_painter.dart';
import '../painters/note_shape_utils.dart';

/// Indica qué parte del texto está enfocada actualmente durante la edición
/// para que el sidebar derecho aplique fuentes, colores y formatos al bloque exacto.
class ActiveTextTarget {
  final bool isTitle;
  final int? paragraphIndex;

  const ActiveTextTarget.title()
      : isTitle = true,
        paragraphIndex = null;

  const ActiveTextTarget.bodyDefault()
      : isTitle = false,
        paragraphIndex = null;

  const ActiveTextTarget.paragraph(int index)
      : isTitle = false,
        paragraphIndex = index;
}

/// El objeto único de Nota / Lista de Tareas del Pizarrón.
/// Es EXACTAMENTE el mismo widget cuando está en vista de pizarrón y cuando se está editando:
/// - Cero botones de configuración dentro de la nota.
/// - Multicapa (Fondo sólido/degradado 3 partes/imagen + Patrones + Brillo + Bordes adaptados a la forma).
/// - Padding inscrito inteligente según la forma (rombo, círculo, octágono, hoja, etc.).
/// - Esquina inferior derecha de redimensionado adaptada matemáticamente al perímetro de cada forma.
class PizarronNoteWidget extends StatefulWidget {
  final BoardElement element;
  final NoteStyleConfig styleConfig;
  final bool isEditing;
  final double Function() getCurrentCanvasScale;
  final VoidCallback onTapNote;
  final void Function(double dxWorld, double dyWorld) onDragNote;
  final void Function(double dwWorld, double dhWorld) onResizeNote;
  final void Function(double scaleFactor, Offset focalWorld) onPinchScaleNote;
  final void Function(String newTitle, String newContent) onTextChanged;
  final void Function(NoteStyleConfig updatedConfig) onStyleChanged;
  final void Function(ActiveTextTarget target) onActiveTargetChanged;
  final ActiveTextTarget activeTarget;

  const PizarronNoteWidget({
    super.key,
    required this.element,
    required this.styleConfig,
    required this.isEditing,
    required this.getCurrentCanvasScale,
    required this.onTapNote,
    required this.onDragNote,
    required this.onResizeNote,
    required this.onPinchScaleNote,
    required this.onTextChanged,
    required this.onStyleChanged,
    required this.onActiveTargetChanged,
    required this.activeTarget,
  });

  @override
  State<PizarronNoteWidget> createState() => _PizarronNoteWidgetState();
}

class _PizarronNoteWidgetState extends State<PizarronNoteWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();

  final List<TextEditingController> _paragraphControllers = [];
  final List<FocusNode> _paragraphFocusNodes = [];

  final List<TextEditingController> _checklistControllers = [];

  late AnimationController _shineController;

  // Cache de imágenes decodificadas para evitar parpadeos a 60/120 FPS
  String? _cachedBgBase64Key;
  Uint8List? _cachedBgBytes;
  String? _cachedInlineBase64Key;
  Uint8List? _cachedInlineBytes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.element.title);
    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) {
        widget.onActiveTargetChanged(const ActiveTextTarget.title());
      }
    });

    _syncParagraphControllersFromContent(widget.element.content);
    _syncChecklistControllers();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.styleConfig.hasShine) {
      _shineController.repeat();
    }
    _updateImageCaches();
  }

  @override
  void didUpdateWidget(covariant PizarronNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.styleConfig.hasShine != oldWidget.styleConfig.hasShine) {
      if (widget.styleConfig.hasShine) {
        _shineController.repeat();
      } else {
        _shineController.stop();
        _shineController.value = 0.0;
      }
    }

    if (!widget.isEditing) {
      if (_titleController.text != widget.element.title) {
        _titleController.text = widget.element.title;
      }
      final currentJoined =
          _paragraphControllers.map((c) => c.text).join('\n');
      if (currentJoined != widget.element.content) {
        _syncParagraphControllersFromContent(widget.element.content);
      }
    } else if (oldWidget.element.id != widget.element.id) {
      _titleController.text = widget.element.title;
      _syncParagraphControllersFromContent(widget.element.content);
    }

    _syncChecklistControllers();
    _updateImageCaches();
  }

  void _updateImageCaches() {
    final bgB64 = widget.styleConfig.bgImageBase64;
    if (bgB64 != _cachedBgBase64Key) {
      _cachedBgBase64Key = bgB64;
      if (bgB64 != null && bgB64.isNotEmpty) {
        try {
          _cachedBgBytes = base64Decode(bgB64);
        } catch (_) {
          _cachedBgBytes = null;
        }
      } else {
        _cachedBgBytes = null;
      }
    }

    final inB64 = widget.styleConfig.inlineImageBase64;
    if (inB64 != _cachedInlineBase64Key) {
      _cachedInlineBase64Key = inB64;
      if (inB64 != null && inB64.isNotEmpty) {
        try {
          _cachedInlineBytes = base64Decode(inB64);
        } catch (_) {
          _cachedInlineBytes = null;
        }
      } else {
        _cachedInlineBytes = null;
      }
    }
  }

  void _syncParagraphControllersFromContent(String content) {
    final lines = content.isEmpty ? <String>[''] : content.split('\n');
    while (_paragraphControllers.length > lines.length) {
      _paragraphControllers.removeLast().dispose();
      _paragraphFocusNodes.removeLast().dispose();
    }
    for (int i = 0; i < lines.length; i++) {
      if (i < _paragraphControllers.length) {
        if (_paragraphControllers[i].text != lines[i]) {
          _paragraphControllers[i].text = lines[i];
        }
      } else {
        final ctrl = TextEditingController(text: lines[i]);
        final fn = FocusNode();
        final idx = i;
        fn.addListener(() {
          if (fn.hasFocus) {
            widget.onActiveTargetChanged(ActiveTextTarget.paragraph(idx));
          }
        });
        _paragraphControllers.add(ctrl);
        _paragraphFocusNodes.add(fn);
      }
    }
  }

  void _syncChecklistControllers() {
    if (widget.element.type != 'checklist') return;
    final items = widget.styleConfig.checklistItems;
    while (_checklistControllers.length > items.length) {
      _checklistControllers.removeLast().dispose();
    }
    for (int i = 0; i < items.length; i++) {
      final text = items[i]['text']?.toString() ?? '';
      if (i < _checklistControllers.length) {
        if (!widget.isEditing && _checklistControllers[i].text != text) {
          _checklistControllers[i].text = text;
        }
      } else {
        _checklistControllers.add(TextEditingController(text: text));
      }
    }
  }

  void _emitContentUpdate() {
    final joined = _paragraphControllers.map((c) => c.text).join('\n');
    widget.onTextChanged(_titleController.text, joined);
  }

  void _handleParagraphChanged(int index, String value) {
    // Si el usuario presiona Enter dentro de un párrafo, dividir en un nuevo párrafo
    // para que pueda asignarle fuente, color o formato hundido independiente.
    if (value.contains('\n')) {
      final parts = value.split('\n');
      _paragraphControllers[index].text = parts.first;
      final rest = parts.sublist(1).join(' ');

      final newCtrl = TextEditingController(text: rest);
      final newFn = FocusNode();
      final insertIdx = index + 1;

      _paragraphControllers.insert(insertIdx, newCtrl);
      _paragraphFocusNodes.insert(insertIdx, newFn);

      // Re-vincular listeners de foco con sus índices actualizados
      _rebindParagraphFocusListeners();

      // Desplazar overrides de párrafos posteriores si existen
      final currentOverrides =
          Map<int, ParagraphStyleOverride>.from(widget.styleConfig.paragraphOverrides);
      final updatedOverrides = <int, ParagraphStyleOverride>{};
      currentOverrides.forEach((k, v) {
        if (k < insertIdx) {
          updatedOverrides[k] = v;
        } else {
          updatedOverrides[k + 1] = v;
        }
      });
      // Heredar el estilo del párrafo actual en el nuevo párrafo
      if (currentOverrides.containsKey(index)) {
        updatedOverrides[insertIdx] = currentOverrides[index]!;
      }
      widget.onStyleChanged(
        widget.styleConfig.copyWith(paragraphOverrides: updatedOverrides),
      );

      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && insertIdx < _paragraphFocusNodes.length) {
          _paragraphFocusNodes[insertIdx].requestFocus();
          widget.onActiveTargetChanged(ActiveTextTarget.paragraph(insertIdx));
        }
      });
    }
    _emitContentUpdate();
  }

  void _rebindParagraphFocusListeners() {
    for (int i = 0; i < _paragraphFocusNodes.length; i++) {
      final idx = i;
      final oldNode = _paragraphFocusNodes[i];
      final hadFocus = oldNode.hasFocus;
      oldNode.dispose();
      final newNode = FocusNode();
      newNode.addListener(() {
        if (newNode.hasFocus) {
          widget.onActiveTargetChanged(ActiveTextTarget.paragraph(idx));
        }
      });
      _paragraphFocusNodes[i] = newNode;
      if (hadFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) newNode.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    for (final c in _paragraphControllers) {
      c.dispose();
    }
    for (final f in _paragraphFocusNodes) {
      f.dispose();
    }
    for (final c in _checklistControllers) {
      c.dispose();
    }
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = math.max(120.0, widget.element.width);
    final h = math.max(100.0, widget.element.height);
    final size = Size(w, h);
    final cfg = widget.styleConfig;
    final contentPadding = NoteShapeUtils.getContentPadding(cfg.shapeType, size);
    final handleCenter =
        NoteShapeUtils.getResizeHandleCenter(cfg.shapeType, size);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Capa de imagen de fondo (si baseMode == 'image') recortada a la forma
          if (cfg.baseMode == 'image' && _cachedBgBytes != null)
            Positioned.fill(
              child: ClipPath(
                clipper: NoteShapeClipper(cfg.shapeType),
                child: Opacity(
                  opacity: cfg.bgImageOpacity.clamp(0.1, 1.0),
                  child: Image.memory(
                    _cachedBgBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),

          // 2. Capas vectoriales: Base + Patrón + Brillo + Borde adaptativo
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                return CustomPaint(
                  painter: NoteCardPainter(
                    config: cfg,
                    shineProgress: _shineController.value,
                    isEditing: widget.isEditing,
                  ),
                  child: child,
                );
              },
              child: ClipPath(
                clipper: NoteShapeClipper(
                  cfg.shapeType,
                  inset: cfg.borderType == NoteBorderType.none
                      ? 2.0
                      : cfg.borderWidth + 2.0,
                ),
                child: Padding(
                  padding: contentPadding,
                  child: _buildCardInterior(size, cfg),
                ),
              ),
            ),
          ),

          // 3. Zona de agarre en la esquina inferior-derecha adaptada a la forma
          Positioned(
            left: handleCenter.dx - 16,
            top: handleCenter.dy - 16,
            width: 32,
            height: 32,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                final scale = widget.getCurrentCanvasScale();
                final safeScale = scale <= 0.001 ? 1.0 : scale;
                widget.onResizeNote(
                  details.delta.dx / safeScale,
                  details.delta.dy / safeScale,
                );
              },
              child: CustomPaint(
                painter: _AdaptiveResizeCornerPainter(
                  color: PizarronPalette.parseHex(cfg.titleColor)
                      .withValues(alpha: 0.55),
                  shape: cfg.shapeType,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInterior(Size cardSize, NoteStyleConfig cfg) {
    if (widget.element.type == 'checklist') {
      return _buildChecklistInterior(cardSize, cfg);
    }
    return _buildNoteInterior(cardSize, cfg);
  }

  Widget _buildNoteInterior(Size cardSize, NoteStyleConfig cfg) {
    final hasImg = _cachedInlineBytes != null;
    final imgPos = cfg.inlineImagePosition;
    final imgHeight =
        (cardSize.height * cfg.inlineImageHeightRatio).clamp(48.0, cardSize.height * 0.55);

    final paraCount = _paragraphControllers.length;
    final midSplit = (paraCount / 2).ceil();

    return Column(
      crossAxisAlignment: _crossAxisForAlign(cfg.textAlign),
      mainAxisSize: MainAxisSize.max,
      children: [
        // --- TÍTULO ---
        _buildTitleBlock(cfg),

        const SizedBox(height: 6),

        // --- IMAGEN ARRIBA DEL CUERPO ---
        if (hasImg && imgPos == InlineImagePosition.aboveBody) ...[
          _buildInlineImageWidget(imgHeight),
          const SizedBox(height: 8),
        ],

        // --- CUERPO DE PÁRRAFOS (CON SOPORTE PARA IMAGEN EN EL MEDIO O ABAJO) ---
        Expanded(
          child: SingleChildScrollView(
            physics: widget.isEditing
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: _crossAxisForAlign(cfg.textAlign),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < paraCount; i++) ...[
                  if (hasImg &&
                      imgPos == InlineImagePosition.middleBody &&
                      i == midSplit) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildInlineImageWidget(imgHeight),
                    ),
                  ],
                  _buildParagraphBlock(i, cfg),
                ],
                if (hasImg &&
                    imgPos == InlineImagePosition.middleBody &&
                    paraCount <= 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildInlineImageWidget(imgHeight),
                  ),
                ],
                if (hasImg && imgPos == InlineImagePosition.belowBody) ...[
                  const SizedBox(height: 8),
                  _buildInlineImageWidget(imgHeight),
                ],
              ],
            ),
          ),
        ),

        // --- IMAGEN AL PIE DE PÁGINA (FOOTER) ---
        if (hasImg && imgPos == InlineImagePosition.footer) ...[
          const SizedBox(height: 6),
          _buildInlineImageWidget(imgHeight * 0.85),
        ],
      ],
    );
  }

  Widget _buildTitleBlock(NoteStyleConfig cfg) {
    final titleColor = PizarronPalette.parseHex(cfg.titleColor);
    final style = PizarronFontCatalog.resolveFont(
      cfg.titleFont,
      fontSize: cfg.titleSize,
      color: titleColor,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    final isFocusedTitle = widget.isEditing && widget.activeTarget.isTitle;

    final field = IgnorePointer(
      ignoring: !widget.isEditing,
      child: TextField(
        controller: _titleController,
        focusNode: _titleFocus,
        readOnly: !widget.isEditing,
        textAlign: cfg.textAlign,
        style: style,
        maxLines: 2,
        minLines: 1,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: widget.isEditing ? '•••' : '',
          hintStyle: style.copyWith(
            color: titleColor.withValues(alpha: 0.32),
          ),
        ),
        onChanged: (_) => _emitContentUpdate(),
      ),
    );

    return _FormattedBlockContainer(
      format: cfg.titleFormat,
      accentColor: titleColor,
      isHighlightedTarget: isFocusedTitle,
      child: field,
    );
  }

  Widget _buildParagraphBlock(int index, NoteStyleConfig cfg) {
    final override = cfg.paragraphOverrides[index];
    final fontName = override?.fontFamily ?? cfg.bodyFont;
    final colorHex = override?.colorHex ?? cfg.bodyColor;
    final fontSize = override?.fontSize ?? cfg.bodySize;
    final format =
        (override != null && override.format != TextBlockFormat.none)
            ? override.format
            : cfg.bodyFormat;

    final textColor = PizarronPalette.parseHex(colorHex);
    final style = PizarronFontCatalog.resolveFont(
      fontName,
      fontSize: fontSize,
      color: textColor,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    final isTargetPara = widget.isEditing &&
        !widget.activeTarget.isTitle &&
        widget.activeTarget.paragraphIndex == index;

    final field = IgnorePointer(
      ignoring: !widget.isEditing,
      child: TextField(
        controller: _paragraphControllers[index],
        focusNode: _paragraphFocusNodes[index],
        readOnly: !widget.isEditing,
        textAlign: cfg.textAlign,
        style: style,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          border: InputBorder.none,
          hintText: (widget.isEditing && index == 0) ? '•••' : '',
          hintStyle: style.copyWith(
            color: textColor.withValues(alpha: 0.28),
          ),
        ),
        onChanged: (val) => _handleParagraphChanged(index, val),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _FormattedBlockContainer(
        format: format,
        accentColor: textColor,
        isHighlightedTarget: isTargetPara,
        child: field,
      ),
    );
  }

  Widget _buildInlineImageWidget(double height) {
    if (_cachedInlineBytes == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.memory(
          _cachedInlineBytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Widget _buildChecklistInterior(Size cardSize, NoteStyleConfig cfg) {
    final items = cfg.checklistItems;
    final textColor = PizarronPalette.parseHex(cfg.bodyColor);
    final titleColor = PizarronPalette.parseHex(cfg.titleColor);
    final itemStyle = PizarronFontCatalog.resolveFont(
      cfg.bodyFont,
      fontSize: cfg.bodySize,
      color: textColor,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: _crossAxisForAlign(cfg.textAlign),
      children: [
        _buildTitleBlock(cfg),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            physics: widget.isEditing
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final nextItems = items
                                .map((m) => Map<String, dynamic>.from(m))
                                .toList();
                            final done = nextItems[i]['done'] == true;
                            nextItems[i]['done'] = !done;
                            widget.onStyleChanged(
                              cfg.copyWith(checklistItems: nextItems),
                            );
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: items[i]['done'] == true
                                  ? const Color(0xFF2EE50F)
                                  : textColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: items[i]['done'] == true
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Color(0xFF141820),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: IgnorePointer(
                            ignoring: !widget.isEditing,
                            child: TextField(
                              controller: i < _checklistControllers.length
                                  ? _checklistControllers[i]
                                  : null,
                              readOnly: !widget.isEditing,
                              style: itemStyle.copyWith(
                                decoration: items[i]['done'] == true
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: items[i]['done'] == true
                                    ? textColor.withValues(alpha: 0.45)
                                    : textColor,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 2),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                final nextItems = items
                                    .map((m) => Map<String, dynamic>.from(m))
                                    .toList();
                                nextItems[i]['text'] = val;
                                widget.onStyleChanged(
                                  cfg.copyWith(checklistItems: nextItems),
                                );
                              },
                            ),
                          ),
                        ),
                        if (widget.isEditing && items.length > 1)
                          GestureDetector(
                            onTap: () {
                              final nextItems = items
                                  .map((m) => Map<String, dynamic>.from(m))
                                  .toList()
                                ..removeAt(i);
                              if (i < _checklistControllers.length) {
                                _checklistControllers.removeAt(i).dispose();
                              }
                              widget.onStyleChanged(
                                cfg.copyWith(checklistItems: nextItems),
                              );
                            },
                            child: Icon(
                              Icons.remove_circle_rounded,
                              size: 18,
                              color: textColor.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (widget.isEditing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        final nextItems = items
                            .map((m) => Map<String, dynamic>.from(m))
                            .toList()
                          ..add({'text': '', 'done': false});
                        widget.onStyleChanged(
                          cfg.copyWith(checklistItems: nextItems),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: titleColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  CrossAxisAlignment _crossAxisForAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }
}

/// Renderiza los formatos especiales de bloque para Títulos y Párrafos:
/// - `escuadra`: línea vertical a la derecha + línea horizontal abajo gruesa y bonita
/// - `escuadraLeft`: línea vertical a la izquierda + línea horizontal abajo
/// - `thickUnderline`: subrayado grueso redondeado
/// - `topBottomLines`: bordes de línea superior e inferior
/// - `sunken`: fondo oscuro hundido con sombreado interno
/// - `quoteBar`: barra lateral izquierda gruesa con fondo tenue
/// - `framed`: marco perimetral completo
class _FormattedBlockContainer extends StatelessWidget {
  final TextBlockFormat format;
  final Color accentColor;
  final bool isHighlightedTarget;
  final Widget child;

  const _FormattedBlockContainer({
    required this.format,
    required this.accentColor,
    required this.isHighlightedTarget,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    switch (format) {
      case TextBlockFormat.none:
        break;

      case TextBlockFormat.escuadra:
        // Como una escuadra: solo la línea derecha y la línea horizontal inferior gruesa
        content = CustomPaint(
          painter: _EscuadraPainter(
            color: accentColor.withValues(alpha: 0.88),
            rightSide: true,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 10, 7),
            child: content,
          ),
        );
        break;

      case TextBlockFormat.escuadraLeft:
        content = CustomPaint(
          painter: _EscuadraPainter(
            color: accentColor.withValues(alpha: 0.88),
            rightSide: false,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 4, 7),
            child: content,
          ),
        );
        break;

      case TextBlockFormat.thickUnderline:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: 3),
            Container(
              height: 4.5,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
        break;

      case TextBlockFormat.topBottomLines:
        content = Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: accentColor.withValues(alpha: 0.75),
                width: 2.2,
              ),
              bottom: BorderSide(
                color: accentColor.withValues(alpha: 0.75),
                width: 2.2,
              ),
            ),
          ),
          child: content,
        );
        break;

      case TextBlockFormat.sunken:
        // Formato hundido con fondo oscuro y sombreado interno
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x660B0E14),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55080A0F),
                offset: Offset(0, 2),
                blurRadius: 3,
                spreadRadius: -1,
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0x66080A0F), width: 2.0),
              left: BorderSide(color: Color(0x55080A0F), width: 1.5),
              bottom: BorderSide(color: Color(0x28FFFFFF), width: 1.0),
              right: BorderSide(color: Color(0x18FFFFFF), width: 1.0),
            ),
          ),
          child: content,
        );
        break;

      case TextBlockFormat.quoteBar:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(
                color: accentColor.withValues(alpha: 0.90),
                width: 4.0,
              ),
            ),
          ),
          child: content,
        );
        break;

      case TextBlockFormat.framed:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.75),
              width: 2.0,
            ),
          ),
          child: content,
        );
        break;
    }

    return content;
  }
}

class _EscuadraPainter extends CustomPainter {
  final Color color;
  final bool rightSide;

  _EscuadraPainter({
    required this.color,
    required this.rightSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (rightSide) {
      // Línea vertical derecha y línea horizontal inferior
      path.moveTo(size.width - 2, 2);
      path.lineTo(size.width - 2, size.height - 2);
      path.lineTo(2, size.height - 2);
    } else {
      // Línea vertical izquierda y línea horizontal inferior
      path.moveTo(2, 2);
      path.lineTo(2, size.height - 2);
      path.lineTo(size.width - 2, size.height - 2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EscuadraPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.rightSide != rightSide;
  }
}

class _AdaptiveResizeCornerPainter extends CustomPainter {
  final Color color;
  final NoteShapeType shape;

  _AdaptiveResizeCornerPainter({
    required this.color,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Dibuja un sutil arco/escuadra de agarre en la esquina adaptada a la forma
    final p1 = Path()
      ..moveTo(cx + 5, cy - 3)
      ..lineTo(cx + 5, cy + 5)
      ..lineTo(cx - 3, cy + 5);
    canvas.drawPath(p1, paint);

    final p2 = Path()
      ..moveTo(cx + 1, cy - 1)
      ..lineTo(cx + 1, cy + 1)
      ..lineTo(cx - 1, cy + 1);
    canvas.drawPath(p2, paint);
  }

  @override
  bool shouldRepaint(covariant _AdaptiveResizeCornerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shape != shape;
  }
}
