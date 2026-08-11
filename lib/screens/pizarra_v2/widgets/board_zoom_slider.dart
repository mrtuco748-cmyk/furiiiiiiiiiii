import 'package:flutter/material.dart';

class BoardZoomSlider extends StatelessWidget {
  final TransformationController transformController;

  const BoardZoomSlider({super.key, required this.transformController});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        ),
        child: ValueListenableBuilder<Matrix4>(
          valueListenable: transformController,
          builder: (context, matrix, _) {
            final scale = matrix.getMaxScaleOnAxis();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _zoomBy(matrix, scale, -0.25),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Slider(
                    value: scale.clamp(0.1, 5.0),
                    min: 0.1,
                    max: 5.0,
                    activeColor: const Color(0xFF4FC3F7),
                    inactiveColor: const Color(0xFF333333),
                    onChanged: scale == 0 ? null : (v) => _zoomTo(matrix, v),
                  ),
                ),
                GestureDetector(
                  onTap: () => _zoomBy(matrix, scale, 0.25),
                  child: const Icon(
                    Icons.add_circle,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _zoomTo(Matrix4 matrix, double target) {
    if (!target.isFinite || target <= 0) return;
    final m = Matrix4.copy(matrix);
    final scale = m.getMaxScaleOnAxis();
    final s = target / scale;
    final scaleMatrix = Matrix4.diagonal3Values(s, s, 1.0);
    transformController.value = m.multiplied(scaleMatrix);
  }

  void _zoomBy(Matrix4 matrix, double current, double delta) {
    _zoomTo(matrix, (current + delta).clamp(0.1, 5.0));
  }
}