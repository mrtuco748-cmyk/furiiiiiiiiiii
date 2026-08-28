import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'brutal_style.dart';
import 'loca_arranger.dart';
import 'responsive_wrapper.dart';
import 'swap_widget.dart';
import 'tap_tile.dart';

/// Entrada de una pantalla "loca" estilo Nosotros: un bloque gigante con icono
/// que ocupa una porción del lienzo. Al tocarlo puede:
///  - abrir un panel swink (si [panel] >= 0, indexando `LocaScreen.panels`),
///  - ejecutar una acción directa (si [onTap] != null),
///  - y/o mostrar contenido rotativo (swap) encima del icono.
/// [label] es el título corto del ítem (se muestra bajo el icono) y hace que
/// el arranger le dé un bloque más grande cuanto más texto tiene.
class LocaEntry {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final int panel;
  final VoidCallback? onTap;
  final Future<void> Function(BuildContext context)? onTapAsync;
  final Widget Function(BuildContext)? swapBuilder;
  final Widget Function(BuildContext)? childBuilder;
  final bool autoPlaySwap;
  final bool isAction;
  final bool tapToSwap;
  final String? label;
  final double? weight;
  final Duration iconDuration;
  final Duration swapDuration;
  final Duration initialDelay;

  const LocaEntry({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    this.panel = -1,
    this.onTap,
    this.onTapAsync,
    this.swapBuilder,
    this.childBuilder,
    this.autoPlaySwap = false,
    this.isAction = false,
    this.tapToSwap = false,
    this.label,
    this.weight,
    this.iconDuration = const Duration(seconds: 4),
    this.swapDuration = const Duration(seconds: 7),
    this.initialDelay = const Duration(seconds: 4),
  });
}

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

  const LocaScreen({
    super.key,
    required this.entries,
    this.panels = const [],
    this.panelAlignments = const [],
    this.seed = 0,
    required this.theme,
    this.showBack = true,
    this.showHearts = true,
  });

  /// Envoltura brutalista estándar para el contenido de un panel swink.
  static Widget panel({
    required Color color,
    required Color borderColor,
    required Widget child,
    int bw = 4,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: bw.toDouble()),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0xFF000000), offset: Offset(8, 8), blurRadius: 0),
          ],
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
          border: Border.all(color: color, width: 2),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _open(int idx) {
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

        // Un SOLO mosaico: TODAS las entradas (ítems + botones de acción) se
        // reparten juntas con el mismo arranger, camufladas entre sí. Los pesos
        // salen de la cantidad de texto de cada tile: más texto → bloque mayor.
        final rects = widget.entries.isEmpty
            ? const <LocaRect>[]
            : LocaArranger.arrange(
                width: w,
                height: contentH,
                cantidad: widget.entries.length,
                seed: widget.seed,
                weights: [for (final e in widget.entries) _entryWeight(e)],
              );

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              BrutalStyle.bg(t.dark),
              _header(w, h, t),
              for (var i = 0; i < widget.entries.length; i++)
                _buildItem(rects[i], widget.entries[i], i, topContent, gap),
              // Backdrop que cierra el swink con un tap.
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: active ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !active,
                    child: GestureDetector(
                      onTap: _close,
                      child: Container(color: Colors.black.withValues(alpha: 0.5)),
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
                  child: _swinkPanel(panelIdx ?? 0),
                ),
              if (_busy)
                Positioned.fill(child: _busyOverlay(t)),
            ],
          ),
        );
      }),
    ));
  }

  Widget _busyOverlay(ThemeSet t) {
    return ColoredBox(
      color: t.dark.withValues(alpha: 0.6),
      child: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(color: t.light, strokeWidth: 4),
        ),
      ),
    );
  }

  Widget _header(double w, double h, ThemeSet t) {
    final barH = h * 0.075;
    return Positioned(
      left: 0,
      top: 0,
      width: w,
      height: barH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: t.d,
            border: Border.all(color: t.d, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
            ],
          ),
          child: Row(children: [
            const Spacer(),
            if (widget.showHearts)
              ...List.generate(3, (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.favorite, color: t.light, size: 28),
              )),
            const SizedBox(width: 12),
          ]),
        ),
      ),
    );
  }

  Widget _buildItem(LocaRect r, LocaEntry e, int idx, double topOffset, double gap) {
    return _buildBlock(
      r.left + gap,
      topOffset + r.top + gap,
      r.width - gap * 2,
      r.height - gap * 2,
      idx,
      e,
    );
  }

  double _entryWeight(LocaEntry e) {
    if (e.weight != null) return e.weight!;
    final l = e.label;
    if (l == null || l.isEmpty) return 1;
    return (1 + l.length / 14).clamp(1.0, 8.0).toDouble();
  }

Widget _buildBlock(
    double l, double t, double w, double h, int idx, LocaEntry e) {
    final bool forced = _forceSwap.contains(idx);
    final Widget child;
    if (e.childBuilder != null) {
      child = e.childBuilder!(context);
    } else if (e.swapBuilder != null) {
      child = SwapWidget(
        autoPlay: e.autoPlaySwap && !forced,
        iconDuration: e.iconDuration,
        swapDuration: e.swapDuration,
        initialDelay: e.initialDelay,
        showSwap: e.tapToSwap && forced ? true : null,
        iconChild: _iconWithLabel(e),
        swapChild: e.swapBuilder!(context),
      );
    } else {
      child = _iconWithLabel(e);
    }
    return BrutalStyle.block(
      l,
      t,
      w,
      h,
      e.color,
      child,
      () => _onEntry(idx, e),
      rot: 0,
    );
  }

  /// Icono de estado + título del ítem debajo (mismo color que el icono).
  Widget _iconWithLabel(LocaEntry e) {
    final icon = BrutalStyle.fillIcon(e.icon, e.iconColor);
    final title = e.label;
    if (title == null || title.isEmpty) return icon;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(mainAxisSize: MainAxisSize.max, children: [
        Expanded(child: icon),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.bangers(color: e.iconColor, fontSize: 13, height: 1.1),
        ),
      ]),
    );
  }

  Widget _swinkPanel(int idx) {
    final alignment = idx < widget.panelAlignments.length
        ? widget.panelAlignments[idx]
        : Alignment.topCenter;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return IgnorePointer(
          ignoring: _ctrl.status == AnimationStatus.dismissed,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              alignment: alignment,
              child: widget.panels[idx](context, _close),
            ),
          ),
        );
      },
    );
  }
}