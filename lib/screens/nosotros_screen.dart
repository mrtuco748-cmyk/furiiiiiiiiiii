import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../providers/rewards_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import 'nosotros/helpers/nosotros_service.dart';
import 'nosotros/models/nosotros_layout.dart';
import 'nosotros/widgets/nosotros_buttons_grid.dart';
import 'nosotros/widgets/nosotros_emociones_panel.dart';
import 'nosotros/widgets/nosotros_preguntas_panel.dart';

class NosotrosScreen extends StatefulWidget {
  final String myId;
  final String? partnerId;
  final AppMode mode;
  const NosotrosScreen({super.key, required this.myId, this.partnerId, required this.mode});

  @override
  State<NosotrosScreen> createState() => _NosotrosScreenState();
}

class _NosotrosScreenState extends State<NosotrosScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _challenges = [];
  Map<String, dynamic>? _partnerLetter;
  List<Map<String, dynamic>> _partnerMoods = [];
  List<Map<String, dynamic>> _myMoods = [];
  List<Map<String, dynamic>> _allQuestions = [];
  List<Map<String, dynamic>> _partnerQuestions = [];
  Map<String, dynamic>? _latestQuestion;

  bool _showPreguntasSwap = false;
  int _preguntasTapCount = 0;
  Timer? _preguntasTapTimer;

  String? _swinkOpen;
  late AnimationController _emocionesCtrl;
  late AnimationController _preguntasCtrl;
  late Animation<double> _emocionesScale;
  late Animation<double> _emocionesOpacity;
  late Animation<double> _preguntasScale;
  late Animation<double> _preguntasOpacity;

  RealtimeChannel? _channel;
  Timer? _reloadTimer;

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _loadAll();
    });
  }

  String get _myInitial => (AppState.identity?.substring(0, 1).toUpperCase() ?? '?');
  String get _partnerInitial => _myInitial == 'F' ? 'R' : 'F';

  @override
  void initState() {
    super.initState();
    _emocionesCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _emocionesScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _emocionesCtrl, curve: Curves.easeOut));
    _emocionesOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _emocionesCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );

    _preguntasCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _preguntasScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _preguntasCtrl, curve: Curves.easeOut));
    _preguntasOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _preguntasCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _loadAll();
    _channel = NosotrosService.subscribeRealtime(_scheduleReload);
  }

  @override
  void dispose() {
    _emocionesCtrl.dispose();
    _preguntasCtrl.dispose();
    _preguntasTapTimer?.cancel();
    _reloadTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  AnimationController get _activeCtrl => _swinkOpen == 'emociones' ? _emocionesCtrl : _preguntasCtrl;
  AnimationController get _inactiveCtrl => _swinkOpen == 'emociones' ? _preguntasCtrl : _emocionesCtrl;

  void _openSwink(String type) {
    if (_swinkOpen != null && _swinkOpen != type) _inactiveCtrl.reverse();
    setState(() => _swinkOpen = type);
    _activeCtrl.forward(from: 0);
  }

  void _closeSwink() {
    _activeCtrl.reverse().then((_) {
      if (mounted) setState(() => _swinkOpen = null);
    });
  }

  Future<void> _loadAll() async {
    var failures = 0;
    try {
      final results = await Future.wait([
        NosotrosService.loadChallenges(myId: widget.myId, partnerId: widget.partnerId).catchError((e) { failures++; return <Map<String, dynamic>>[]; }),
        NosotrosService.loadPartnerLetter(myId: widget.myId, partnerId: widget.partnerId).catchError((e) { failures++; return null; }),
        NosotrosService.loadTodayMoods(widget.partnerId).catchError((e) { failures++; return <Map<String, dynamic>>[]; }),
        NosotrosService.loadAllQuestions(myId: widget.myId, partnerId: widget.partnerId).catchError((e) { failures++; return <Map<String, dynamic>>[]; }),
      ]);
      if (!mounted) return;
      final partnerMoods = <Map<String, dynamic>>[];
      final myMoods = <Map<String, dynamic>>[];
      for (final m in (results[2] as List<Map<String, dynamic>>)) {
        if (m['user_id'] == widget.partnerId) {
          partnerMoods.add(m);
        } else {
          myMoods.add(m);
        }
      }
      final allQ = results[3] as List<Map<String, dynamic>>;
      setState(() {
        _challenges = results[0] as List<Map<String, dynamic>>;
        _partnerLetter = results[1] as Map<String, dynamic>?;
        _partnerMoods = partnerMoods;
        _myMoods = myMoods;
        _allQuestions = allQ;
        _partnerQuestions = allQ.where((q) => q['from_user'] == widget.partnerId).toList();
        _latestQuestion = _partnerQuestions.isNotEmpty ? _partnerQuestions.first : null;
      });
      if (failures >= 3 && mounted) AppFeedback.error(context, 'Sin conexión: Nosotros no se pudo cargar');
    } catch (e) {
      if (mounted) AppFeedback.error(context, 'Sin conexión: Nosotros no se pudo cargar');
    }
  }

  Future<void> _addMood(String emoji) async {
    HapticFeedback.heavyImpact();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rewards = context.read<RewardsProvider>();
    try {
      await NosotrosService.addMood(myId: widget.myId, emoji: emoji);
      _loadAll();
      rewards.awardOnce(widget.myId, 'mood-$today', 1);
    } catch (e) {
      if (mounted) AppFeedback.error(context, 'No se pudo registrar la emoción');
    }
  }

  void _onPreguntasTap() {
    HapticFeedback.heavyImpact();
    _preguntasTapCount++;
    _preguntasTapTimer?.cancel();
    if (_preguntasTapCount == 1) {
      _preguntasTapTimer = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _showPreguntasSwap = !_showPreguntasSwap;
          _preguntasTapCount = 0;
        });
      });
    } else if (_preguntasTapCount == 2) {
      setState(() {
        _showPreguntasSwap = false;
        _preguntasTapCount = 0;
      });
      if (_swinkOpen == 'preguntas') {
        _closeSwink();
      } else {
        _openSwink('preguntas');
      }
    }
  }

  List<Map<String, dynamic>> get _partnerRetos =>
      _challenges.where((c) => c['couple_id'] == widget.partnerId && (c['completed'] as bool? ?? false) == false).toList();

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Scaffold(
      backgroundColor: t.dark,
      body: SafeArea(
        child: ResponsiveWrapper(builder: (context, w, h) {
          final lay = NosotrosLayout.calculate(w, h);
          final activeEmociones = _swinkOpen == 'emociones';
          final activePreguntas = _swinkOpen == 'preguntas';
          return SizedBox(
            width: w,
            height: h,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
              _header(w, h, t),
              NosotrosButtonsGrid(
                layout: lay,
                theme: t,
                mode: widget.mode,
                myId: widget.myId,
                partnerInitial: _partnerInitial,
                partnerRetos: _partnerRetos,
                partnerLetter: _partnerLetter,
                partnerMoods: _partnerMoods,
                latestQuestion: _latestQuestion,
                showPreguntasSwap: _showPreguntasSwap,
                onPreguntasTap: _onPreguntasTap,
                onEmocionesTap: () {
                  if (_swinkOpen == 'emociones') {
                    _closeSwink();
                  } else {
                    _openSwink('emociones');
                  }
                },
              ),
              _swinkBackdrop(),
              if (activeEmociones || !_emocionesCtrl.isDismissed)
                Positioned(
                  left: lay.emocionesX, top: lay.r3Y, width: lay.panelW, height: lay.r3H,
                  child: AnimatedBuilder(
                    animation: _emocionesCtrl,
                    builder: (context, _) => NosotrosEmocionesPanel(
                      layout: lay, theme: t, active: activeEmociones,
                      scaleAnimation: _emocionesScale, opacityAnimation: _emocionesOpacity,
                      myMoods: _myMoods, partnerMoods: _partnerMoods, myId: widget.myId,
                      partnerName: AppState.partnerName,
                      onClose: _closeSwink, onAddMood: _addMood,
                      onDeleteMood: (m) => NosotrosService.deleteMood(m['id']).then((_) => _scheduleReload()),
                    ),
                  ),
                ),
              if (activePreguntas || !_preguntasCtrl.isDismissed)
                Positioned(
                  left: lay.rightColX, top: lay.r3Y, width: lay.rightColW, height: lay.r3H,
                  child: AnimatedBuilder(
                    animation: _preguntasCtrl,
                    builder: (context, _) => NosotrosPreguntasPanel(
                      layout: lay, theme: t, active: activePreguntas,
                      scaleAnimation: _preguntasScale, opacityAnimation: _preguntasOpacity,
                      allQuestions: _allQuestions, myId: widget.myId,
                      myInitial: _myInitial, partnerInitial: _partnerInitial,
                      onClose: _closeSwink,
                      onAnswer: (qid, ans) => NosotrosService.answerQuestion(questionId: qid, answer: ans).then((_) => _scheduleReload()),
                      onSendNewQuestion: (text) => NosotrosService.sendNewQuestion(myId: widget.myId, partnerId: widget.partnerId ?? '', text: text).then((_) => _scheduleReload()),
                      onDeleteQuestion: (qid) => NosotrosService.deleteQuestion(qid).then((_) => _scheduleReload()),
                    ),
                  ),
                ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _header(double w, double h, ThemeSet t) {
    return Positioned(
      left: 0, top: 0, width: w, height: h * 0.065,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(18)),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ...List.generate(3, (_) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.favorite, color: t.light, size: 28))),
            const SizedBox(width: 12),
          ]),
        ),
      ),
    );
  }

  Widget _swinkBackdrop() {
    final active = _swinkOpen != null;
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !active,
          child: GestureDetector(
            onTap: _closeSwink,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
