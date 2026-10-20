import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/swap_widget.dart';
import '../../../widgets/tap_tile.dart';
import '../helpers/nosotros_service.dart';
import '../models/nosotros_layout.dart';

const Color _purple = Color(0xFF7000FF);

class NosotrosButtonsGrid extends StatefulWidget {
  final NosotrosLayout layout;
  final ThemeSet theme;
  final AppMode mode;
  final String myId;
  final String partnerInitial;
  final List<Map<String, dynamic>> partnerRetos;
  final Map<String, dynamic>? partnerLetter;
  final List<Map<String, dynamic>> partnerMoods;
  final Map<String, dynamic>? latestQuestion;
  final bool showPreguntasSwap;
  final VoidCallback onPreguntasTap;
  final VoidCallback onEmocionesTap;

  const NosotrosButtonsGrid({
    super.key,
    required this.layout,
    required this.theme,
    required this.mode,
    required this.myId,
    required this.partnerInitial,
    required this.partnerRetos,
    required this.partnerLetter,
    required this.partnerMoods,
    required this.latestQuestion,
    required this.showPreguntasSwap,
    required this.onPreguntasTap,
    required this.onEmocionesTap,
  });

  @override
  State<NosotrosButtonsGrid> createState() => _NosotrosButtonsGridState();
}

class _NosotrosButtonsGridState extends State<NosotrosButtonsGrid> {
  Map<String, dynamic>? _retoSwapItem;
  String _retoSwapTitle = '';

  Widget _fillIcon(IconData icon, Color color) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)),
    );
  }

  Widget _btnBlock(double l, double t, double w, double h, Color bgColor, Widget child, VoidCallback? onTap) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)),
        child: child,
      ),
    );
    return Positioned(
      left: l,
      top: t,
      width: w,
      height: h,
      child: onTap != null
          ? TapTile(
              onTap: () {
                HapticFeedback.heavyImpact();
                onTap();
              },
              child: content,
            )
          : content,
    );
  }

  void _onRetosSwapShow() {
    final retos = widget.partnerRetos;
    if (retos.isEmpty) return;
    final random = retos[Random().nextInt(retos.length)];
    _retoSwapItem = random;
    _retoSwapTitle = random['title'] as String? ?? '';
    NosotrosService.markSeen(random, 'challenges', widget.myId);
    if (mounted) setState(() {});
  }

  Widget _buildRetosSwapContent() {
    if (_retoSwapItem == null) {
      return Center(child: Text('Sin retos', style: GoogleFonts.bangers(color: Colors.white70, fontSize: 13)));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_retoSwapTitle, style: GoogleFonts.bangers(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          Text(widget.partnerInitial, style: GoogleFonts.bangers(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildCartasSwapContent() {
    if (widget.partnerLetter == null) {
      return Center(child: Text('Sin cartas', style: GoogleFonts.bangers(color: Colors.white70, fontSize: 13)));
    }
    final content = widget.partnerLetter!['content'] as String? ?? '';
    final title = widget.partnerLetter!['title'] as String? ?? '';
    final fullText = title.isNotEmpty ? '$title\n$content' : content;
    return LineScrollText(
      key: ValueKey(widget.partnerLetter!['id']),
      text: fullText,
      style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.4),
      totalDuration: Duration(seconds: (fullText.split('\n').length * 5).clamp(8, 40).toInt()),
    );
  }

  Widget _buildEmocionesContent() {
    final t = widget.theme;
    if (widget.partnerMoods.isEmpty) {
      return Transform.rotate(angle: -0.05, alignment: Alignment.center, child: _fillIcon(Icons.mood, t.light));
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.partnerMoods.map((m) => Text(m['mood'] as String? ?? '', style: const TextStyle(fontSize: 40))).toList(),
        ),
      ),
    );
  }

  Widget _buildPreguntasSwapContent() {
    final t = widget.theme;
    if (widget.latestQuestion == null) {
      return Center(child: Text('Sin preguntas', style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 13)));
    }
    return PhraseScrollText(
      key: ValueKey(widget.latestQuestion!['id']),
      text: widget.latestQuestion!['question'] as String? ?? '',
      style: GoogleFonts.bangers(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      phraseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lay = widget.layout;
    final t = widget.theme;
    final seenLetter = widget.partnerLetter != null &&
        ((widget.partnerLetter!['seen_by'] as List?) ?? []).contains(widget.myId);

    return Stack(children: [
      _btnBlock(
        lay.retosX, lay.r1Y, lay.retosW * 1.35, lay.r1H, t.e,
        SwapWidget(
          autoPlay: widget.partnerRetos.isNotEmpty,
          playSound: false,
          initialDelay: const Duration(seconds: 2),
          swapDuration: const Duration(seconds: 3),
          iconDuration: const Duration(seconds: 4),
          onSwapShow: _onRetosSwapShow,
          iconChild: _fillIcon(Icons.flag, t.light),
          swapChild: _buildRetosSwapContent(),
        ),
        () => context.push(RouterRoutes.retos, extra: widget.mode),
      ),
      _btnBlock(
        lay.chatX + lay.retosW * 0.37, lay.r1Y, lay.chatW * 0.6, lay.r1H, t.a,
        _fillIcon(Icons.chat, t.light),
        () => context.push(RouterRoutes.chat, extra: widget.mode),
      ),
      _btnBlock(
        lay.cartasX, lay.cartasY, lay.cartasW, lay.cartasH, t.b,
        SwapWidget(
          autoPlay: widget.partnerLetter != null,
          playSound: false,
          initialDelay: const Duration(seconds: 1),
          swapDuration: const Duration(seconds: 4),
          iconDuration: const Duration(seconds: 2),
          iconChild: (widget.partnerLetter != null && !seenLetter)
              ? Icon(Icons.markunread_mailbox, color: t.light, size: 80)
              : _fillIcon(Icons.mail, t.light),
          swapChild: _buildCartasSwapContent(),
        ),
        () => context.push(RouterRoutes.cartas, extra: widget.mode),
      ),
      _btnBlock(
        lay.emocionesX, lay.r3Y, lay.emocionesW, lay.r3H, _purple,
        _buildEmocionesContent(),
        widget.onEmocionesTap,
      ),
      _btnBlock(
        lay.rightColX, lay.r3Y, lay.rightColW, lay.preguntasH, t.e,
        SwapWidget(
          autoPlay: false,
          showSwap: widget.showPreguntasSwap,
          iconChild: _fillIcon(Icons.help, t.light),
          swapChild: _buildPreguntasSwapContent(),
        ),
        widget.onPreguntasTap,
      ),
      _btnBlock(
        lay.metasX, lay.bottomY, lay.metasW, lay.bottomH, const Color(0xFFFFD700),
        _fillIcon(Icons.emoji_events, Colors.black),
        () => context.push(RouterRoutes.metas, extra: widget.mode),
      ),
      _btnBlock(
        lay.mapaX, lay.bottomY, lay.mapaW, lay.bottomH, t.d,
        _fillIcon(Icons.map, t.dark),
        () => context.push(RouterRoutes.mapa, extra: widget.mode),
      ),
    ]);
  }
}
