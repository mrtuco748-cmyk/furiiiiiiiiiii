import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/trivia.dart';
import '../../../providers/trivia_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';

/// Mazo de preguntas tipo Tinder: cards apiladas, swipe para navegar
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

class _TriviaDeckState extends State<TriviaDeck> with SingleTickerProviderStateMixin {
  int _index = 0;
  String? _answer;
  String? _guess;
  bool _saving = false;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0;
  bool _isDragging = false;

  static const double _cardW = 320;
  static const double _cardH = 480;
  static const double _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  TriviaQuestion get _currentQuestion => widget.questions[_index];

  void _submit() {
    final q = _currentQuestion;
    final ans = _answer;
    final gss = _guess;
    if (ans == null || gss == null || _saving) return;
    setState(() => _saving = true);
    widget.provider
        .submit(questionId: q.id!, answer: ans, guess: gss)
        .whenComplete(() {
      if (mounted) {
        setState(() {
          _saving = false;
          _answer = null;
          _guess = null;
        });
        widget.onQuestionAnswered();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta ?? 0;
      // Limitar el arrastre a un rango razonable
      _dragOffset = _dragOffset.clamp(-_cardW * 0.8, _cardW * 0.8);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldSwipeNext = _dragOffset < -_swipeThreshold || velocity < -500;
    final shouldSwipePrev = _dragOffset > _swipeThreshold || velocity > 500;

    if (shouldSwipeNext && _index < widget.questions.length - 1) {
      _animateSwipe(direction: 1); // siguiente (izquierda)
    } else if (shouldSwipePrev && _index > 0) {
      _animateSwipe(direction: -1); // anterior (derecha)
    } else {
      // Volver a posición original
      _animateReturn();
    }
  }

  void _animateSwipe({required int direction}) {
    // direction: 1 = siguiente (sale a la izquierda), -1 = anterior (sale a la derecha)
    final exitOffset = direction == 1 ? -_cardW * 1.2 : _cardW * 1.2;
    final enterOffset = direction == 1 ? _cardW * 1.2 : -_cardW * 1.2;

    _animController.reset();
    _slideAnimation = Tween<double>(begin: _dragOffset, end: exitOffset).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward().then((_) {
      if (mounted) {
        setState(() {
          _index += direction;
          _answer = null;
          _guess = null;
          _dragOffset = enterOffset;
        });
        // Animar entrada de la nueva carta
        _slideAnimation = Tween<double>(begin: enterOffset, end: 0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
        _animController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _dragOffset = 0;
              _isDragging = false;
            });
          }
        });
      }
    });
  }

  void _animateReturn() {
    _animController.reset();
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward().then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
          _isDragging = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _animateReturn,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Card siguiente (entrando/saliendo)
                if (_index + 1 < total && (_isDragging || _animController.isAnimating))
                  _cardShell(
                    1,
                    offsetX: _cardW + _dragOffset * 0.3,
                    offsetY: -8.0,
                    scale: 0.96,
                    opacity: 0.6,
                    child: _frontCard(widget.questions[_index + 1]),
                  ),
                // Card anterior (entrando/saliendo)
                if (_index > 0 && (_isDragging || _animController.isAnimating))
                  _cardShell(
                    -1,
                    offsetX: -_cardW + _dragOffset * 0.3,
                    offsetY: -8.0,
                    scale: 0.96,
                    opacity: 0.6,
                    child: _frontCard(widget.questions[_index - 1]),
                  ),
                // Cards de atrás (efecto mazo estático)
                for (var d = 2; d >= 1; d--)
                  if (_index + d < total && !_isDragging && !_animController.isAnimating)
                    _cardShell(d, offsetY: -8.0 * d, scale: 1.0 - 0.04 * d),
                // Card frontal (la que se arrastra)
                if (_index < total)
                  Transform.translate(
                    offset: Offset(_slideAnimation.value + (_isDragging ? _dragOffset : 0), 0),
                    child: _cardShell(0, child: _frontCard(_currentQuestion)),
                  ),
                // Indicador de posición
                if (total > 1)
                  Positioned(
                    bottom: -60,
                    child: Text('${_index + 1} / $total  ·  deslizá',
                        style: GoogleFonts.bangers(fontSize: 13, color: Colors.white38)),
                  ),
                // Hint visual durante el drag
                if (_isDragging && _dragOffset.abs() > 20)
                  _SwipeHint(offset: _dragOffset, threshold: _swipeThreshold, cardWidth: _cardW),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardShell(
    int depth, {
    double? offsetX,
    double? offsetY,
    double? scale,
    double? opacity,
    Widget? child,
  }) {
    return Transform.translate(
      offset: Offset(offsetX ?? 0, offsetY ?? 0),
      child: Transform.scale(
        scale: scale ?? 1,
        child: Opacity(
          opacity: opacity ?? (depth == 0 ? 1 : 0.6 - depth.abs() * 0.08),
          child: Container(
            width: _cardW,
            height: _cardH,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9D00FF), Color(0xFF7000FF), Color(0xFFB23BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9D00FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _frontCard(TriviaQuestion q) {
    final my = widget.provider.myAnswerToday;
    final myAnswerForThis = (my != null && my.questionId == q.id) ? my : null;
    final shownAnswer = _answer ?? myAnswerForThis?.answer;
    final shownGuess = _guess ?? myAnswerForThis?.guess;
    final canSave = shownAnswer != null && shownGuess != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Cuánto conocés a tu pareja?',
            textAlign: TextAlign.center,
            style: GoogleFonts.bangers(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(q.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 20, height: 1.4, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        // Tu respuesta
        Text('Tu respuesta', style: GoogleFonts.bangers(color: widget.theme.c, fontSize: 13)),
        const SizedBox(height: 8),
        _OptionChips(options: q.options, selected: shownAnswer, onTap: (o) => setState(() => _answer = o)),
        const SizedBox(height: 16),
        // Predicción
        Text('Predicción: ¿qué responderá tu pareja?', style: GoogleFonts.bangers(color: widget.theme.c, fontSize: 13)),
        const SizedBox(height: 8),
        _OptionChips(options: q.options, selected: shownGuess, onTap: (o) => setState(() => _guess = o)),
        const SizedBox(height: 20),
        // Botón confirmar
        TapTile(
          onTap: canSave && !_saving ? _submit : () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: canSave && !_saving ? const Color(0xFF39FF14) : const Color(0xFF2A2A2A),
              border: Border.all(
                  color: canSave && !_saving ? const Color(0xFF39FF14) : const Color(0xFF2A2A2A), width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(_saving ? 'Guardando...' : (myAnswerForThis != null ? 'Actualizar' : 'Confirmar'),
                  style: GoogleFonts.bangers(
                      color: canSave && !_saving ? const Color(0xFF0A0A0A) : Colors.white54, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hint visual durante el swipe
class _SwipeHint extends StatelessWidget {
  final double offset;
  final double threshold;
  final double cardWidth;
  const _SwipeHint({
    required this.offset,
    required this.threshold,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = offset < 0;
    final progress = (offset.abs() / threshold).clamp(0.0, 1.0);
    final color = isLeft ? const Color(0xFF39FF14) : const Color(0xFF00D4FF);
    final icon = isLeft ? Icons.arrow_forward_ios : Icons.arrow_back_ios;
    final label = isLeft ? 'Siguiente' : 'Anterior';

    return Positioned(
      top: cardWidth * 0.3,
      left: isLeft ? null : 20,
      right: isLeft ? 20 : null,
      child: AnimatedOpacity(
        opacity: progress,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF0A0A0A), size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.bangers(
                      color: const Color(0xFF0A0A0A), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onTap;
  const _OptionChips({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final o in options)
          TapTile(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(o);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected == o ? const Color(0xFF9D00FF) : const Color(0xFF1A1A1A),
                border: Border.all(
                    color: selected == o ? const Color(0xFF9D00FF) : const Color(0xFF333333), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(o,
                  style: GoogleFonts.bangers(
                      color: selected == o ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected == o ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
      ],
    );
  }
}
