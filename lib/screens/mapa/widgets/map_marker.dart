import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserMapMarker extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final bool isMe;

  const UserMapMarker({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                name,
                style: GoogleFonts.bangers(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: TrianglePointer(color: color),
        ),
      ],
    );
  }
}

class TrianglePointer extends CustomPainter {
  final Color color;
  const TrianglePointer({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePointer oldDelegate) =>
      oldDelegate.color != color;
}
