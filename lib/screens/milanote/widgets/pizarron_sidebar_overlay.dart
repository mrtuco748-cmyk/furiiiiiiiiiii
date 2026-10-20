import 'package:flutter/material.dart';

import '../models/note_style_config.dart';
import '../painters/note_shape_utils.dart';
import 'pizarron_color_picker_area.dart';
import 'pizarron_note_widget.dart';

/// Categorías del panel lateral derecho de edición.
enum SidebarSection {
  baseLayer,
  patternLayer,
  shape,
  border,
  typography,
  inlineImage,
}

/// Barra lateral derecha de personalización (Overlay de edición).
/// Reglas de diseño:
/// - 100% guiada por íconos y previsualizaciones visuales (cero palabras/etiquetas de texto).
/// - Cero popups modales: todo se despliega suavemente junto al riel derecho.
/// - Bloques sólidos sin bordes negros puros (cumpliendo `skill_visual .md`).
class PizarronSidebarOverlay extends StatefulWidget {
  final NoteStyleConfig config;
  final ActiveTextTarget activeTarget;
  final ValueChanged<NoteStyleConfig> onConfigChanged;
  final ValueChanged<ActiveTextTarget> onTargetChanged;
  final VoidCallback onPickBackgroundImage;
  final VoidCallback onPickInlineImage;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onCloseEdit;

  const PizarronSidebarOverlay({
    super.key,
    required this.config,
    required this.activeTarget,
    required this.onConfigChanged,
    required this.onTargetChanged,
    required this.onPickBackgroundImage,
    required this.onPickInlineImage,
    required this.onDuplicate,
    required this.onDelete,
    required this.onCloseEdit,
  });

  @override
  State<PizarronSidebarOverlay> createState() => _PizarronSidebarOverlayState();
}

class _PizarronSidebarOverlayState extends State<PizarronSidebarOverlay> {
  SidebarSection? _activeSection;
  int _gradientStopIndex = 0; // 0 = inicial, 1 = medio, 2 = final
  late TextEditingController _emojiPatternController;

  static const Color _panelBg = Color(0xFF1A1F2E);
  static const Color _cardBg = Color(0xFF252C40);
  static const Color _activeAccent = Color(0xFF2EE50F);
  static const Color _secondaryAccent = Color(0xFF7B2CBF);

  @override
  void initState() {
    super.initState();
    _emojiPatternController =
        TextEditingController(text: widget.config.patternEmojiText);
  }

  @override
  void didUpdateWidget(covariant PizarronSidebarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.patternEmojiText != _emojiPatternController.text) {
      _emojiPatternController.text = widget.config.patternEmojiText;
    }
  }

  @override
  void dispose() {
    _emojiPatternController.dispose();
    super.dispose();
  }

  List<String> _getSampledColors() {
    final cfg = widget.config;
    final set = <String>{};
    if (cfg.solidColor.isNotEmpty) set.add(cfg.solidColor);
    if (cfg.gradientStartColor.isNotEmpty) set.add(cfg.gradientStartColor);
    if (cfg.gradientMidColor.isNotEmpty) set.add(cfg.gradientMidColor);
    if (cfg.gradientEndColor.isNotEmpty) set.add(cfg.gradientEndColor);
    if (cfg.patternColor1.isNotEmpty) set.add(cfg.patternColor1);
    if (cfg.patternColor2.isNotEmpty) set.add(cfg.patternColor2);
    if (cfg.borderColor.isNotEmpty) set.add(cfg.borderColor);
    if (cfg.titleColor.isNotEmpty) set.add(cfg.titleColor);
    if (cfg.bodyColor.isNotEmpty) set.add(cfg.bodyColor);
    set.add('#4FC3F7');
    set.add('#CE93D8');
    set.add('#2EE50F');
    set.add('#FFFFFF');
    set.add('#141820');
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Subpanel contextual de la herramienta activa (se pliega cuando no hay sección activa)
            if (_activeSection != null) ...[
              Container(
                width: 224,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.84,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _panelBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildActiveSubpanel(_activeSection!),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Riel principal vertical derecho de íconos
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: _panelBg,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRailIcon(
                    icon: Icons.layers_rounded,
                    section: SidebarSection.baseLayer,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.grid_on_rounded,
                    section: SidebarSection.patternLayer,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.category_rounded,
                    section: SidebarSection.shape,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.border_style_rounded,
                    section: SidebarSection.border,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.text_fields_rounded,
                    section: SidebarSection.typography,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.image_rounded,
                    section: SidebarSection.inlineImage,
                  ),
                  const SizedBox(height: 14),
                  _buildActionIcon(
                    icon: Icons.copy_rounded,
                    bgColor: _cardBg,
                    iconColor: Colors.white,
                    onTap: widget.onDuplicate,
                  ),
                  const SizedBox(height: 8),
                  _buildActionIcon(
                    icon: Icons.delete_rounded,
                    bgColor: const Color(0xFF421C26),
                    iconColor: const Color(0xFFFF4D6D),
                    onTap: widget.onDelete,
                  ),
                  const SizedBox(height: 10),
                  _buildActionIcon(
                    icon: Icons.check_rounded,
                    bgColor: _activeAccent,
                    iconColor: const Color(0xFF141820),
                    onTap: widget.onCloseEdit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailIcon({
    required IconData icon,
    required SidebarSection section,
  }) {
    final selected = _activeSection == section;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_activeSection == section) {
            _activeSection = null; // Cierra si se vuelve a tocar
          } else {
            _activeSection = section; // Abre la sección seleccionada
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? _secondaryAccent : _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildActiveSubpanel(SidebarSection section) {
    switch (section) {
      case SidebarSection.baseLayer:
        return _buildBaseLayerPanel();
      case SidebarSection.patternLayer:
        return _buildPatternLayerPanel();
      case SidebarSection.shape:
        return _buildShapePanel();
      case SidebarSection.border:
        return _buildBorderPanel();
      case SidebarSection.typography:
        return _buildTypographyPanel();
      case SidebarSection.inlineImage:
        return _buildInlineImagePanel();
    }
  }

  // ===========================================================================
  // 1. PANEL CAPA BASE: Sólido / Degradado 3 partes / Imagen + Brillo
  // ===========================================================================
  Widget _buildBaseLayerPanel() {
    final cfg = widget.config;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector de modo de capa base (Sólido, Degradado 3 partes, Foto) + Brillo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModeButton(
              icon: Icons.circle,
              isSelected: cfg.baseMode == 'solid',
              onTap: () =>
                  widget.onConfigChanged(cfg.copyWith(baseMode: 'solid')),
            ),
            _buildModeButton(
              icon: Icons.gradient_rounded,
              isSelected: cfg.baseMode == 'gradient',
              onTap: () =>
                  widget.onConfigChanged(cfg.copyWith(baseMode: 'gradient')),
            ),
            _buildModeButton(
              icon: Icons.photo_camera_back_rounded,
              isSelected: cfg.baseMode == 'image',
              onTap: () {
                widget.onConfigChanged(cfg.copyWith(baseMode: 'image'));
                if (!cfg.hasBgImage) {
                  widget.onPickBackgroundImage();
                }
              },
            ),
            _buildModeButton(
              icon: Icons.auto_awesome_rounded,
              isSelected: cfg.hasShine,
              activeColor: const Color(0xFFFFB703),
              onTap: () =>
                  widget.onConfigChanged(cfg.copyWith(hasShine: !cfg.hasShine)),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (cfg.baseMode == 'solid') ...[
          PizarronColorPickerArea(
            currentColorHex: cfg.solidColor,
            sampledColors: _getSampledColors(),
            onColorChanged: (hex) =>
                widget.onConfigChanged(cfg.copyWith(solidColor: hex)),
          ),
        ] else if (cfg.baseMode == 'gradient') ...[
          // Selector visual de las 3 paradas del degradado: Inicial (0), Medio (1), Final (2)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  PizarronPalette.parseHex(cfg.gradientStartColor),
                  PizarronPalette.parseHex(cfg.gradientMidColor),
                  PizarronPalette.parseHex(cfg.gradientEndColor),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGradientStopDot(0, cfg.gradientStartColor),
                _buildGradientStopDot(1, cfg.gradientMidColor),
                _buildGradientStopDot(2, cfg.gradientEndColor),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Ángulo del degradado con íconos de dirección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAngleButton(0.0, Icons.arrow_forward_rounded, cfg),
              _buildAngleButton(45.0, Icons.south_east_rounded, cfg),
              _buildAngleButton(90.0, Icons.arrow_downward_rounded, cfg),
              _buildAngleButton(135.0, Icons.south_west_rounded, cfg),
            ],
          ),
          const SizedBox(height: 12),
          PizarronColorPickerArea(
            currentColorHex: _gradientStopIndex == 0
                ? cfg.gradientStartColor
                : (_gradientStopIndex == 1
                    ? cfg.gradientMidColor
                    : cfg.gradientEndColor),
            sampledColors: _getSampledColors(),
            onColorChanged: (hex) {
              if (_gradientStopIndex == 0) {
                widget.onConfigChanged(cfg.copyWith(gradientStartColor: hex));
              } else if (_gradientStopIndex == 1) {
                widget.onConfigChanged(cfg.copyWith(gradientMidColor: hex));
              } else {
                widget.onConfigChanged(cfg.copyWith(gradientEndColor: hex));
              }
            },
          ),
        ] else if (cfg.baseMode == 'image') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(
                icon: Icons.add_photo_alternate_rounded,
                bgColor: _secondaryAccent,
                iconColor: Colors.white,
                onTap: widget.onPickBackgroundImage,
              ),
              if (cfg.hasBgImage)
                _buildActionIcon(
                  icon: Icons.hide_image_rounded,
                  bgColor: const Color(0xFF421C26),
                  iconColor: const Color(0xFFFF4D6D),
                  onTap: () => widget.onConfigChanged(
                    cfg.copyWith(clearBgImage: true, baseMode: 'solid'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildIconSlider(
            icon: Icons.opacity_rounded,
            value: cfg.bgImageOpacity,
            min: 0.15,
            max: 1.0,
            onChanged: (v) =>
                widget.onConfigChanged(cfg.copyWith(bgImageOpacity: v)),
          ),
        ],
      ],
    );
  }

  Widget _buildGradientStopDot(int index, String hex) {
    final isSelected = _gradientStopIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _gradientStopIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSelected ? 30 : 22,
        height: isSelected ? 30 : 22,
        decoration: BoxDecoration(
          color: PizarronPalette.parseHex(hex),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0x55141820),
              blurRadius: isSelected ? 6 : 2,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.adjust_rounded,
                size: 16,
                color: PizarronPalette.parseHex(hex).computeLuminance() > 0.5
                    ? const Color(0xFF141820)
                    : Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildAngleButton(
      double angle, IconData icon, NoteStyleConfig cfg) {
    final selected = (cfg.gradientAngle - angle).abs() < 1.0;
    return GestureDetector(
      onTap: () => widget.onConfigChanged(cfg.copyWith(gradientAngle: angle)),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? _secondaryAccent : _cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ===========================================================================
  // 2. PANEL CAPA DE PATRONES (Con controles contextuales inteligentes)
  // ===========================================================================
  Widget _buildPatternLayerPanel() {
    final cfg = widget.config;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grilla de iconos de patrones
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in NotePatternType.values)
              _buildPatternTile(p, cfg.patternType == p),
          ],
        ),

        if (cfg.patternType != NotePatternType.none) ...[
          const SizedBox(height: 12),

          // Si el patrón soporta toggle relleno/vacío (Círculos)
          if (cfg.patternSupportsFillToggle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(
                  icon: Icons.circle,
                  isSelected: cfg.patternType == NotePatternType.circlesFilled,
                  onTap: () => widget.onConfigChanged(
                    cfg.copyWith(patternType: NotePatternType.circlesFilled),
                  ),
                ),
                const SizedBox(width: 10),
                _buildModeButton(
                  icon: Icons.circle_outlined,
                  isSelected: cfg.patternType == NotePatternType.circlesEmpty,
                  onTap: () => widget.onConfigChanged(
                    cfg.copyWith(patternType: NotePatternType.circlesEmpty),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Si es patrón de Emoji/Texto: selector rápido + campo directo sin popup
          if (cfg.patternSupportsEmojiInput) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final em in const [
                  '✨',
                  '❤️',
                  '🔥',
                  '⭐',
                  '🌸',
                  '🦊',
                  '🌙',
                  '⚡',
                  '🎵',
                  '💎'
                ])
                  GestureDetector(
                    onTap: () {
                      _emojiPatternController.text = em;
                      widget.onConfigChanged(
                          cfg.copyWith(patternEmojiText: em));
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cfg.patternEmojiText == em
                            ? _secondaryAccent
                            : _cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(em, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _emojiPatternController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        counterText: '',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onConfigChanged(
                            cfg.copyWith(patternEmojiText: val.trim()),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Sliders contextuales según el patrón elegido:
          // 1. Grosor (solo líneas, ondas, círculos vacíos, cuadrícula)
          if (cfg.patternSupportsStrokeWidth)
            _buildIconSlider(
              icon: Icons.line_weight_rounded,
              value: cfg.patternStrokeWidth,
              min: 1.0,
              max: 12.0,
              onChanged: (v) =>
                  widget.onConfigChanged(cfg.copyWith(patternStrokeWidth: v)),
            ),

          // 2. Espaciado (NO aparece en ajedrez porque son bloques juntos)
          if (cfg.patternSupportsSpacing)
            _buildIconSlider(
              icon: Icons.space_bar_rounded,
              value: cfg.patternSpacing,
              min: 6.0,
              max: 64.0,
              onChanged: (v) =>
                  widget.onConfigChanged(cfg.copyWith(patternSpacing: v)),
            ),

          // 3. Tamaño / Escala (bloques de ajedrez, radio de círculos, amplitud de ondas, emoji)
          if (cfg.patternSupportsScale)
            _buildIconSlider(
              icon: Icons.zoom_out_map_rounded,
              value: cfg.patternScale,
              min: 8.0,
              max: 48.0,
              onChanged: (v) =>
                  widget.onConfigChanged(cfg.copyWith(patternScale: v)),
            ),

          // 4. Opacidad del patrón
          _buildIconSlider(
            icon: Icons.opacity_rounded,
            value: cfg.patternOpacity,
            min: 0.05,
            max: 0.95,
            onChanged: (v) =>
                widget.onConfigChanged(cfg.copyWith(patternOpacity: v)),
          ),

          const SizedBox(height: 8),

          // Toggle de color sólido vs degradado en el patrón
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeButton(
                icon: Icons.lens_rounded,
                isSelected: !cfg.patternUseGradient,
                onTap: () => widget.onConfigChanged(
                  cfg.copyWith(patternUseGradient: false),
                ),
              ),
              const SizedBox(width: 10),
              _buildModeButton(
                icon: Icons.gradient_rounded,
                isSelected: cfg.patternUseGradient,
                onTap: () => widget.onConfigChanged(
                  cfg.copyWith(patternUseGradient: true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          PizarronColorPickerArea(
            currentColorHex: cfg.patternColor1,
            sampledColors: _getSampledColors(),
            onColorChanged: (hex) =>
                widget.onConfigChanged(cfg.copyWith(patternColor1: hex)),
          ),
          if (cfg.patternUseGradient) ...[
            const SizedBox(height: 10),
            PizarronColorPickerArea(
              currentColorHex: cfg.patternColor2,
              sampledColors: _getSampledColors(),
              onColorChanged: (hex) =>
                  widget.onConfigChanged(cfg.copyWith(patternColor2: hex)),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPatternTile(NotePatternType type, bool selected) {
    return GestureDetector(
      onTap: () => widget.onConfigChanged(
        widget.config.copyWith(patternType: type),
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? _secondaryAccent : _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _iconForPattern(type),
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

  IconData _iconForPattern(NotePatternType type) {
    switch (type) {
      case NotePatternType.none:
        return Icons.block_rounded;
      case NotePatternType.chess:
        return Icons.apps_rounded;
      case NotePatternType.linesOblique:
        return Icons.texture_rounded;
      case NotePatternType.linesHorizontal:
        return Icons.reorder_rounded;
      case NotePatternType.linesVertical:
        return Icons.view_week_rounded;
      case NotePatternType.waves:
        return Icons.waves_rounded;
      case NotePatternType.circlesFilled:
        return Icons.bubble_chart_rounded;
      case NotePatternType.circlesEmpty:
        return Icons.radio_button_unchecked_rounded;
      case NotePatternType.dots:
        return Icons.grain_rounded;
      case NotePatternType.grid:
        return Icons.grid_4x4_rounded;
      case NotePatternType.emoji:
        return Icons.auto_awesome_rounded;
    }
  }

  // ===========================================================================
  // 3. PANEL DE FORMAS (11 formas vectoriales con vista previa exacta)
  // ===========================================================================
  Widget _buildShapePanel() {
    final cfg = widget.config;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final shape in NoteShapeType.values)
          GestureDetector(
            onTap: () {
              // Si cambia a forma geométrica simétrica (rombo, círculo, hexágono, octágono),
              // ajustar alineación al centro para que encaje perfecto.
              final shouldCenter = shape == NoteShapeType.diamond ||
                  shape == NoteShapeType.circle ||
                  shape == NoteShapeType.hexagon ||
                  shape == NoteShapeType.octagon ||
                  shape == NoteShapeType.shield;
              widget.onConfigChanged(
                cfg.copyWith(
                  shapeType: shape,
                  textAlign:
                      shouldCenter ? TextAlign.center : cfg.textAlign,
                ),
              );
            },
            child: Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cfg.shapeType == shape ? _secondaryAccent : _cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: _ShapeMiniPreviewPainter(shape: shape),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // 4. PANEL DE BORDES (Ninguno, Sólido, Punteado, Rayas, Doble línea, Ondulado)
  // ===========================================================================
  Widget _buildBorderPanel() {
    final cfg = widget.config;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final bt in NoteBorderType.values)
              GestureDetector(
                onTap: () =>
                    widget.onConfigChanged(cfg.copyWith(borderType: bt)),
                child: Container(
                  width: 58,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cfg.borderType == bt ? _secondaryAccent : _cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomPaint(
                    painter: _BorderMiniPreviewPainter(borderType: bt),
                  ),
                ),
              ),
          ],
        ),
        if (cfg.borderType != NoteBorderType.none) ...[
          const SizedBox(height: 12),
          _buildIconSlider(
            icon: Icons.line_weight_rounded,
            value: cfg.borderWidth,
            min: 1.5,
            max: 10.0,
            onChanged: (v) =>
                widget.onConfigChanged(cfg.copyWith(borderWidth: v)),
          ),
          if (cfg.borderType != NoteBorderType.solid)
            _buildIconSlider(
              icon: Icons.space_bar_rounded,
              value: cfg.borderSpacing,
              min: 3.0,
              max: 24.0,
              onChanged: (v) =>
                  widget.onConfigChanged(cfg.copyWith(borderSpacing: v)),
            ),
          const SizedBox(height: 8),
          PizarronColorPickerArea(
            currentColorHex: cfg.borderColor,
            sampledColors: _getSampledColors(),
            onColorChanged: (hex) =>
                widget.onConfigChanged(cfg.copyWith(borderColor: hex)),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 5. PANEL DE TIPOGRAFÍA, FORMATOS DE BLOQUE Y COLORES DE TEXTO
  // ===========================================================================
  Widget _buildTypographyPanel() {
    final cfg = widget.config;
    final target = widget.activeTarget;

    // Obtener valores actuales según si el foco está en el título, un párrafo específico o el cuerpo general
    String currentFont = cfg.bodyFont;
    String currentColor = cfg.bodyColor;
    double currentSize = cfg.bodySize;
    TextBlockFormat currentFormat = cfg.bodyFormat;

    if (target.isTitle) {
      currentFont = cfg.titleFont;
      currentColor = cfg.titleColor;
      currentSize = cfg.titleSize;
      currentFormat = cfg.titleFormat;
    } else if (target.paragraphIndex != null) {
      final ov = cfg.paragraphOverrides[target.paragraphIndex!];
      currentFont = ov?.fontFamily ?? cfg.bodyFont;
      currentColor = ov?.colorHex ?? cfg.bodyColor;
      currentSize = ov?.fontSize ?? cfg.bodySize;
      currentFormat = ov?.format ?? cfg.bodyFormat;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector de objetivo: Título vs Cuerpo / Párrafo + Alineación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModeButton(
              icon: Icons.title_rounded,
              isSelected: target.isTitle,
              onTap: () =>
                  widget.onTargetChanged(const ActiveTextTarget.title()),
            ),
            _buildModeButton(
              icon: Icons.notes_rounded,
              isSelected: !target.isTitle,
              onTap: () => widget.onTargetChanged(
                target.paragraphIndex != null
                    ? ActiveTextTarget.paragraph(target.paragraphIndex!)
                    : const ActiveTextTarget.bodyDefault(),
              ),
            ),
            _buildModeButton(
              icon: Icons.format_align_left_rounded,
              isSelected: cfg.textAlign == TextAlign.left,
              onTap: () => widget.onConfigChanged(
                cfg.copyWith(textAlign: TextAlign.left),
              ),
            ),
            _buildModeButton(
              icon: Icons.format_align_center_rounded,
              isSelected: cfg.textAlign == TextAlign.center,
              onTap: () => widget.onConfigChanged(
                cfg.copyWith(textAlign: TextAlign.center),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Tamaño de letra
        _buildIconSlider(
          icon: Icons.format_size_rounded,
          value: currentSize.clamp(11.0, 38.0),
          min: 11.0,
          max: 38.0,
          onChanged: (v) => _applyTypographyChange(fontSize: v),
        ),

        const SizedBox(height: 8),

        // Formatos de bloque (Normal, Escuadra derecha, Escuadra izquierda, Subrayado grueso,
        // Líneas arriba/abajo, Hundido oscuro, Barra lateral, Enmarcado)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final fmt in TextBlockFormat.values)
              GestureDetector(
                onTap: () => _applyTypographyChange(format: fmt),
                child: Container(
                  width: 44,
                  height: 38,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentFormat == fmt ? _secondaryAccent : _cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _BlockFormatMiniPainter(format: fmt),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Catálogo de 22 fuentes extravagantes representadas con glifos visuales en su propia fuente
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final font in PizarronFontCatalog.fonts)
              GestureDetector(
                onTap: () => _applyTypographyChange(fontFamily: font),
                child: Container(
                  width: 44,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: currentFont == font ? _secondaryAccent : _cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    PizarronFontCatalog.glyphFor(font),
                    style: PizarronFontCatalog.resolveFont(
                      font,
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Color del texto del bloque activo
        PizarronColorPickerArea(
          currentColorHex: currentColor,
          sampledColors: _getSampledColors(),
          onColorChanged: (hex) => _applyTypographyChange(colorHex: hex),
        ),
      ],
    );
  }

  void _applyTypographyChange({
    String? fontFamily,
    String? colorHex,
    double? fontSize,
    TextBlockFormat? format,
  }) {
    final cfg = widget.config;
    final target = widget.activeTarget;

    if (target.isTitle) {
      widget.onConfigChanged(
        cfg.copyWith(
          titleFont: fontFamily ?? cfg.titleFont,
          titleColor: colorHex ?? cfg.titleColor,
          titleSize: fontSize ?? cfg.titleSize,
          titleFormat: format ?? cfg.titleFormat,
        ),
      );
    } else if (target.paragraphIndex != null) {
      final idx = target.paragraphIndex!;
      final nextOverrides =
          Map<int, ParagraphStyleOverride>.from(cfg.paragraphOverrides);
      final existing = nextOverrides[idx] ??
          ParagraphStyleOverride(
            fontFamily: cfg.bodyFont,
            colorHex: cfg.bodyColor,
            fontSize: cfg.bodySize,
            format: cfg.bodyFormat,
          );
      nextOverrides[idx] = existing.copyWith(
        fontFamily: fontFamily,
        colorHex: colorHex,
        fontSize: fontSize,
        format: format,
      );
      widget.onConfigChanged(cfg.copyWith(paragraphOverrides: nextOverrides));
    } else {
      widget.onConfigChanged(
        cfg.copyWith(
          bodyFont: fontFamily ?? cfg.bodyFont,
          bodyColor: colorHex ?? cfg.bodyColor,
          bodySize: fontSize ?? cfg.bodySize,
          bodyFormat: format ?? cfg.bodyFormat,
        ),
      );
    }
  }

  // ===========================================================================
  // 6. PANEL DE IMAGEN INTEGRADA EN LA NOTA (4 Posiciones + Tamaño)
  // ===========================================================================
  Widget _buildInlineImagePanel() {
    final cfg = widget.config;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionIcon(
              icon: Icons.add_photo_alternate_rounded,
              bgColor: _secondaryAccent,
              iconColor: Colors.white,
              onTap: widget.onPickInlineImage,
            ),
            if (cfg.hasInlineImage)
              _buildActionIcon(
                icon: Icons.delete_sweep_rounded,
                bgColor: const Color(0xFF421C26),
                iconColor: const Color(0xFFFF4D6D),
                onTap: () => widget.onConfigChanged(
                  cfg.copyWith(clearInlineImage: true),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 posiciones de la imagen respecto al texto:
        // Arriba del cuerpo, En el medio del cuerpo, Abajo del cuerpo, Pie de página
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final pos in InlineImagePosition.values)
              GestureDetector(
                onTap: () => widget.onConfigChanged(
                  cfg.copyWith(inlineImagePosition: pos),
                ),
                child: Container(
                  width: 44,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cfg.inlineImagePosition == pos
                        ? _secondaryAccent
                        : _cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomPaint(
                    painter: _ImagePositionMiniPainter(position: pos),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        _buildIconSlider(
          icon: Icons.height_rounded,
          value: cfg.inlineImageHeightRatio,
          min: 0.20,
          max: 0.55,
          onChanged: (v) =>
              widget.onConfigChanged(cfg.copyWith(inlineImageHeightRatio: v)),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES COMPARTIDOS
  // ===========================================================================
  Widget _buildModeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = _secondaryAccent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIconSlider({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: _activeAccent,
              inactiveTrackColor: _cardBg,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShapeMiniPreviewPainter extends CustomPainter {
  final NoteShapeType shape;

  _ShapeMiniPreviewPainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final path = NoteShapeUtils.buildShapePath(shape, size);
    final fillPaint = Paint()
      ..color = const Color(0x38FFFFFF)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ShapeMiniPreviewPainter oldDelegate) =>
      oldDelegate.shape != shape;
}

class _BorderMiniPreviewPainter extends CustomPainter {
  final NoteBorderType borderType;

  _BorderMiniPreviewPainter({required this.borderType});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    switch (borderType) {
      case NoteBorderType.none:
        final p = Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(size.width * 0.3, size.height * 0.25),
          Offset(size.width * 0.7, size.height * 0.75),
          p,
        );
        break;
      case NoteBorderType.solid:
        canvas.drawLine(Offset(4, cy), Offset(size.width - 4, cy), paint);
        break;
      case NoteBorderType.dotted:
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        for (double x = 6; x <= size.width - 6; x += 8) {
          canvas.drawCircle(Offset(x, cy), 2.2, dotPaint);
        }
        break;
      case NoteBorderType.dashed:
        for (double x = 4; x < size.width - 6; x += 11) {
          canvas.drawLine(Offset(x, cy), Offset(x + 6, cy), paint);
        }
        break;
      case NoteBorderType.doubleLine:
        canvas.drawLine(
            Offset(4, cy - 3), Offset(size.width - 4, cy - 3), paint);
        canvas.drawLine(
            Offset(4, cy + 3), Offset(size.width - 4, cy + 3), paint);
        break;
      case NoteBorderType.wavy:
        final path = Path()..moveTo(4, cy);
        for (double x = 4; x < size.width - 6; x += 10) {
          path.quadraticBezierTo(x + 2.5, cy - 4, x + 5, cy);
          path.quadraticBezierTo(x + 7.5, cy + 4, x + 10, cy);
        }
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BorderMiniPreviewPainter oldDelegate) =>
      oldDelegate.borderType != borderType;
}

class _BlockFormatMiniPainter extends CustomPainter {
  final TextBlockFormat format;

  _BlockFormatMiniPainter({required this.format});

  @override
  void paint(Canvas canvas, Size size) {
    final textPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = const Color(0xFF2EE50F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    if (format == TextBlockFormat.sunken) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, w - 4, h - 4),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = const Color(0xAA0C0F17),
      );
    }

    // Líneas simulando texto
    canvas.drawLine(Offset(6, h * 0.36), Offset(w - 8, h * 0.36), textPaint);
    canvas.drawLine(Offset(6, h * 0.62), Offset(w * 0.65, h * 0.62), textPaint);

    switch (format) {
      case TextBlockFormat.none:
        break;
      case TextBlockFormat.escuadra:
        final p = Path()
          ..moveTo(w - 3, 3)
          ..lineTo(w - 3, h - 3)
          ..lineTo(4, h - 3);
        canvas.drawPath(p, accentPaint);
        break;
      case TextBlockFormat.escuadraLeft:
        final p = Path()
          ..moveTo(3, 3)
          ..lineTo(3, h - 3)
          ..lineTo(w - 4, h - 3);
        canvas.drawPath(p, accentPaint);
        break;
      case TextBlockFormat.thickUnderline:
        canvas.drawLine(
          Offset(4, h - 3),
          Offset(w - 4, h - 3),
          accentPaint..strokeWidth = 3.4,
        );
        break;
      case TextBlockFormat.topBottomLines:
        canvas.drawLine(Offset(3, 2), Offset(w - 3, 2), accentPaint);
        canvas.drawLine(Offset(3, h - 2), Offset(w - 3, h - 2), accentPaint);
        break;
      case TextBlockFormat.sunken:
        canvas.drawLine(
          Offset(3, 3),
          Offset(w - 3, 3),
          Paint()
            ..color = const Color(0xFF2EE50F)
            ..strokeWidth = 1.6,
        );
        break;
      case TextBlockFormat.quoteBar:
        canvas.drawLine(
          Offset(3, 3),
          Offset(3, h - 3),
          accentPaint..strokeWidth = 3.5,
        );
        break;
      case TextBlockFormat.framed:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(2, 2, w - 4, h - 4),
            const Radius.circular(4),
          ),
          accentPaint..strokeWidth = 2.0,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BlockFormatMiniPainter oldDelegate) =>
      oldDelegate.format != format;
}

class _ImagePositionMiniPainter extends CustomPainter {
  final InlineImagePosition position;

  _ImagePositionMiniPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final imgPaint = Paint()
      ..color = const Color(0xFF2EE50F)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Título siempre arriba
    canvas.drawLine(Offset(4, 4), Offset(w * 0.7, 4), linePaint);

    switch (position) {
      case InlineImagePosition.aboveBody:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4, 9, w - 8, 11),
            const Radius.circular(3),
          ),
          imgPaint,
        );
        canvas.drawLine(Offset(4, 25), Offset(w - 4, 25), linePaint);
        canvas.drawLine(Offset(4, 30), Offset(w - 6, 30), linePaint);
        break;

      case InlineImagePosition.middleBody:
        canvas.drawLine(Offset(4, 10), Offset(w - 4, 10), linePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4, 14, w - 8, 11),
            const Radius.circular(3),
          ),
          imgPaint,
        );
        canvas.drawLine(Offset(4, 30), Offset(w - 5, 30), linePaint);
        break;

      case InlineImagePosition.belowBody:
        canvas.drawLine(Offset(4, 10), Offset(w - 4, 10), linePaint);
        canvas.drawLine(Offset(4, 15), Offset(w - 6, 15), linePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4, 20, w - 8, 11),
            const Radius.circular(3),
          ),
          imgPaint,
        );
        break;

      case InlineImagePosition.footer:
        canvas.drawLine(Offset(4, 10), Offset(w - 4, 10), linePaint);
        canvas.drawLine(Offset(4, 15), Offset(w - 6, 15), linePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(2, h - 10, w - 4, 8),
            const Radius.circular(2),
          ),
          imgPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ImagePositionMiniPainter oldDelegate) =>
      oldDelegate.position != position;
}
