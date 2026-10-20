import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF0D0D0D);
const _near = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);
const _white70 = Color(0xB3FFFFFF);

class ClassBoardWeekStrip extends StatelessWidget {
  final double width;
  final double height;
  final int selectedDay;
  final void Function(int day) onSelectDay;

  const ClassBoardWeekStrip({
    super.key,
    required this.width,
    required this.height,
    required this.selectedDay,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    const names = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    final stripH = height * 0.075;
    return Positioned(
      left: width * 0.03,
      top: height * 0.10,
      width: width * 0.94,
      height: stripH,
      child: Row(
        children: List.generate(7, (i) {
          final day = i + 1;
          final selected = day == selectedDay;
          final isToday = day == DateTime.now().weekday;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: TapTile(
                onTap: () => onSelectDay(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? _c : (isToday ? const Color(0xFF0E2A38) : _near),
                    border: Border.all(color: selected ? _c : (isToday ? _c : _cDeep), width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        names[i],
                        style: GoogleFonts.bangers(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: selected ? _dark : (isToday ? _c : _white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
