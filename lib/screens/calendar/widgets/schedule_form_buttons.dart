import 'package:flutter/material.dart';
import '../../../widgets/tap_tile.dart';

const Color _c = Color(0xFF00D4FF);
const Color _dark = Color(0xFF0D0D0D);
const Color _cDeep = Color(0xFF003344);

class ScheduleBackButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const ScheduleBackButton({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: width * 0.02,
      top: height * 0.01,
      width: width * 0.13,
      height: height * 0.06,
      child: TapTile(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _c, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Icon(Icons.arrow_back, color: Color(0xFF0D0D0D), size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleSaveButton extends StatelessWidget {
  final double width;
  final double height;
  final bool saving;
  final VoidCallback onTap;

  const ScheduleSaveButton({
    super.key,
    required this.width,
    required this.height,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: width * 0.20,
      bottom: height * 0.04,
      width: width * 0.60,
      height: height * 0.08,
      child: TapTile(
        onTap: saving ? () {} : onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: saving ? _cDeep : _c,
              border: Border.all(color: saving ? _cDeep : _c, width: 5),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
              ],
            ),
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 3, color: _dark),
                    )
                  : const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 32),
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleDeleteButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const ScheduleDeleteButton({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: width * 0.06,
      top: height * 0.85,
      width: width * 0.13,
      height: width * 0.13,
      child: TapTile(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4A0000),
              border: Border.all(color: const Color(0xFF4A0000), width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Icon(Icons.delete, color: Colors.red, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
