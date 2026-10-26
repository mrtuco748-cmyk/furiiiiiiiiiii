import 'package:flutter/material.dart';

/// Selector rápido de grosor de borde y color para viñeta de cómic en 1 toque.
class ComicPanelQuickBorderRow extends StatelessWidget {
  final double currentBorderWidth;
  final Color currentBorderColor;
  final void Function(double width, Color color) onSelect;

  const ComicPanelQuickBorderRow({
    super.key,
    required this.currentBorderWidth,
    required this.currentBorderColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip('Sin borde', 0.0),
          const SizedBox(width: 6),
          _buildChip('Fino', 2.0),
          const SizedBox(width: 6),
          _buildChip('Normal', 4.0),
          const SizedBox(width: 6),
          _buildChip('Shonen', 8.0),
          const SizedBox(width: 12),
          _buildDot(const Color(0xFF111111)),
          const SizedBox(width: 6),
          _buildDot(const Color(0xFFFFFFFF)),
          const SizedBox(width: 6),
          _buildDot(const Color(0xFFFFDE59)),
          const SizedBox(width: 6),
          _buildDot(const Color(0xFFFF453A)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, double width) {
    final isSelected = (currentBorderWidth - width).abs() < 0.5;
    return GestureDetector(
      onTap: () => onSelect(width, currentBorderColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    final isSelected = currentBorderColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => onSelect(currentBorderWidth, color),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 12,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}
