import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/trivia.dart';
import '../../../providers/trivia_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';

/// Vista de mazo de trivia: limpia, moderna, sin bordes ni degradados toscos.
class TriviaDeck extends StatefulWidget {
  final List<TriviaQuestion> questions;
  final TriviaProvider provider;
  final ThemeSet theme;
  final VoidCallback onQuestionAnswered;

  const TriviaDeck({
    super.key,
    required this.questions,
    required this.provider,
    required this.theme,
    required this.onQuestionAnswered,
  });

  @override
  State<TriviaDeck> createState() => _TriviaDeckState();
}

class _TriviaDeckState extends State<TriviaDeck> {
  int _index = 0;
  int _activeTab = 0; // 0 = Mi respuesta, 1 = Mi predicción
  String? _answer;
  String? _guess;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initQuestionState();
  }

  @override
  void didUpdateWidget(covariant TriviaDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.questions.length) {
      _index = (widget.questions.length - 1).clamp(0, 99999);
      _initQuestionState();
    }
  }

  void _initQuestionState() {
    if (widget.questions.isEmpty) return;
    final q = widget.questions[_index];
    final my = widget.provider.myAnswerToday;
    if (my != null && my.questionId == q.id) {
      _answer = my.answer;
      _guess = my.guess;
    } else {
      _answer = null;
      _guess = null;
      _activeTab = 0;
    }
  }

  void _changeQuestion(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.questions.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = newIndex;
      _initQuestionState();
    });
  }

  void _submit() {
    if (widget.questions.isEmpty) return;
    final q = widget.questions[_index];
    final ans = _answer;
    final gss = _guess;
    if (ans == null || gss == null || _saving) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    widget.provider
        .submit(questionId: q.id!, answer: ans, guess: gss)
        .then((ok) {
      if (mounted) {
        setState(() {
          _saving = false;
          _answer = null;
          _guess = null;
          _activeTab = 0;
        });
        widget.onQuestionAnswered();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const SizedBox.shrink();
    final q = widget.questions[_index.clamp(0, widget.questions.length - 1)];
    final t = widget.theme;
    final canSubmit = _answer != null && _guess != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navegación entre preguntas
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TapTile(
                  onTap: _index > 0 ? () => _changeQuestion(_index - 1) : () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _index > 0 ? const Color(0xFF222222) : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: _index > 0 ? Colors.white : Colors.white24,
                      size: 24,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_index + 1} de ${widget.questions.length}',
                    style: GoogleFonts.bangers(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                TapTile(
                  onTap: _index < widget.questions.length - 1 ? () => _changeQuestion(_index + 1) : () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _index < widget.questions.length - 1
                          ? const Color(0xFF222222)
                          : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: _index < widget.questions.length - 1 ? Colors.white : Colors.white24,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta principal interactiva
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -250 && _index < widget.questions.length - 1) {
                _changeQuestion(_index + 1);
              } else if (v > 250 && _index > 0) {
                _changeQuestion(_index - 1);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pregunta
                  Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(
                      fontSize: 22,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Selector de pasos / pestañas (Mi respuesta vs Mi predicción)
                  Row(
                    children: [
                      Expanded(
                        child: TapTile(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeTab = 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? t.a : const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _answer != null ? Icons.check_circle_rounded : Icons.person_rounded,
                                  size: 16,
                                  color: _activeTab == 0 ? Colors.white : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tu respuesta',
                                  style: GoogleFonts.bangers(
                                    fontSize: 13,
                                    color: _activeTab == 0 ? Colors.white : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TapTile(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeTab = 1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? const Color(0xFF00D4FF) : const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _guess != null ? Icons.check_circle_rounded : Icons.favorite_rounded,
                                  size: 16,
                                  color: _activeTab == 1 ? const Color(0xFF0A0A0A) : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Predicción',
                                  style: GoogleFonts.bangers(
                                    fontSize: 13,
                                    color: _activeTab == 1 ? const Color(0xFF0A0A0A) : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Lista de opciones para la pestaña activa
                  for (final option in q.options) ...[
                    _buildOptionTile(
                      option: option,
                      isSelected: _activeTab == 0 ? _answer == option : _guess == option,
                      selectedColor: _activeTab == 0 ? t.a : const Color(0xFF00D4FF),
                      textColor: _activeTab == 0 ? Colors.white : const Color(0xFF0A0A0A),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (_activeTab == 0) {
                          setState(() => _answer = option);
                          if (_guess == null) {
                            Future.delayed(const Duration(milliseconds: 220), () {
                              if (mounted && _guess == null) {
                                setState(() => _activeTab = 1);
                              }
                            });
                          }
                        } else {
                          setState(() => _guess = option);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 12),

                  // Botón confirmar
                  TapTile(
                    onTap: canSubmit && !_saving ? _submit : () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: canSubmit && !_saving ? const Color(0xFF39FF14) : const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _saving
                              ? 'GUARDANDO...'
                              : (canSubmit
                                  ? 'CONFIRMAR RESPUESTA'
                                  : (_answer == null ? 'Elegí tu respuesta' : 'Elegí tu predicción')),
                          style: GoogleFonts.bangers(
                            fontSize: 16,
                            color: canSubmit && !_saving ? const Color(0xFF0A0A0A) : Colors.white38,
                            letterSpacing: 1,
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
      ),
    );
  }

  Widget _buildOptionTile({
    required String option,
    required bool isSelected,
    required Color selectedColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return TapTile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.bangers(
                  fontSize: 15,
                  color: isSelected ? textColor : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: textColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
