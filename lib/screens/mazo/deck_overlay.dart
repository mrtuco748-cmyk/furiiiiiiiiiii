import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/deck_card.dart';
import '../../providers/deck_provider.dart';
import 'create_deck_card_modal.dart';
import 'deck_history_sheet.dart';
import 'deck_style.dart';
import 'widgets/deck_card_view.dart';
import 'widgets/deck_feedback_views.dart';
import 'widgets/deck_header_actions.dart';

class DeckOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final String? category;
  const DeckOverlay({super.key, required this.onClose, this.category});

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
      _swipeOut(pv, card,
          _drag.dx > 0 ? DeckReaction.encanta : DeckReaction.noMeGusta);
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
          var pending = pv.pendingFor(AppState.myId);
          if (widget.category != null) {
            final filtered =
                pending.where((c) => c.category == widget.category).toList();
            if (filtered.isNotEmpty) pending = filtered;
          }
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
              DeckErrorView(onRetry: pv.load)
            else if (current == null)
              DeckEmptyView(onAdd: () => showCreateDeckCardModal(context))
            else
              _cardsArea(pv, current, pending),
            if (!_swiping) ...[
              DeckHeaderActions.closeButton(onTap: widget.onClose),
              if (current != null)
                DeckHeaderActions.historyButton(
                  onTap: () {
                    showDeckHistorySheet(context,
                        onReswipe: (card) =>
                            setState(() => _reswipeCard = card));
                  },
                ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _cardsArea(
      DeckProvider pv, DeckCard current, List<DeckCard> pending) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        const cardRatio = 0.714;
        final maxW = w * 0.78;
        final maxH = h * 0.9;
        double cardW = maxW;
        double cardH = cardW / cardRatio;
        if (cardH > maxH) {
          cardH = maxH;
          cardW = cardH * cardRatio;
        }
        final stack = <Widget>[];

        if (_reswipeCard != null) {
          stack.add(_dragCard(pv, current, cardW, cardH));
        } else {
          final next = pending.length > 1 ? pending[1] : null;
          final third = pending.length > 2 ? pending[2] : null;
          if (third != null) {
            stack.add(Positioned.fill(
              child: Center(
                child: DeckCardView(
                  card: third,
                  width: cardW,
                  height: cardH,
                  scale: 0.88,
                  offsetY: 44,
                  opacity: 0.55,
                ),
              ),
            ));
          }
          if (next != null) {
            stack.add(Positioned.fill(
              child: Center(
                child: DeckCardView(
                  card: next,
                  width: cardW,
                  height: cardH,
                  scale: 0.94,
                  offsetY: 22,
                  opacity: 0.8,
                ),
              ),
            ));
          }
          stack.add(Positioned.fill(
            child: Center(child: _dragCard(pv, current, cardW, cardH)),
          ));
        }

        return Stack(children: [
          ...stack,
          if (_reswipeCard != null)
            DeckHeaderActions.reswipeBanner(
              onDismiss: () => setState(() => _reswipeCard = null),
            ),
        ]);
      }),
    );
  }

  Widget _dragCard(DeckProvider pv, DeckCard card, double w, double h) {
    final rotate = (_drag.dx / w).clamp(-1.0, 1.0) * 0.18;
    final reactionStyle = _reactionStyle(_drag);
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
        child: DeckCardView(
          card: card,
          width: w,
          height: h,
          scale: 1,
          offsetY: 0,
          opacity: 1,
          reactionStyle: reactionStyle,
        ),
      ),
    );
  }

  DeckReactionStyle? _reactionStyle(Offset drag) {
    final dx = drag.dx.abs();
    final dy = drag.dy.abs();
    if (dx < 26 && dy < 26) return null;
    if (dx > dy) {
      return DeckReactionStyle.of(
          drag.dx > 0 ? DeckReaction.encanta : DeckReaction.noMeGusta);
    }
    return DeckReactionStyle.of(
        drag.dy > 0 ? DeckReaction.meGusta : DeckReaction.meh);
  }
}
