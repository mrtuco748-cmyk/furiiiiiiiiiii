import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SimpleColorWheel extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const SimpleColorWheel({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<SimpleColorWheel> createState() => _SimpleColorWheelState();
}

class _SimpleColorWheelState extends State<SimpleColorWheel> {
  late double _h, _s, _v;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _h = hsv.hue;
    _s = hsv.saturation;
    _v = hsv.value;
  }

  void _emit() =>
      widget.onColorChanged(HSVColor.fromAHSV(1, _h, _s, _v).toColor());

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: 24,
        child: LayoutBuilder(
          builder: (ctx, c) => GestureDetector(
            onPanDown: (d) {
              setState(() => _h = (d.localPosition.dx / c.maxWidth).clamp(0, 1) * 360);
              _emit();
            },
            onPanUpdate: (d) {
              setState(() => _h = (d.localPosition.dx / c.maxWidth).clamp(0, 1) * 360);
              _emit();
            },
            child: CustomPaint(
              size: Size(c.maxWidth, 24),
              painter: _HueBarPainter(),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 180,
        child: LayoutBuilder(
          builder: (ctx, c) => GestureDetector(
            onPanDown: (d) {
              _updateSB(d.localPosition, c.maxWidth, c.maxHeight);
              _emit();
            },
            onPanUpdate: (d) {
              _updateSB(d.localPosition, c.maxWidth, c.maxHeight);
              _emit();
            },
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _SBPainter(hue: _h),
            ),
          ),
        ),
      ),
    ]);
  }

  void _updateSB(Offset p, double w, double h) {
    setState(() {
      _s = (p.dx / w).clamp(0, 1);
      _v = 1 - (p.dy / h).clamp(0, 1);
    });
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
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 1, size.height),
        Paint()..color = HSVColor.fromAHSV(1, (x / size.width) * 360, 1, 1).toColor(),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HueBarPainter old) => false;
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          [Colors.white, HSVColor.fromAHSV(1, hue, 1, 1).toColor()],
        ),
    );

    // Black to transparent (vertical = brightness)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [Colors.transparent, Colors.black],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _SBPainter old) => old.hue != hue;
}
