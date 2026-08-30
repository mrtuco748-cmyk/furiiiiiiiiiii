import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/trivia.dart';
import '../../providers/trivia_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/tap_tile.dart';

/// Trivia de pareja estilo "Nosotros": mazo de preguntas sin responder,
/// se deslizan para navegar. Al responder, pasan al historial.
class TriviaScreen extends StatefulWidget {
  final AppMode mode;
  const TriviaScreen({super.key, required this.mode});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  bool _showAdd = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TriviaProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Consumer<TriviaProvider>(
      builder: (context, pv, _) {
        final unanswered = pv.unansweredQuestions;
        final answered = pv.answeredQuestions;

        if (_showAdd) {
          return _AddQuestionScreen(
            theme: t,
            provider: pv,
            onClose: () => setState(() => _showAdd = false),
          );
        }
        if (_showHistory) {
          return _HistoryScreen(
            theme: t,
            provider: pv,
            onClose: () => setState(() => _showHistory = false),
          );
        }

        if (pv.loading) {
          return _LoadingScreen(theme: t);
        }
        if (pv.hasError) {
          return _ErrorScreen(
            theme: t,
            message: pv.error ?? 'Error al cargar',
            onRetry: () => pv.load(),
          );
        }

        if (unanswered.isEmpty && answered.isEmpty) {
          return _EmptyScreen(theme: t, onAdd: () => setState(() => _showAdd = true));
        }

        return Stack(
          children: [
            // Fondo
            Container(color: const Color(0xFF0A0A0A)),
            // Mazo de preguntas sin responder
            if (unanswered.isNotEmpty)
              TriviaDeck(
                questions: unanswered,
                provider: pv,
                theme: t,
                onQuestionAnswered: () {
                  // La UI se actualiza automáticamente via provider
                },
              ),
            // Botones de acción flotantes
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.add,
                    label: 'Agregar',
                    color: const Color(0xFF9D00FF),
                    onTap: () => setState(() => _showAdd = true),
                  ),
                  _ActionButton(
                    icon: Icons.history,
                    label: 'Historial',
                    color: const Color(0xFF9D00FF),
                    onTap: answered.isEmpty ? null : () => setState(() => _showHistory = true),
                  ),
                ],
              ),
            ),
            // Indicador de puntuación arriba
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _Scoreboard(theme: t, provider: pv),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final ThemeSet theme;
  const _LoadingScreen({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF9D00FF), strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Cargando trivia...',
                style: GoogleFonts.bangers(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final ThemeSet theme;
  final String message;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.theme, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              TapTile(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D00FF),
                    border: Border.all(color: const Color(0xFF9D00FF), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Reintentar',
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyScreen extends StatelessWidget {
  final ThemeSet theme;
  final VoidCallback onAdd;
  const _EmptyScreen({required this.theme, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz, color: const Color(0xFF9D00FF), size: 64),
              const SizedBox(height: 16),
              Text('¡No hay preguntas!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              Text('Agregá la primera para empezar a jugar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              TapTile(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D00FF),
                    border: Border.all(color: const Color(0xFF9D00FF), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Agregar pregunta',
                          style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
                    ],
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

class _Scoreboard extends StatelessWidget {
  final ThemeSet theme;
  final TriviaProvider provider;
  const _Scoreboard({required this.theme, required this.provider});

  @override
  Widget build(BuildContext context) {
    final myScore = provider.myScore;
    final partnerScore = provider.partnerScore;
    final iWin = myScore >= partnerScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF9D00FF), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text('VOS', style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
              Text('$myScore',
                  style: GoogleFonts.bangers(
                      color: iWin ? const Color(0xFF39FF14) : Colors.white, fontSize: 24)),
            ],
          ),
          const SizedBox(width: 20),
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 20),
          Column(
            children: [
              Text('PAREJA', style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
              Text('$partnerScore',
                  style: GoogleFonts.bangers(
                      color: !iWin ? const Color(0xFF39FF14) : Colors.white, fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return TapTile(
      onTap: onTap ?? () {},
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? color : const Color(0xFF333333),
            border: Border.all(color: enabled ? color : const Color(0xFF333333), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? Colors.white : Colors.white54, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.bangers(
                      color: enabled ? Colors.white : Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// Pantalla para agregar pregunta
class _AddQuestionScreen extends StatefulWidget {
  final ThemeSet theme;
  final TriviaProvider provider;
  final VoidCallback onClose;
  const _AddQuestionScreen({
    required this.theme,
    required this.provider,
    required this.onClose,
  });

  @override
  State<_AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<_AddQuestionScreen> {
  final _qCtrl = TextEditingController();
  final List<TextEditingController> _optCtrls = List.generate(4, (_) => TextEditingController());
  bool _saving = false;

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _optCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _opts => _optCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
  bool get _canSave => _qCtrl.text.trim().isNotEmpty && _opts.length >= 2 && !_saving;

  InputDecoration _dec(ThemeSet t, String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.bangers(color: t.c, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF333333), width: 2), borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF333333), width: 2), borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: t.c, width: 2), borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final ok = await widget.provider.addQuestion(question: _qCtrl.text.trim(), options: _opts);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppFeedback.saved(context, 'Pregunta agregada');
      widget.onClose();
    } else {
      AppFeedback.error(context, 'No se pudo agregar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: TapTile(
          onTap: widget.onClose,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9D00FF),
              border: Border.all(color: const Color(0xFF9D00FF), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
        title: Text('Nueva pregunta', style: GoogleFonts.bangers(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _qCtrl,
            maxLines: 3,
            maxLength: 200,
            autocorrect: false,
            enableSuggestions: false,
            decoration: _dec(t, 'Pregunta'),
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text('Opciones (mínimo 2)', style: GoogleFonts.bangers(color: t.c, fontSize: 14)),
          const SizedBox(height: 10),
          for (var i = 0; i < 4; i++) ...[
            TextField(
              controller: _optCtrls[i],
              maxLength: 60,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _dec(t, 'Opción ${i + 1}'),
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          TapTile(
            onTap: _canSave ? _save : () {},
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _canSave ? t.c : const Color(0xFF111111),
                border: Border.all(color: _canSave ? t.c : const Color(0xFF111111), width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.check, color: _canSave ? Colors.white : const Color(0xFF888888), size: 24),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Pantalla de historial
class _HistoryScreen extends StatefulWidget {
  final ThemeSet theme;
  final TriviaProvider provider;
  final VoidCallback onClose;
  const _HistoryScreen({
    required this.theme,
    required this.provider,
    required this.onClose,
  });

  @override
  State<_HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<_HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final pv = widget.provider;
    final t = widget.theme;
    final myAnswers = pv.answers.where((a) => a.userId == pv.myId).toList();
    myAnswers.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

    // Agrupar por pregunta para mostrar respuesta de la pareja
    final partnerAnswers = <int, TriviaAnswer>{};
    for (final a in pv.answers) {
      if (a.userId == pv.partnerId && a.answer.isNotEmpty) {
        partnerAnswers[a.questionId] = a;
      }
    }

    final questionsMap = <int, TriviaQuestion>{};
    for (final q in pv.questions) {
      if (q.id != null) questionsMap[q.id!] = q;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: TapTile(
          onTap: widget.onClose,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9D00FF),
              border: Border.all(color: const Color(0xFF9D00FF), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
        title: Text('Historial', style: GoogleFonts.bangers(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: myAnswers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: Colors.white54, size: 56),
                  const SizedBox(height: 16),
                  Text('Sin respuestas aún',
                      style: GoogleFonts.bangers(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Respondé preguntas para ver el historial',
                      style: GoogleFonts.bangers(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myAnswers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _HistoryItem(
                theme: t,
                myAnswer: myAnswers[i],
                question: questionsMap[myAnswers[i].questionId],
                partnerAnswer: partnerAnswers[myAnswers[i].questionId],
              ),
            ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ThemeSet theme;
  final TriviaAnswer myAnswer;
  final TriviaQuestion? question;
  final TriviaAnswer? partnerAnswer;
  const _HistoryItem({
    required this.theme,
    required this.myAnswer,
    this.question,
    this.partnerAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final guessed = myAnswer.guess;
    final real = partnerAnswer?.answer;
    final hit = real != null && guessed != null && real == guessed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF333333), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pregunta
          Text(question?.question ?? 'Pregunta',
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Mi respuesta
          _HistoryRow(
            label: 'Tu respuesta',
            value: myAnswer.answer,
            color: const Color(0xFF9D00FF),
          ),
          const SizedBox(height: 6),
          // Mi predicción
          _HistoryRow(
            label: 'Tu predicción',
            value: guessed ?? '—',
            color: const Color(0xFF00D4FF),
          ),
          const SizedBox(height: 6),
          // Respuesta de la pareja
          _HistoryRow(
            label: 'Respuesta de tu pareja',
            value: real ?? 'Sin responder',
            color: const Color(0xFFFF1493),
          ),
          if (guessed != null && real != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hit ? const Color(0xFF39FF14) : const Color(0xFFFF0000),
                border: Border.all(color: hit ? const Color(0xFF39FF14) : const Color(0xFFFF0000), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(hit ? Icons.check_circle : Icons.cancel,
                      color: hit ? const Color(0xFF0A0A0A) : Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(hit ? '¡Acertaste!' : 'No acertaste',
                      style: GoogleFonts.bangers(
                          color: hit ? const Color(0xFF0A0A0A) : Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
          // Fecha
          if (myAnswer.date != null) ...[
            const SizedBox(height: 8),
            Text('Respondido el ${_formatDate(myAnswer.date!)}',
                style: GoogleFonts.bangers(color: Colors.white38, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HistoryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.bangers(color: color, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
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