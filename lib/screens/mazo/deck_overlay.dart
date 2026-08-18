import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/deck_card.dart';
import '../../providers/deck_provider.dart';
import 'create_deck_card_modal.dart';
import 'deck_history_sheet.dart';
import 'deck_style.dart';

class DeckOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const DeckOverlay({super.key, required this.onClose});

  @override
  State<DeckOverlay> createState() => _DeckOverlayState();
}

class _DeckOverlayState extends State<DeckOverlay>
    with SingleTickerProviderStateMixin {
  static const _threshold = 70.0;
  static const _bg = Color(0xFF0A0A0A);

  Offset _drag = Offset.zero;
  bool _swiping = false;
  Offset _exitFrom = Offset.zero;
  Offset _exitTo = Offset.zero;
  double _exitRot = 0;
  DeckCard? _reswipeCard;

  late final AnimationController _exitCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void dispose() {
    _exitCtrl.dispose();
    super.dispose();
  }

  DeckCard? _current(List<DeckCard> pending) {
    if (_reswipeCard != null) return _reswipeCard;
    return pending.isEmpty ? null : pending.first;
  }

  void _swipeOut(DeckProvider pv, DeckCard card, String reaction) {
    final style = DeckReactionStyle.of(reaction);
    _exitFrom = _drag;
    _exitTo = Offset(style.dirX * 1200, style.dirY * 1200);
    _exitRot = style.dirX * 0.4;
    setState(() => _swiping = true);
    _exitCtrl.forward(from: 0).whenComplete(() {
      _exitCtrl.reset();
      _drag = Offset.zero;
      _reswipeCard = null;
      _swiping = false;
      pv.react(card, reaction);
      if (mounted) setState(() {});
    });
  }

  void _snapBack() {
    _exitFrom = _drag;
    _exitTo = Offset.zero;
    _exitRot = 0;
    setState(() => _swiping = true);
    _exitCtrl.forward(from: 0).whenComplete(() {
      _exitCtrl.reset();
      _drag = Offset.zero;
      _swiping = false;
      if (mounted) setState(() {});
    });
  }

  void _onPanEnd(DeckProvider pv, DeckCard card) {
    final dx = _drag.dx.abs();
    final dy = _drag.dy.abs();
    if (dx < _threshold && dy < _threshold) {
      _snapBack();
      return;
    }
    if (dx > dy) {
      _swipeOut(pv, card, _drag.dx > 0
          ? DeckReaction.encanta
          : DeckReaction.noMeGusta);
    } else {
      _swipeOut(pv, card,
          _drag.dy > 0 ? DeckReaction.meGusta : DeckReaction.meh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: Consumer<DeckProvider>(
        builder: (context, pv, _) {
          final pending = pv.pendingFor(AppState.myId);
          final current = _current(pending);
          return Stack(children: [
            Positioned.fill(child: Container(color: _bg)),
            if (pv.loading && pv.cards.isEmpty)
              const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFDE59),
                    strokeWidth: 4,
                  ),
                ),
              )
            else if (pv.hasError && pv.cards.isEmpty)
              _errorView(pv)
            else if (current == null)
              _emptyView(pv)
            else
              _cardsArea(pv, current, pending),
            if (!_swiping)
              _minimalHeader(pv),
          ]);
        },
      ),
    );
  }

  Widget _minimalHeader(DeckProvider pv) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Row(children: [
        GestureDetector(
          onTap: () => showDeckHistorySheet(context,
              onReswipe: (card) => setState(() => _reswipeCard = card)),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF9D00FF),
              border: Border.all(color: const Color(0xFF9D00FF), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history,
                color: Color(0xFF1A1A1A), size: 18),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => showCreateDeckCardModal(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF39FF14),
              border: Border.all(color: const Color(0xFF39FF14), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add,
                color: Color(0xFF1A1A1A), size: 20),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              border: Border.all(color: const Color(0xFFFF0000), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close,
                color: Color(0xFF1A1A1A), size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _cardsArea(
      DeckProvider pv, DeckCard current, List<DeckCard> pending) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final cardW = (w * 0.92).clamp(280.0, 600.0);
        final cardH = (h * 0.82).clamp(360.0, 800.0);
        final stack = <Widget>[];

        if (_reswipeCard != null) {
          stack.add(_dragCard(pv, current, cardW, cardH));
        } else {
          final next = pending.length > 1 ? pending[1] : null;
          final third = pending.length > 2 ? pending[2] : null;
          if (third != null) {
            stack.add(Positioned.fill(
              child: Center(
                child: _cardBody(third, cardW, cardH,
                    scale: 0.88, offsetY: 44, opacity: 0.55),
              ),
            ));
          }
          if (next != null) {
            stack.add(Positioned.fill(
              child: Center(
                child: _cardBody(next, cardW, cardH,
                    scale: 0.94, offsetY: 22, opacity: 0.8),
              ),
            ));
          }
          stack.add(Positioned.fill(
            child: Center(child: _dragCard(pv, current, cardW, cardH)),
          ));
        }

        return Stack(children: [
          ...stack,
          if (_reswipeCard != null) _reswipeBanner(),
        ]);
      }),
    );
  }

  Widget _reswipeBanner() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF9D00FF),
            border: Border.all(color: const Color(0xFF9D00FF), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.swap_horiz,
                color: Color(0xFF1A1A1A), size: 18),
            const SizedBox(width: 6),
            Text('deslizá de nuevo',
                style: TextStyle(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 12,
                    fontFamily: 'monospace')),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _reswipeCard = null),
              child: const Icon(Icons.close,
                  color: Color(0xFF1A1A1A), size: 16),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dragCard(DeckProvider pv, DeckCard card, double w, double h) {
    final rotate = (_drag.dx / w).clamp(-1.0, 1.0) * 0.18;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _exitCtrl.stop(),
      onPanUpdate: (d) {
        if (_swiping) return;
        setState(() => _drag += d.delta);
      },
      onPanEnd: (_) => _onPanEnd(pv, card),
      child: AnimatedBuilder(
        animation: _exitCtrl,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_exitCtrl.value);
          final offset =
              _swiping ? Offset.lerp(_exitFrom, _exitTo, t)! : _drag;
          final rot = _swiping ? _exitRot * t : rotate;
          return Transform.translate(
            offset: offset,
            child: Transform.rotate(angle: rot, child: child),
          );
        },
        child: _cardBody(card, w, h, scale: 1, offsetY: 0, opacity: 1),
      ),
    );
  }

  Widget _cardBody(DeckCard card, double w, double h,
      {required double scale,
      required double offsetY,
      required double opacity}) {
    final style = DeckCategoryStyle.of(card.category);
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: w,
            height: h,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: style.color,
              border: Border.all(color: style.color, width: 5),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Text(card.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 22,
                      height: 1.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyView(DeckProvider pv) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🃏', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        const Text('No hay tarjetas para deslizar',
            style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontFamily: 'monospace')),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => showCreateDeckCardModal(context),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF39FF14),
              border: Border.all(color: const Color(0xFF39FF14), width: 4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.add,
                color: Color(0xFF1A1A1A), size: 34),
          ),
        ),
      ]),
    );
  }

  Widget _errorView(DeckProvider pv) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF5A0000),
          border: Border.all(color: const Color(0xFF5A0000), width: 3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No se pudieron cargar las tarjetas',
              style: TextStyle(
                  color: Color(0xFFFFCACA),
                  fontSize: 14,
                  fontFamily: 'monospace')),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => pv.load(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                border: Border.all(color: const Color(0xFFFF0000), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.refresh,
                  color: Color(0xFF1A1A1A), size: 26),
            ),
          ),
        ]),
      ),
    );
  }
}