import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NoteColorWheel extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const NoteColorWheel({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<NoteColorWheel> createState() => _NoteColorWheelState();
}

class _NoteColorWheelState extends State<NoteColorWheel> {
  late double _hue;
  late double _saturation;
  late double _brightness;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
  }

  void _emit() {
    widget.onColorChanged(
      HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPreview(),
        const SizedBox(height: 16),
        _buildHueSlider(),
        const SizedBox(height: 12),
        _buildSaturationBrightnessSquare(),
      ],
    );
  }

  Widget _buildPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: HSVColor.fromAHSV(1, _hue, _saturation, _brightness)
                .toColor(),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: HSVColor.fromAHSV(1, _hue, _saturation, _brightness)
                  .toColor(),
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '#${HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHueSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tono',
          style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (d) => _updateHue(d.localPosition.dx, constraints.maxWidth),
                onPanUpdate: (d) => _updateHue(d.localPosition.dx, constraints.maxWidth),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 24),
                  painter: _HueBarPainter(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateHue(double x, double width) {
    setState(() {
      _hue = (x / width).clamp(0, 1) * 360;
    });
    _emit();
  }

  Widget _buildSaturationBrightnessSquare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saturación / Brillo',
          style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (d) =>
                    _updateSB(d.localPosition, constraints.maxWidth, constraints.maxHeight),
                onPanUpdate: (d) =>
                    _updateSB(d.localPosition, constraints.maxWidth, constraints.maxHeight),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _SBPainter(hue: _hue),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateSB(Offset p, double w, double h) {
    setState(() {
      _saturation = (p.dx / w).clamp(0, 1);
      _brightness = 1 - (p.dy / h).clamp(0, 1);
    });
    _emit();
  }
}

class _HueBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.clipRRect(rect);

    for (double x = 0; x < size.width; x++) {
      final hue = (x / size.width) * 360;
      final color = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 1, size.height),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HueBarPainter oldDelegate) => false;
}

class _SBPainter extends CustomPainter {
  final double hue;
  _SBPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.clipRRect(rect);

    // White to hue (horizontal = saturation)
    final satPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [
          Colors.white,
          HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), satPaint);

    // Black to transparent (vertical = brightness)
    final valPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          Colors.transparent,
          Colors.black,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), valPaint);
  }

  @override
  bool shouldRepaint(covariant _SBPainter oldDelegate) => oldDelegate.hue != hue;
}
