import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Selector de color completo para el Pizarrón:
/// 1. Cuadrado 2D de Saturación y Brillo (permite cualquier color con cualquier saturación).
/// 2. Barra de Tono (Hue) + Botón Cuentagotas (para muestrear colores presentes de la nota o tablero).
/// 3. Fila inferior con los últimos colores usados (mínimo 5).
class PizarronColorPickerArea extends StatefulWidget {
  final String currentColorHex;
  final ValueChanged<String> onColorChanged;
  final List<String> sampledColors;

  const PizarronColorPickerArea({
    super.key,
    required this.currentColorHex,
    required this.onColorChanged,
    this.sampledColors = const [],
  });

  @override
  State<PizarronColorPickerArea> createState() => _PizarronColorPickerAreaState();
}

class _PizarronColorPickerAreaState extends State<PizarronColorPickerArea> {
  late double _hue;
  late double _saturation;
  late double _value;
  bool _eyedropperOpen = false;

  @override
  void initState() {
    super.initState();
    _syncFromHex(widget.currentColorHex);
  }

  @override
  void didUpdateWidget(covariant PizarronColorPickerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColorHex.toUpperCase() !=
        widget.currentColorHex.toUpperCase()) {
      _syncFromHex(widget.currentColorHex);
    }
  }

  void _syncFromHex(String hex) {
    final color = PizarronPalette.parseHex(hex);
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _notifyColor() {
    final color = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    final hex = PizarronPalette.toHex(color);
    PizarronPalette.addRecentColor(hex);
    widget.onColorChanged(hex);
  }

  void _updateSatValFromOffset(Offset local, Size size) {
    setState(() {
      _saturation = (local.dx / size.width).clamp(0.0, 1.0);
      _value = (1.0 - (local.dy / size.height)).clamp(0.0, 1.0);
    });
    _notifyColor();
  }

  void _updateHueFromOffset(Offset local, double width) {
    setState(() {
      _hue = ((local.dx / width) * 360.0).clamp(0.0, 360.0);
    });
    _notifyColor();
  }

  void _selectHex(String hex) {
    setState(() {
      _syncFromHex(hex);
    });
    final clean = hex.trim().toUpperCase();
    PizarronPalette.addRecentColor(clean);
    widget.onColorChanged(clean);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor =
        HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cuadrado de Saturación (horizontal) y Brillo (vertical)
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              const boxHeight = 110.0;
              final thumbX =
                  (_saturation * boxWidth).clamp(8.0, boxWidth - 8.0);
              final thumbY =
                  ((1.0 - _value) * boxHeight).clamp(8.0, boxHeight - 8.0);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) =>
                    _updateSatValFromOffset(d.localPosition, Size(boxWidth, boxHeight)),
                onPanUpdate: (d) =>
                    _updateSatValFromOffset(d.localPosition, Size(boxWidth, boxHeight)),
                child: SizedBox(
                  width: boxWidth,
                  height: boxHeight,
                  child: Stack(
                    children: [
                      // Fondo del cuadrado HSV
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SaturationValuePainter(hue: _hue),
                        ),
                      ),
                      // Indicador circular de la saturación/brillo actual
                      Positioned(
                        left: thumbX - 9,
                        top: thumbY - 9,
                        child: IgnorePointer(
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentColor,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x77000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 2. Barra de Tono (Hue) + Botón de Cuentagotas
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sliderWidth = constraints.maxWidth;
                    const sliderHeight = 22.0;
                    final thumbX =
                        ((_hue / 360.0) * sliderWidth).clamp(7.0, sliderWidth - 7.0);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) =>
                          _updateHueFromOffset(d.localPosition, sliderWidth),
                      onPanUpdate: (d) =>
                          _updateHueFromOffset(d.localPosition, sliderWidth),
                      child: SizedBox(
                        width: sliderWidth,
                        height: sliderHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF0000),
                                      Color(0xFFFFFF00),
                                      Color(0xFF00FF00),
                                      Color(0xFF00FFFF),
                                      Color(0xFF0000FF),
                                      Color(0xFFFF00FF),
                                      Color(0xFFFF0000),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Indicador del tono actual
                            Positioned(
                              left: thumbX - 7,
                              top: 2,
                              child: IgnorePointer(
                                child: Container(
                                  width: 14,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0)
                                        .toColor(),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: Colors.white, width: 2.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón Cuentagotas
            GestureDetector(
              onTap: () {
                setState(() {
                  _eyedropperOpen = !_eyedropperOpen;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _eyedropperOpen
                      ? const Color(0xFF2EE50F)
                      : const Color(0xFF252C40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.colorize_rounded,
                  size: 18,
                  color: _eyedropperOpen
                      ? const Color(0xFF141820)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),

        // Cuentagotas desplegado: Muestrario de colores presentes en la nota y tablero
        if (_eyedropperOpen && widget.sampledColors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF252C40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final hex in widget.sampledColors)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () {
                          _selectHex(hex);
                          setState(() => _eyedropperOpen = false);
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: PizarronPalette.parseHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),

        // 3. Fila con los últimos colores usados (mínimo 5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final hex in PizarronPalette.recentColors.take(6))
              GestureDetector(
                onTap: () => _selectHex(hex),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: PizarronPalette.parseHex(hex),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: widget.currentColorHex.toUpperCase() == hex.toUpperCase()
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: PizarronPalette.parseHex(hex)
                                      .computeLuminance() >
                                  0.5
                              ? const Color(0xFF141820)
                              : Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  final double hue;

  _SaturationValuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // 1. Color base según el tono
    canvas.drawRect(rect, Paint()..color = baseColor);

    // 2. Gradiente horizontal blanco a transparente (Saturación)
    final whiteShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Color(0x00FFFFFF)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = whiteShader);

    // 3. Gradiente vertical transparente a negro (Brillo/Valor)
    final blackShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Colors.black],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = blackShader);
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}
