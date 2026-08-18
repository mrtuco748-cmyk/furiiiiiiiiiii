import 'package:flutter/material.dart';
import 'note_gradient_color_picker.dart';

const _patternOptions = [
  ('Puntos', Icons.blur_on),
  ('Líneas H', Icons.horizontal_rule),
  ('Líneas V', Icons.more_vert),
  ('Cuadrícula', Icons.grid_on),
  ('Diagonales', Icons.grid_3x3),
  ('Zigzag', Icons.show_chart),
  ('Diamantes', Icons.diamond_outlined),
  ('Ondas', Icons.waves),
  ('Círculos', Icons.circle_outlined),
  ('Triángulos', Icons.change_history),
  ('Rayas', Icons.brush),
  ('Panal', Icons.hexagon),
];

const _gradientTypes = ['Liso', 'Lineal', 'Radial'];

class NoteBackgroundEditor extends StatefulWidget {
  final Color bgColor;
  final String gradientType;
  final Color gradientStart;
  final Color gradientMid;
  final Color gradientEnd;
  final String selectedPattern;
  final bool patternEnabled;
  final String? customPattern;
  final double patternThickness;
  final double patternAngle;
  final double patternSize;
  final double patternOpacity;
  final double patternSpacing;
  final double patternSaturation;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onGradientTypeChanged;
  final ValueChanged<Color> onGradientStartChanged;
  final ValueChanged<Color> onGradientMidChanged;
  final ValueChanged<Color> onGradientEndChanged;
  final ValueChanged<String> onPatternChanged;
  final ValueChanged<bool> onPatternEnabledChanged;
  final ValueChanged<String?> onCustomPatternChanged;
  final ValueChanged<double> onPatternThicknessChanged;
  final ValueChanged<double> onPatternAngleChanged;
  final ValueChanged<double> onPatternSizeChanged;
  final ValueChanged<double> onPatternOpacityChanged;
  final ValueChanged<double> onPatternSpacingChanged;
  final ValueChanged<double> onPatternSaturationChanged;

  const NoteBackgroundEditor({
    super.key,
    required this.bgColor,
    this.gradientType = 'Liso',
    this.gradientStart = const Color(0xFF1A1A1A),
    this.gradientMid = const Color(0xFF333333),
    this.gradientEnd = const Color(0xFF0A0A0A),
    this.selectedPattern = 'Puntos',
    this.patternEnabled = false,
    this.customPattern,
    this.patternThickness = 1.5,
    this.patternAngle = 0,
    this.patternSize = 40,
    this.patternOpacity = 0.25,
    this.patternSpacing = 24,
    this.patternSaturation = 1.0,
    required this.onColorChanged,
    required this.onGradientTypeChanged,
    required this.onGradientStartChanged,
    required this.onGradientMidChanged,
    required this.onGradientEndChanged,
    required this.onPatternChanged,
    required this.onPatternEnabledChanged,
    required this.onCustomPatternChanged,
    required this.onPatternThicknessChanged,
    required this.onPatternAngleChanged,
    required this.onPatternSizeChanged,
    required this.onPatternOpacityChanged,
    required this.onPatternSpacingChanged,
    required this.onPatternSaturationChanged,
  });

  @override
  State<NoteBackgroundEditor> createState() => _NoteBackgroundEditorState();
}

class _NoteBackgroundEditorState extends State<NoteBackgroundEditor> {
  int _layer = 1;
  late String _gradType;
  late Color _gStart, _gMid, _gEnd;
  late String _pat;
  late bool _patEnabled;
  late double _thick, _angle, _size, _opacity, _spacing, _saturation;
  late final TextEditingController _patCtrl; // null, 'start', 'mid', 'end'

  @override
  void initState() {
    super.initState();
    _patCtrl = TextEditingController(text: widget.customPattern ?? '');
    _layer = 1;
    _syncFromWidget();
  }

  @override
  void dispose() {
    _patCtrl.dispose();
    super.dispose();
  }

  void _syncFromWidget() {
    _gradType = widget.gradientType;
    _gStart = widget.gradientStart;
    _gMid = widget.gradientMid;
    _gEnd = widget.gradientEnd;
    _pat = widget.selectedPattern;
    _patEnabled = widget.patternEnabled;
    _thick = widget.patternThickness;
    _angle = widget.patternAngle;
    _size = widget.patternSize;
    _opacity = widget.patternOpacity;
    _spacing = widget.patternSpacing;
    _saturation = widget.patternSaturation;
    if (widget.customPattern != _patCtrl.text) {
      _patCtrl.text = widget.customPattern ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant NoteBackgroundEditor old) {
    super.didUpdateWidget(old);
    if (old.gradientType != widget.gradientType) setState(() => _gradType = widget.gradientType);
    if (old.gradientStart != widget.gradientStart) setState(() => _gStart = widget.gradientStart);
    if (old.gradientMid != widget.gradientMid) setState(() => _gMid = widget.gradientMid);
    if (old.gradientEnd != widget.gradientEnd) setState(() => _gEnd = widget.gradientEnd);
    if (old.selectedPattern != widget.selectedPattern) setState(() => _pat = widget.selectedPattern);
    if (old.patternEnabled != widget.patternEnabled) setState(() => _patEnabled = widget.patternEnabled);
    if (old.patternThickness != widget.patternThickness) setState(() => _thick = widget.patternThickness);
    if (old.patternAngle != widget.patternAngle) setState(() => _angle = widget.patternAngle);
    if (old.patternSize != widget.patternSize) setState(() => _size = widget.patternSize);
    if (old.patternOpacity != widget.patternOpacity) setState(() => _opacity = widget.patternOpacity);
    if (old.patternSpacing != widget.patternSpacing) setState(() => _spacing = widget.patternSpacing);
    if (old.patternSaturation != widget.patternSaturation) setState(() => _saturation = widget.patternSaturation);
    if (old.customPattern != widget.customPattern) {
      _patCtrl.text = widget.customPattern ?? '';
    }
  }

  static const _sec = TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12);
  static const _dim = TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 10);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildTabs(),
      const SizedBox(height: 16),
      if (_layer == 1) _buildType(),
      if (_layer == 2) _buildPattern(),
    ]);
  }

  Widget _buildTabs() {
    return Row(children: [
      _tab('Capa 1\nDegradado', 1),
      const SizedBox(width: 6),
      _tab('Capa 2\nPatrón', 2),
    ]);
  }

  Widget _tab(String label, int i) {
    final active = _layer == i;
    final colors = [const Color(0xFF00D4FF), const Color(0xFF9D00FF)];
    return GestureDetector(
      onTap: () => setState(() => _layer = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors[i - 1] : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? colors[i - 1] : const Color(0xFF333333), width: 1.5),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: active ? const Color(0xFF0A0A0A) : Colors.white54, fontFamily: 'monospace', fontSize: 11)),
      ),
    );
  }

  Widget _buildType() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('Tipo de relleno', style: _sec),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in _gradientTypes) _typeChip(t),
      ]),
      if (_gradType != 'Liso') ...[
        const SizedBox(height: 14),
        const Text('Colores del degradado', style: _sec),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _gradDot('Inicio', _gStart, (c) { setState(() => _gStart = c); widget.onGradientStartChanged(c); }),
          _gradDot('Medio', _gMid, (c) { setState(() => _gMid = c); widget.onGradientMidChanged(c); }),
          _gradDot('Borde', _gEnd, (c) { setState(() => _gEnd = c); widget.onGradientEndChanged(c); }),
        ]),
      ],
    ]);
  }

  Widget _typeChip(String t) {
    final active = _gradType == t;
    return GestureDetector(
      onTap: () {
        setState(() => _gradType = t);
        widget.onGradientTypeChanged(t);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00D4FF) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF00D4FF) : const Color(0xFF333333), width: 1.5),
        ),
        child: Text(t, style: TextStyle(
          color: active ? const Color(0xFF0A0A0A) : Colors.white70,
          fontFamily: 'monospace', fontSize: 12)),
      ),
    );
  }

  Widget _gradDot(String label, Color c, ValueChanged<Color> onPick) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => GradientColorPicker(initialColor: c, onPicked: onPick),
          );
        },
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c, width: 1.5))),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 9)),
    ]);
  }

  Widget _buildPattern() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        const Text('Patrón', style: _sec),
        const Spacer(),
        GestureDetector(
          onTap: () {
            setState(() => _patEnabled = !_patEnabled);
            widget.onPatternEnabledChanged(_patEnabled);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46, height: 26, padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _patEnabled ? const Color(0xFF9D00FF) : const Color(0xFF333333),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: _patEnabled ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 20, height: 20,
              decoration: BoxDecoration(
                color: _patEnabled ? const Color(0xFF0A0A0A) : Colors.white38,
                shape: BoxShape.circle)),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in _patternOptions) _patTile(p.$1, p.$2),
      ]),
      const SizedBox(height: 12),
      const Text('Personalizado (texto/emoji)', style: _sec),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333), width: 1.5)),
        child: TextField(
          controller: _patCtrl,
          onChanged: (v) {
            widget.onCustomPatternChanged(v.isNotEmpty ? v : null);
          },
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'ej: ❤️ o texto', hintStyle: TextStyle(color: Colors.white24, fontFamily: 'monospace'),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
      ),
      const SizedBox(height: 16),
      const Text('Ajustes', style: _sec),
      const SizedBox(height: 8),
      _slider('Grosor', _thick, 0.5, 8, (v) { setState(() => _thick = v); widget.onPatternThicknessChanged(v); }),
      _slider('Ángulo', _angle, 0, 360, (v) { setState(() => _angle = v); widget.onPatternAngleChanged(v); }),
      _slider('Tamaño', _size, 4, 80, (v) { setState(() => _size = v); widget.onPatternSizeChanged(v); }),
      _slider('Opacidad', _opacity, 0.05, 1.0, (v) { setState(() => _opacity = v); widget.onPatternOpacityChanged(v); }),
      _slider('Espaciado', _spacing, 2, 60, (v) { setState(() => _spacing = v); widget.onPatternSpacingChanged(v); }),
      _slider('Saturación', _saturation, 0, 1, (v) { setState(() => _saturation = v); widget.onPatternSaturationChanged(v); }),
    ]);
  }

  Widget _patTile(String name, IconData icon) {
    final active = _pat == name;
    return GestureDetector(
      onTap: () {
        setState(() { _pat = name; _patEnabled = true; });
        widget.onPatternChanged(name);
        widget.onPatternEnabledChanged(true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF9D00FF) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF9D00FF) : const Color(0xFF333333), width: active ? 2.5 : 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: active ? const Color(0xFF0A0A0A) : Colors.white54),
          const SizedBox(height: 2),
          Text(name, style: TextStyle(color: active ? const Color(0xFF0A0A0A) : Colors.white38,
            fontFamily: 'monospace', fontSize: 8)),
        ]),
      ),
    );
  }

  Widget _slider(String label, double val, double min, double max, ValueChanged<double> cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 72, child: Text(label, style: _dim)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: const Color(0xFF9D00FF),
              inactiveTrackColor: const Color(0xFF333333),
              thumbColor: const Color(0xFF9D00FF),
              overlayColor: const Color(0xFF9D00FF).withValues(alpha: 0.2),
            ),
            child: Slider(value: val, min: min, max: max, onChanged: cb),
          ),
        ),
        SizedBox(width: 34, child: Text(val.toStringAsFixed(1), textAlign: TextAlign.right, style: _dim)),
      ]),
    );
  }
}
