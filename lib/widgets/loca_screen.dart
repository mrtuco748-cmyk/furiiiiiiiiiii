import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'brutal_style.dart';
import 'loca_arranger.dart';
import 'loca_block.dart';
import 'loca_entry.dart';
import 'loca_header.dart';
import 'loca_swink_panel.dart';
import 'responsive_wrapper.dart';
import 'tap_tile.dart';

export 'loca_entry.dart';

/// Scaffold compartido para pantallas estilo Nosotros.
///
/// Dibuja el fondo de hormigón, un header con corazones (iconos, sin texto) y
/// distribuye las [LocaEntry] de forma "loca" aprovechando TODO el lienzo
/// (mosaico determinístico por [seed]). El contenido real se abre en paneles
/// swink superpuestos con animación de escala al tocar los bloques.
class LocaScreen extends StatefulWidget {
  final List<LocaEntry> entries;
  final List<Widget Function(BuildContext, VoidCallback)> panels;
  final List<Alignment> panelAlignments;
  final int seed;
  final ThemeSet theme;
  final bool showBack;
  final bool showHearts;
  final double blockWeight;

  const LocaScreen({
    super.key,
    required this.entries,
    this.panels = const [],
    this.panelAlignments = const [],
    this.seed = 0,
    required this.theme,
    this.showBack = true,
    this.showHearts = true,
    this.blockWeight = 1.0,
  });

  /// Envoltura brutalista estándar para el contenido de un panel swink.
  static Widget panel({
    required Color color,
    required Color borderColor,
    required Widget child,
    int bw = 4,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: child,
      ),
    );
  }

  /// Botón circular de cierre para headers de paneles (solo icono).
  static Widget closeIcon(VoidCallback onTap, Color color, IconData icon) {
    return TapTile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  @override
  State<LocaScreen> createState() => _LocaScreenState();
}

class _LocaScreenState extends State<LocaScreen>
    with SingleTickerProviderStateMixin {
  int? _openPanel;
  bool _busy = false;
  final Set<int> _forceSwap = {};
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _open(int idx) {
    SoundService().swoosh();
    setState(() => _openPanel = idx);
    _ctrl.forward(from: 0);
  }

  void _close() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _openPanel = null);
    });
  }

  void _onEntry(int idx, LocaEntry e) {
    HapticFeedback.heavyImpact();
    if (e.tapToSwap && e.swapBuilder != null) {
      setState(() => _forceSwap.add(idx));
      return;
    }
    if (e.onTapAsync != null) {
      setState(() => _busy = true);
      e.onTapAsync!(context).whenComplete(() {
        if (mounted) setState(() => _busy = false);
      });
      return;
    }
    if (e.panel >= 0) {
      _open(e.panel);
    } else {
      e.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = identityTheme(widget.theme);
    return PopScope(
      canPop: _openPanel == null && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: t.dark,
        body: ResponsiveWrapper(builder: (context, w, h) {
          final headerH = h * 0.075;
          final gap = (w * 0.018).clamp(4.0, 12.0);
          final topContent = headerH + gap;
          final contentH = h - headerH - gap - gap;
          final active = _openPanel != null;
          final panelIdx = _openPanel;

          final rects = widget.entries.isEmpty
              ? const <LocaRect>[]
              : LocaArranger.arrange(
                  width: w,
                  height: contentH,
                  cantidad: widget.entries.length,
                  seed: widget.seed,
                  weights: [
                    for (final e in widget.entries) _entryWeight(e)
                  ],
                );

          return SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                BrutalStyle.bg(t.dark),
                LocaHeader(
                  width: w,
                  height: headerH,
                  theme: t,
                  showHearts: widget.showHearts,
                ),
                for (var i = 0; i < widget.entries.length; i++)
                  _buildItem(rects[i], widget.entries[i], i, topContent, gap),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: active ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !active,
                      child: GestureDetector(
                        onTap: _close,
                        child: Container(
                            color: Colors.black.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                if (panelIdx != null || !_ctrl.isDismissed)
                  Positioned(
                    left: w * 0.05,
                    top: headerH + gap * 2,
                    width: w * 0.90,
                    height: h - headerH - gap * 3,
                    child: LocaSwinkPanel(
                      controller: _ctrl,
                      scaleAnimation: _scale,
                      opacityAnimation: _opacity,
                      alignment: (panelIdx != null &&
                              panelIdx < widget.panelAlignments.length)
                          ? widget.panelAlignments[panelIdx]
                          : Alignment.topCenter,
                      child: widget.panels[panelIdx ?? 0](context, _close),
                    ),
                  ),
                if (_busy) LocaBusyOverlay(theme: t),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItem(
      LocaRect r, LocaEntry e, int idx, double topOffset, double gap) {
    return LocaBlock(
      left: r.left + gap,
      top: topOffset + r.top + gap,
      width: r.width - gap * 2,
      height: r.height - gap * 2,
      index: idx,
      entry: e,
      forced: _forceSwap.contains(idx),
      onTap: () => _onEntry(idx, e),
    );
  }

  double _entryWeight(LocaEntry e) {
    if (e.weight != null) return e.weight!;
    final l = e.label;
    final base = (l == null || l.isEmpty)
        ? 1.0
        : (1 + l.length / 14).clamp(1.0, 8.0).toDouble();
    return (base * widget.blockWeight).clamp(0.5, 8.0);
  }
}
