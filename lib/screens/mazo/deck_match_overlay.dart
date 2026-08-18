import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/deck_card.dart';
import 'deck_style.dart';

class DeckMatchOverlay extends StatefulWidget {
  final DeckCard card;
  final VoidCallback onDone;
  const DeckMatchOverlay({
    super.key,
    required this.card,
    required this.onDone,
  });

  @override
  State<DeckMatchOverlay> createState() => _DeckMatchOverlayState();
}

class _DeckMatchOverlayState extends State<DeckMatchOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Confetti.launch(context, options: ConfettiOptions(
        particleCount: 70,
        spread: 90,
        startVelocity: 45,
        gravity: 0.85,
        decay: 0.93,
        x: 0.5,
        y: 0.4,
        colors: const [
          Color(0xFFFFDE59),
          Color(0xFF00F0FF),
          Color(0xFFFF5757),
          Color(0xFF00FF66),
          Color(0xFF7000FF),
          Color(0xFFFF66C4),
        ],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat = DeckCategoryStyle.of(widget.card.category);
    return Material(
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 10),
                Text('FURI!!',
                    style: GoogleFonts.bangers(
                        color: cat.color,
                        fontSize: 84,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4)),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cat.color,
                    border: Border.all(color: cat.color, width: 4),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    widget.card.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 18,
                        height: 1.4,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 26),
                GestureDetector(
                  onTap: widget.onDone,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14),
                      border: Border.all(color: const Color(0xFF39FF14),
                          width: 4),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Color(0xFF1A1A1A), size: 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
