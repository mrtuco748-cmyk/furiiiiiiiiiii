import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/board_element.dart';
import '../milanote_colors.dart';

/// Tarjeta de elemento de Milanote con edición directa e inline
/// y arrastre fluido local a 60/120 FPS sin lag.
class MilanoteElementCard extends StatefulWidget {
  final BoardElement element;
  final double canvasScale;
  final bool isSelected;
  final bool isConnectingSource;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final Function(double worldDx, double worldDy, double totalDx, double totalDy) onDragUpdate;
  final Function(double totalDx, double totalDy) onDragEnd;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onStartConnect;
  final Function(BoardElement) onUpdate;
  final Function(int subBoardId, String title)? onOpenSubBoard;

  const MilanoteElementCard({
    super.key,
    required this.element,
    this.canvasScale = 1.0,
    required this.isSelected,
    this.isConnectingSource = false,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDelete,
    required this.onDuplicate,
    required this.onStartConnect,
    required this.onUpdate,
    this.onOpenSubBoard,
  });

  @override
  State<MilanoteElementCard> createState() => _MilanoteElementCardState();
}

class _MilanoteElementCardState extends State<MilanoteElementCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  Timer? _debounceTimer;

  // Arrastre suave local para 60/120 FPS sin reconstruir todo el árbol de widgets
  double _dragLocalDx = 0.0;
  double _dragLocalDy = 0.0;
  bool _isDragging = false;

  // Controlador para nueva tarea rápida en checklist
  final TextEditingController _newChecklistCtrl = TextEditingController();
  bool _isAddingChecklistItem = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.element.title);
    _contentCtrl = TextEditingController(text: widget.element.content);
  }

  @override
  void didUpdateWidget(MilanoteElementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.id != widget.element.id) {
      _titleCtrl.text = widget.element.title;
      _contentCtrl.text = widget.element.content;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _newChecklistCtrl.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    _isDragging = true;
    _dragLocalDx = 0.0;
    _dragLocalDy = 0.0;
    widget.onDragStart();
    widget.onTap();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final scale = widget.canvasScale > 0 ? widget.canvasScale : 1.0;
    final worldDx = details.delta.dx / scale;
    final worldDy = details.delta.dy / scale;

    setState(() {
      _dragLocalDx += worldDx;
      _dragLocalDy += worldDy;
    });

    widget.onDragUpdate(worldDx, worldDy, _dragLocalDx, _dragLocalDy);
  }

  void _handleDragEnd() {
    if (!_isDragging) return;
    final finalDx = _dragLocalDx;
    final finalDy = _dragLocalDy;
    setState(() {
      _isDragging = false;
      _dragLocalDx = 0.0;
      _dragLocalDy = 0.0;
    });
    widget.onDragEnd(finalDx, finalDy);
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      widget.onUpdate(widget.element.copyWith(
        title: _titleCtrl.text,
        content: _contentCtrl.text,
      ));
    });
  }

  void _changeColor(Color color) {
    HapticFeedback.selectionClick();
    widget.onUpdate(widget.element.copyWith(
      color: MilanotePalette.toHex(color),
    ));
  }

  void _toggleCardWidth() {
    HapticFeedback.selectionClick();
    final newWidth = widget.element.width > 260 ? 220.0 : 340.0;
    widget.onUpdate(widget.element.copyWith(width: newWidth));
  }

  Future<void> _pickCardImage() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    final updatedData = Map<String, dynamic>.from(widget.element.data);
    updatedData['imagePath'] = file.path;

    widget.onUpdate(widget.element.copyWith(
      data: updatedData,
      content: file.path,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final bgColor = MilanotePalette.parseHex(
      el.color,
      defaultColor: MilanotePalette.noteYellow,
    );
    final isDark = bgColor.computeLuminance() < 0.45;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2024);

    return Positioned(
      left: el.x + _dragLocalDx,
      top: el.y + _dragLocalDy,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onPanStart: (_) => _handleDragStart(),
          onPanUpdate: _handleDragUpdate,
          onPanEnd: (_) => _handleDragEnd(),
          onPanCancel: _handleDragEnd,
          child: Container(
            width: el.width,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: (widget.isSelected || widget.isConnectingSource)
                  ? Border.all(
                      color: widget.isConnectingSource
                          ? const Color(0xFF39FF14)
                          : const Color(0xFF00E5FF),
                      width: 2.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDragging ? 0.45 : (widget.isSelected ? 0.35 : 0.15),
                  ),
                  blurRadius: _isDragging ? 22 : (widget.isSelected ? 14 : 6),
                  offset: _isDragging ? const Offset(0, 8) : const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER DE ARRASTRE Y TÍTULO DIRECTO (INLINE)
                _buildHeaderWithDragHandle(textColor, isDark),

                // 2. CUERPO EDITABLE DIRECTAMENTE SEGÚN TIPO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _buildCardBody(textColor, isDark),
                ),

                // 3. BARRA DE HERRAMIENTAS MILANOTE (si está seleccionada)
                if (widget.isSelected)
                  _buildMilanoteToolbar(isDark, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithDragHandle(Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          // Icono de agarre / Drag Handle
          MouseRegion(
            cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 16,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 4),

          // Icono del tipo
          Icon(
            _typeIcon(widget.element.type),
            size: 15,
            color: textColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),

          // TÍTULO EDITABLE DIRECTAMENTE EN LA NOTA (INLINE)
          Expanded(
            child: TextField(
              controller: _titleCtrl,
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: _defaultTitleForType(widget.element.type),
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'board':
        return Icons.folder_rounded;
      case 'column':
        return Icons.view_column_rounded;
      case 'checklist':
        return Icons.checklist_rounded;
      case 'colorSwatch':
        return Icons.palette_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'drawing':
        return Icons.brush_rounded;
      default:
        return Icons.sticky_note_2_rounded;
    }
  }

  String _defaultTitleForType(String type) {
    switch (type) {
      case 'board':
        return 'Sub-Tablero';
      case 'column':
        return 'Columna';
      case 'checklist':
        return 'Lista de Tareas';
      case 'colorSwatch':
        return 'Paleta de Color';
      case 'image':
        return 'Foto / Imagen';
      case 'drawing':
        return 'Boceto';
      default:
        return 'Nota';
    }
  }

  Widget _buildCardBody(Color textColor, bool isDark) {
    switch (widget.element.type) {
      case 'board':
        return _buildBoardBody(textColor);
      case 'checklist':
        return _buildChecklistBody(textColor);
      case 'colorSwatch':
        return _buildColorSwatchBody(textColor);
      case 'column':
        return _buildColumnBody(textColor);
      case 'drawing':
        return _buildDrawingBody(textColor);
      case 'image':
        return _buildImageBody(textColor);
      case 'note':
      default:
        return _buildNoteBody(textColor);
    }
  }

  // NOTA: ESCRITURA TOTALMENTE DIRECTA E INLINE
  Widget _buildNoteBody(Color textColor) {
    return TextField(
      controller: _contentCtrl,
      maxLines: null,
      minLines: 3,
      style: GoogleFonts.plusJakartaSans(
        color: textColor.withValues(alpha: 0.9),
        fontSize: 13,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: 'Escribe aquí tu nota directamente...',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textColor.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (_) => _onFieldChanged(),
    );
  }

  // SUB-TABLERO MILANOTE
  Widget _buildBoardBody(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _contentCtrl,
          maxLines: 2,
          style: GoogleFonts.plusJakartaSans(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: 'Descripción del tablero...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => _onFieldChanged(),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (widget.onOpenSubBoard != null && widget.element.id != null) {
              HapticFeedback.mediumImpact();
              widget.onOpenSubBoard!(
                widget.element.id!,
                _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Sub-Tablero',
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 16,
                  color: Color(0xFF00E5FF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Entrar al Tablero',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // CHECKLIST DIRECTO E INTERACTIVO
  Widget _buildChecklistBody(Color textColor) {
    final items = List<Map<String, dynamic>>.from(
      (widget.element.data['items'] as List?) ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(items.length, (idx) {
          final item = items[idx];
          final isChecked = item['checked'] == true;
          final itemText = item['text']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    items[idx]['checked'] = !isChecked;
                    final updatedData = Map<String, dynamic>.from(widget.element.data);
                    updatedData['items'] = items;
                    widget.onUpdate(widget.element.copyWith(data: updatedData));
                  },
                  child: Icon(
                    isChecked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: isChecked
                        ? const Color(0xFF39FF14)
                        : textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: itemText,
                    style: GoogleFonts.plusJakartaSans(
                      color: isChecked
                          ? textColor.withValues(alpha: 0.4)
                          : textColor,
                      fontSize: 12,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      items[idx]['text'] = val;
                      final updatedData = Map<String, dynamic>.from(widget.element.data);
                      updatedData['items'] = items;
                      widget.onUpdate(widget.element.copyWith(data: updatedData));
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    items.removeAt(idx);
                    final updatedData = Map<String, dynamic>.from(widget.element.data);
                    updatedData['items'] = items;
                    widget.onUpdate(widget.element.copyWith(data: updatedData));
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 6),

        // Campo para añadir tarea directo en la misma nota (cero popups)
        if (_isAddingChecklistItem)
          Row(
            children: [
              const Icon(
                Icons.check_box_outline_blank_rounded,
                size: 18,
                color: Colors.white38,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newChecklistCtrl,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nombre de la tarea...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      items.add({'text': val.trim(), 'checked': false});
                      final updatedData = Map<String, dynamic>.from(widget.element.data);
                      updatedData['items'] = items;
                      widget.onUpdate(widget.element.copyWith(data: updatedData));
                      _newChecklistCtrl.clear();
                    }
                    setState(() => _isAddingChecklistItem = false);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final val = _newChecklistCtrl.text.trim();
                  if (val.isNotEmpty) {
                    items.add({'text': val, 'checked': false});
                    final updatedData = Map<String, dynamic>.from(widget.element.data);
                    updatedData['items'] = items;
                    widget.onUpdate(widget.element.copyWith(data: updatedData));
                    _newChecklistCtrl.clear();
                  }
                  setState(() => _isAddingChecklistItem = false);
                },
              ),
            ],
          )
        else
          GestureDetector(
            onTap: () {
              setState(() => _isAddingChecklistItem = true);
            },
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Añadir tarea...',
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // PALETA DE COLOR INTERACTIVA
  Widget _buildColorSwatchBody(Color textColor) {
    final hexCode = widget.element.data['hex']?.toString() ?? widget.element.color;
    final parsed = MilanotePalette.parseHex(hexCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: parsed,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hexCode.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.firaCode(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: MilanotePalette.swatchColors.take(8).map((c) {
            return GestureDetector(
              onTap: () {
                final hex = MilanotePalette.toHex(c);
                final updatedData = Map<String, dynamic>.from(widget.element.data);
                updatedData['hex'] = hex;
                widget.onUpdate(widget.element.copyWith(
                  data: updatedData,
                  color: hex,
                ));
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // IMAGEN MILANOTE CON CARGA DIRECTA
  Widget _buildImageBody(Color textColor) {
    final imgPath = widget.element.data['imagePath']?.toString() ?? widget.element.content;
    final hasImage = imgPath.isNotEmpty && File(imgPath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _pickCardImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.file(File(imgPath), fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 32,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Toca para subir imagen',
                          style: GoogleFonts.plusJakartaSans(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _contentCtrl,
          style: GoogleFonts.plusJakartaSans(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 11,
          ),
          decoration: InputDecoration(
            hintText: 'Pie de foto / nota...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 11,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => _onFieldChanged(),
        ),
      ],
    );
  }

  Widget _buildDrawingBody(Color textColor) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gesture_rounded,
              size: 34,
              color: textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Boceto creativo',
              style: GoogleFonts.plusJakartaSans(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnBody(Color textColor) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: Center(
        child: Text(
          'Columna Milanote\nOrganiza elementos arrastrándolos aquí',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: textColor.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // BARRA DE HERRAMIENTAS MILANOTE (COLOR, ANCHO, DUPLICAR, CONECTAR, BORRAR)
  Widget _buildMilanoteToolbar(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Column(
        children: [
          // Fila de colores Milanote rápidos (Post-It, Melocotón, Rosa, Celeste, Menta, Carbón)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _colorDot(MilanotePalette.noteYellow),
              _colorDot(MilanotePalette.notePeach),
              _colorDot(MilanotePalette.notePink),
              _colorDot(MilanotePalette.noteBlue),
              _colorDot(MilanotePalette.noteMint),
              _colorDot(MilanotePalette.notePurple),
              _colorDot(MilanotePalette.noteCharcoal),
            ],
          ),
          const SizedBox(height: 6),

          // Botonera de acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Alternar ancho
              GestureDetector(
                onTap: _toggleCardWidth,
                child: Tooltip(
                  message: 'Cambiar Ancho',
                  child: Icon(
                    Icons.aspect_ratio_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Conectar con flecha a otra tarjeta
              GestureDetector(
                onTap: widget.onStartConnect,
                child: Tooltip(
                  message: 'Conectar con otra tarjeta',
                  child: Icon(
                    Icons.alt_route_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Duplicar
              GestureDetector(
                onTap: widget.onDuplicate,
                child: Tooltip(
                  message: 'Duplicar tarjeta',
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Eliminar
              GestureDetector(
                onTap: widget.onDelete,
                child: const Tooltip(
                  message: 'Eliminar tarjeta',
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFFF5252),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => _changeColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
