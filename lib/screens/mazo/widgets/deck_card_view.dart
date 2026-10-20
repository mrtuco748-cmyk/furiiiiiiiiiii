import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/deck_card.dart';
import '../deck_style.dart';

/// Vista visual de una carta del mazo (con escala, opacidad, degradado y badge de reacción).
class DeckCardView extends StatelessWidget {
  final DeckCard card;
  final double width;
  final double height;
  final double scale;
  final double offsetY;
  final double opacity;
  final DeckReactionStyle? reactionStyle;

  const DeckCardView({
    super.key,
    required this.card,
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.offsetY = 0.0,
    this.opacity = 1.0,
    this.reactionStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style = DeckCategoryStyle.of(card.category);
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              Container(
                width: width,
                height: height,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      style.label,
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            card.content,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.bangers(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (reactionStyle != null)
                Positioned(
                  top: 36,
                  right: 36,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: reactionStyle!.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        reactionStyle!.label,
                        style: GoogleFonts.bangers(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
