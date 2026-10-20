import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitBounds;

  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitBounds,
  });

  Widget _buildMapBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMapBtn(
          icon: Icons.add,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 8),
        _buildMapBtn(
          icon: Icons.remove,
          onTap: onZoomOut,
        ),
        const SizedBox(height: 8),
        _buildMapBtn(
          icon: Icons.crop_free,
          onTap: onFitBounds,
        ),
      ],
    );
  }
}
