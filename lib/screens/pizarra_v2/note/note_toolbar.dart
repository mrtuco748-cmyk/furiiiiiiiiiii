import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'note_shape_editor.dart';
import 'note_color_editor.dart';
import 'note_background_editor.dart';
import 'note_font_editor.dart';
import 'note_border_editor.dart';

class NoteToolbar extends StatelessWidget {
  final String currentShape;
  final Color currentColor;
  final List<Color> lastCustomColors;
  final ValueChanged<String> onShapeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<List<Color>> onCustomColorsChanged;
  final Map<String, dynamic> bgState;
  final void Function(String, dynamic) onBgChanged;
  final Map<String, dynamic> fontState;
  final void Function(String, dynamic) onFontChanged;
  final Map<String, dynamic> borderState;
  final void Function(String, dynamic) onBorderChanged;

  const NoteToolbar({
    super.key,
    required this.currentShape,
    required this.currentColor,
    this.lastCustomColors = const [],
    required this.onShapeChanged,
    required this.onColorChanged,
    required this.onCustomColorsChanged,
    this.bgState = const {},
    required this.onBgChanged,
    this.fontState = const {},
    required this.onFontChanged,
    this.borderState = const {},
    required this.onBorderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toolButton(
          icon: Icons.hexagon_outlined,
          color: const Color(0xFF00D4FF),
          tooltip: 'Forma',
          onTap: () { HapticFeedback.selectionClick(); _showShapePicker(context); },
        ),
        const SizedBox(height: 8),
        _toolButton(
          icon: Icons.palette_outlined,
          color: const Color(0xFFFF6B00),
          tooltip: 'Color',
          onTap: () { HapticFeedback.selectionClick(); _showColorPicker(context); },
        ),
        const SizedBox(height: 8),
        _toolButton(
          icon: Icons.wallpaper_outlined,
          color: const Color(0xFF9D00FF),
          tooltip: 'Fondo',
          onTap: () { HapticFeedback.selectionClick(); _showBgEditor(context); },
        ),
        const SizedBox(height: 8),
        _toolButton(
          icon: Icons.text_fields,
          color: const Color(0xFFFF00FF),
          tooltip: 'Fuente',
          onTap: () { HapticFeedback.selectionClick(); _showFontEditor(context); },
        ),
        const SizedBox(height: 8),
        _toolButton(
          icon: Icons.border_style,
          color: const Color(0xFFFF6B00),
          tooltip: 'Borde',
          onTap: () { HapticFeedback.selectionClick(); _showBorderEditor(context); },
        ),
      ],
    );
  }

  Widget _toolButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  void _showShapePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black26,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: NoteShapeEditor(
          selected: currentShape,
          onShapeSelected: onShapeChanged,
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black26,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: NoteColorEditor(
          currentColor: currentColor,
          lastCustomColors: lastCustomColors,
          onColorSelected: onColorChanged,
          onCustomColorsChanged: onCustomColorsChanged,
        ),
      ),
    );
  }

  void _showBgEditor(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      barrierColor: Colors.black26,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: NoteBackgroundEditor(
          bgColor: currentColor,
          gradientType: (bgState['gradientType'] as String?) ?? 'Liso',
          gradientStart: (bgState['gradientStart'] as Color?) ?? const Color(0xFF5C2D91),
          gradientMid: (bgState['gradientMid'] as Color?) ?? const Color(0xFF3A7BD5),
          gradientEnd: (bgState['gradientEnd'] as Color?) ?? const Color(0xFF00D4FF),
          selectedPattern: (bgState['selectedPattern'] as String?) ?? 'Puntos',
          patternEnabled: (bgState['patternEnabled'] as bool?) ?? false,
          customPattern: bgState['customPattern'] as String?,
          patternThickness: (bgState['patternThickness'] as double?) ?? 1.5,
          patternAngle: (bgState['patternAngle'] as double?) ?? 0,
          patternSize: (bgState['patternSize'] as double?) ?? 40,
          patternOpacity: (bgState['patternOpacity'] as double?) ?? 0.25,
          patternSpacing: (bgState['patternSpacing'] as double?) ?? 24,
          patternSaturation: (bgState['patternSaturation'] as double?) ?? 1.0,
          onColorChanged: (c) => onBgChanged('bgColor', c),
          onGradientTypeChanged: (v) => onBgChanged('gradientType', v),
          onGradientStartChanged: (c) => onBgChanged('gradientStart', c),
          onGradientMidChanged: (c) => onBgChanged('gradientMid', c),
          onGradientEndChanged: (c) => onBgChanged('gradientEnd', c),
          onPatternChanged: (v) => onBgChanged('selectedPattern', v),
          onPatternEnabledChanged: (v) => onBgChanged('patternEnabled', v),
          onCustomPatternChanged: (v) => onBgChanged('customPattern', v),
          onPatternThicknessChanged: (v) => onBgChanged('patternThickness', v),
          onPatternAngleChanged: (v) => onBgChanged('patternAngle', v),
          onPatternSizeChanged: (v) => onBgChanged('patternSize', v),
          onPatternOpacityChanged: (v) => onBgChanged('patternOpacity', v),
          onPatternSpacingChanged: (v) => onBgChanged('patternSpacing', v),
          onPatternSaturationChanged: (v) => onBgChanged('patternSaturation', v),
        ),
      ),
    );
  }

  void _showFontEditor(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      barrierColor: Colors.black26,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: NoteFontEditor(
          currentFont: (fontState['fontFamily'] as String?) ?? 'Roboto',
          currentFontColor: (fontState['fontColor'] as Color?) ?? Colors.white,
          currentFontSize: (fontState['fontSize'] as double?) ?? 14,
          onFontChanged: (v) => onFontChanged('fontFamily', v),
          onFontColorChanged: (v) => onFontChanged('fontColor', v),
          onFontSizeChanged: (v) => onFontChanged('fontSize', v),
        ),
      ),
    );
  }

  void _showBorderEditor(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      barrierColor: Colors.black26,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: NoteBorderEditor(
          borderEnabled: (borderState['borderEnabled'] as bool?) ?? false,
          borderColor: (borderState['borderColor'] as Color?) ?? const Color(0xFF39FF14),
          borderType: (borderState['borderType'] as String?) ?? 'Solido',
          borderWidth: (borderState['borderWidth'] as double?) ?? 2,
          borderSpacing: (borderState['borderSpacing'] as double?) ?? 4,
          onEnabledChanged: (v) => onBorderChanged('borderEnabled', v),
          onColorChanged: (v) => onBorderChanged('borderColor', v),
          onTypeChanged: (v) => onBorderChanged('borderType', v),
          onWidthChanged: (v) => onBorderChanged('borderWidth', v),
          onSpacingChanged: (v) => onBorderChanged('borderSpacing', v),
        ),
      ),
    );
  }
}
