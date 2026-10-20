import 'package:flutter/material.dart';

/// Barra horizontal de selección de Tono (Hue) y botón cuentagotas para el selector de color del Pizarrón.
class PizarronHueBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onHueChanged;
  final bool eyedropperOpen;
  final VoidCallback onToggleEyedropper;

  const PizarronHueBar({
    super.key,
    required this.hue,
    required this.onHueChanged,
    required this.eyedropperOpen,
    required this.onToggleEyedropper,
  });

  void _updateHueFromOffset(Offset local, double width) {
    final newHue = ((local.dx / width) * 360.0).clamp(0.0, 360.0);
    onHueChanged(newHue);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sliderWidth = constraints.maxWidth;
                const sliderHeight = 22.0;
                final thumbX =
                    ((hue / 360.0) * sliderWidth).clamp(7.0, sliderWidth - 7.0);

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
                        Positioned(
                          left: thumbX - 7,
                          top: 2,
                          child: IgnorePointer(
                            child: Container(
                              width: 14,
                              height: 18,
                              decoration: BoxDecoration(
                                color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0)
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
        GestureDetector(
          onTap: onToggleEyedropper,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: eyedropperOpen
                  ? const Color(0xFF2EE50F)
                  : const Color(0xFF252C40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.colorize_rounded,
              size: 18,
              color: eyedropperOpen
                  ? const Color(0xFF141820)
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
