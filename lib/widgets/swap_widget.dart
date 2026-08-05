import 'dart:async';
import 'package:flutter/material.dart';

class SwapWidget extends StatefulWidget {
  final Widget iconChild;
  final Widget swapChild;
  final bool autoPlay;
  final Duration iconDuration;
  final Duration swapDuration;
  final Duration initialDelay;
  final bool? showSwap;

  const SwapWidget({
    super.key,
    required this.iconChild,
    required this.swapChild,
    this.autoPlay = true,
    this.iconDuration = const Duration(seconds: 4),
    this.swapDuration = const Duration(seconds: 7),
    this.initialDelay = const Duration(seconds: 4),
    this.showSwap,
  });

  @override
  State<SwapWidget> createState() => _SwapWidgetState();
}

class _SwapWidgetState extends State<SwapWidget> {
  bool _showingSwap = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _startCycle();
    } else if (widget.showSwap != null) {
      _showingSwap = widget.showSwap!;
    }
  }

  @override
  void didUpdateWidget(SwapWidget old) {
    super.didUpdateWidget(old);
    if (widget.autoPlay && !old.autoPlay) {
      _startCycle();
    } else if (!widget.autoPlay && widget.showSwap != old.showSwap) {
      setState(() => _showingSwap = widget.showSwap ?? false);
    }
  }

  void _startCycle() {
    _timer?.cancel();
    _showingSwap = false;
    _timer = Timer(widget.initialDelay, () {
      if (!mounted) return;
      _showSwapContent();
    });
  }

  void _showSwapContent() {
    if (!mounted) return;
    setState(() => _showingSwap = true);
    _timer = Timer(widget.swapDuration, () {
      if (!mounted) return;
      _showIcon();
    });
  }

  void _showIcon() {
    if (!mounted) return;
    setState(() => _showingSwap = false);
    _timer = Timer(widget.iconDuration, () {
      if (!mounted) return;
      _showSwapContent();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _showingSwap
          ? KeyedSubtree(key: const ValueKey('swap'), child: widget.swapChild)
          : KeyedSubtree(key: const ValueKey('icon'), child: widget.iconChild),
    );
  }
}

class LineScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration totalDuration;
  final VoidCallback? onComplete;

  const LineScrollText({
    super.key,
    required this.text,
    required this.style,
    this.totalDuration = const Duration(seconds: 8),
    this.onComplete,
  });

  @override
  State<LineScrollText> createState() => _LineScrollTextState();
}

class _LineScrollTextState extends State<LineScrollText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.totalDuration);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final textHeight = constraints.maxHeight * 3;
            return ClipRect(
              child: Transform.translate(
                offset: Offset(0, textHeight * (1 - _anim.value) - textHeight + constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(widget.text, style: widget.style, textAlign: TextAlign.start),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PhraseScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration phraseDuration;

  const PhraseScrollText({
    super.key,
    required this.text,
    required this.style,
    this.phraseDuration = const Duration(seconds: 3),
  });

  @override
  State<PhraseScrollText> createState() => _PhraseScrollTextState();
}

class _PhraseScrollTextState extends State<PhraseScrollText> {
  int _currentPhrase = 0;
  List<String> _phrases = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final regex = RegExp(r'[^.!?\n]+[.!?\n]?');
    _phrases = regex.allMatches(widget.text).map((m) => m.group(0)!.trim()).where((s) => s.isNotEmpty).toList();
    if (_phrases.isEmpty) _phrases = [widget.text];
    _timer = Timer.periodic(widget.phraseDuration, (_) {
      if (!mounted) return;
      setState(() => _currentPhrase = (_currentPhrase + 1) % _phrases.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phrases.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Padding(
        key: ValueKey(_currentPhrase),
        padding: const EdgeInsets.all(8),
        child: Text(_phrases[_currentPhrase], style: widget.style),
      ),
    );
  }
}
