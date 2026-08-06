import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/swap_widget.dart';
import '../widgets/responsive_wrapper.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'letters_screen.dart';
import 'retos_screen.dart';
import 'metas_screen.dart';
import 'mapa_screen.dart';

const _purple = Color(0xFF7000FF);
const _black = Color(0xFF000000);

const _emojis = ['😊', '😢', '😡', '😍', '😴', '😰', '🥳', '🤔', '😎', '🤗', '😤', '🥰', '😱', '😶', '🙄', '😇'];

class _Layout {
  final double w, h, gapW, gapH, headerH;
  final double r1Y, r1H, cartasY, cartasH;
  final double r3Y, r3H, emocionesW, emocionesX;
  final double rightColX, rightColW, preguntasH, margin;

  const _Layout({
    required this.w, required this.h, required this.gapW, required this.gapH, required this.headerH,
    required this.r1Y, required this.r1H, required this.cartasY, required this.cartasH,
    required this.r3Y, required this.r3H, required this.emocionesW, required this.emocionesX,
    required this.rightColX, required this.rightColW, required this.preguntasH, required this.margin,
  });

  double get retosW => (w - margin * 2 - gapW) * 0.5;
  double get chatW => retosW;
  double get retosX => margin;
  double get chatX => retosX + retosW + gapW;
  double get cartasW => w - margin * 2;
  double get cartasX => margin;
  double get bottomH => r3H - preguntasH - gapH;
  double get metasW => (rightColW - gapW) / 2;
  double get mapaW => metasW;
  double get metasX => rightColX;
  double get mapaX => metasX + metasW + gapW;
  double get bottomY => r3Y + preguntasH + gapH;
  double get panelW => emocionesW + gapW + rightColW;
  double get iconW => emocionesW * 0.7;
}

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

  bool _answeringQuestion = false;
  Map<String, dynamic>? _questionToAnswer;
  final _answerController = TextEditingController();
  final _emojiCtrl = TextEditingController();
  final _mostUsedEmojis = ['😊','😍','😂','🥰','😢','😡','🥳','❤️','🔥','😎','🤗','😴'];
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
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _emocionesCtrl.dispose();
    _preguntasCtrl.dispose();
    _preguntasTapTimer?.cancel();
    _answerController.dispose();
    _emojiCtrl.dispose();
    _reloadTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  AnimationController get _activeCtrl => _swinkOpen == 'emociones' ? _emocionesCtrl : _preguntasCtrl;
  AnimationController get _inactiveCtrl => _swinkOpen == 'emociones' ? _preguntasCtrl : _emocionesCtrl;

  void _openSwink(String type) {
    if (_swinkOpen != null && _swinkOpen != type) {
      _inactiveCtrl.reverse();
    }
    setState(() => _swinkOpen = type);
    _activeCtrl.forward(from: 0);
  }

  void _closeSwink() {
    _activeCtrl.reverse().then((_) {
      if (mounted) setState(() => _swinkOpen = null);
    });
  }

  void _subscribeRealtime() {
    _channel = SupabaseConfig.client
        .channel('nosotros_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'challenges',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'letters',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'moods',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'custom_questions',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _loadChallenges().catchError((e) { debugPrint('challenges error: $e'); return <Map<String, dynamic>>[]; }),
        _loadPartnerLetter().catchError((e) { debugPrint('letters error: $e'); return null; }),
        _loadTodayMoods().catchError((e) { debugPrint('moods error: $e'); return <Map<String, dynamic>>[]; }),
        _loadAllQuestions().catchError((e) { debugPrint('questions error: $e'); return <Map<String, dynamic>>[]; }),
      ]);
      if (!mounted) return;
      debugPrint('Nosotros: challenges=${(results[0] as List).length}, letter=${results[1] != null}, moods=${(results[2] as List).length}, questions=${(results[3] as List).length}');
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
    } catch (e) {
      debugPrint('Nosotros _loadAll error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadChallenges() async {
    final filters = widget.partnerId != null
        ? 'couple_id.eq.${widget.myId},couple_id.eq.${widget.partnerId}'
        : 'couple_id.eq.${widget.myId}';
    final data = await SupabaseConfig.client
        .from('challenges')
        .select('*')
        .or(filters)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> _loadPartnerLetter() async {
    if (widget.partnerId == null) return null;
    final data = await SupabaseConfig.client
        .from('letters')
        .select('*')
        .eq('from_user', widget.partnerId!)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return null;
    final letter = data[0] as Map<String, dynamic>;
    // Solo presenta cartas no leidas por el usuario actual.
    await _markSeen(letter, 'letters');
    return letter['seen_by'] != null &&
            (letter['seen_by'] as List).contains(widget.myId)
        ? null
        : letter;
  }

  // Marca como "visto" el registro actual (agrega myId al array seen_by).
  Future<void> _markSeen(Map<String, dynamic> record, String table) async {
    final list = (record['seen_by'] as List?)?.cast<String>() ?? <String>[];
    if (list.contains(widget.myId)) return;
    list.add(widget.myId);
    record['seen_by'] = list;
    try {
      await SupabaseConfig.client.from(table).update({'seen_by': list}).eq('id', record['id']);
    } catch (e) {
      debugPrint('Nosotros _markSeen error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadTodayMoods() async {
    if (widget.partnerId == null) return [];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await SupabaseConfig.client
        .from('moods')
        .select('*')
        .eq('date', today)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadAllQuestions() async {
    if (widget.partnerId == null) return [];
    final data = await SupabaseConfig.client
        .from('custom_questions')
        .select('*')
        .or('from_user.eq.${widget.myId},to_user.eq.${widget.myId}')
        .order('created_at', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _addMood(String emoji) async {
    if (emoji.isEmpty) return;
    HapticFeedback.heavyImpact();
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      await SupabaseConfig.client.from('moods').insert({
        'user_id': widget.myId,
        'mood': emoji,
        'date': today,
      });
      _loadAll();
    } catch (e) {
      debugPrint('NosotrosScreen._selectMood error: $e');
    }
  }

  Future<void> _answerQuestion(String answer) async {
    if (_questionToAnswer == null || answer.isEmpty) return;
    HapticFeedback.heavyImpact();
    try {
      await SupabaseConfig.client.from('custom_questions').update({
        'answer': answer,
        'answered_at': DateTime.now().toIso8601String(),
      }).eq('id', _questionToAnswer!['id']);
      setState(() {
        _answeringQuestion = false;
        _questionToAnswer = null;
        _answerController.clear();
      });
      _scheduleReload();
    } catch (e) {
      debugPrint('NosotrosScreen._answerQuestion error: $e');
    }
  }

  Future<void> _sendNewQuestion(String text) async {
    if (text.isEmpty || widget.partnerId == null) return;
    HapticFeedback.heavyImpact();
    try {
      await SupabaseConfig.client.from('custom_questions').insert({
        'from_user': widget.myId,
        'to_user': widget.partnerId,
        'question': text.trim(),
      });
      setState(() {
        _answeringQuestion = false;
        _questionToAnswer = null;
        _answerController.clear();
      });
      _loadAll();
    } catch (e) {
      debugPrint('NosotrosScreen._sendNewQuestion error: $e');
    }
  }

  void _navigateToChat() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        myId: widget.myId, partnerId: widget.partnerId ?? '',
        myName: 'Yo', mode: widget.mode,
      ),
    ));
  }

  void _navigateToRetos() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RetosScreen(mode: widget.mode),
    ));
  }

  void _navigateToLetters() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LettersScreen(mode: widget.mode, name: 'Yo'),
    ));
  }

  void _onEmocionesTap() {
    HapticFeedback.heavyImpact();
    if (_swinkOpen == 'emociones') {
      _closeSwink();
    } else {
      _openSwink('emociones');
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

  void _navigateToMetas() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MetasScreen(mode: widget.mode),
    ));
  }

  void _navigateToMapa() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MapaScreen(mode: widget.mode),
    ));
  }

  Widget fillIcon(IconData icon, Color color) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)));
  }

  Widget bg() {
    return Positioned.fill(child: CustomPaint(painter: ConcretePainter()));
  }

  Widget btnBlock(double l, double t, double w, double h, Color bgColor, Widget child,
      VoidCallback? onTap, {int bw = 3, double rot = 0}) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: bgColor, width: bw.toDouble()),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: child,
      ),
    );
    final rotated = rot != 0
        ? Transform.rotate(angle: rot, alignment: Alignment.center, child: content)
        : content;
    return Positioned(
      left: l, top: t, width: w, height: h,
      child: onTap != null
          ? TapTile(onTap: () { HapticFeedback.heavyImpact(); onTap(); }, child: rotated)
          : rotated,
    );
  }

  Widget _buildCartasIcon(ThemeSet t) {
    if (_partnerLetter != null) {
      final seenByMe = ((_partnerLetter!['seen_by'] as List?) ?? []).contains(widget.myId);
      if (!seenByMe) {
        return Icon(Icons.markunread_mailbox, color: t.light, size: 80);
      }
    }
    return fillIcon(Icons.mail, t.light);
  }

  List<Map<String, dynamic>> get _partnerRetos =>
      _challenges.where((c) =>
          c['couple_id'] == widget.partnerId &&
          (c['completed'] as bool? ?? false) == false).toList();

  Widget _buildRetosSwapContent(ThemeSet t) {
    final retos = _partnerRetos;
    if (retos.isEmpty) {
      return Center(child: Text('Sin retos', style: GoogleFonts.bangers(color: Colors.white70, fontSize: 13)));
    }
    final random = retos[Random().nextInt(retos.length)];
    final title = random['title'] as String? ?? '';
    _markSeen(random, 'challenges');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: GoogleFonts.bangers(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
          const SizedBox(height: 4),
          Text(_partnerInitial, style: GoogleFonts.bangers(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildCartasSwapContent(ThemeSet t) {
    if (_partnerLetter == null) {
      return Center(child: Text('Sin cartas', style: GoogleFonts.bangers(color: Colors.white70, fontSize: 13)));
    }
    final content = _partnerLetter!['content'] as String? ?? '';
    final title = _partnerLetter!['title'] as String? ?? '';
    final fullText = title.isNotEmpty ? '$title\n$content' : content;
    return LineScrollText(
      key: ValueKey(_partnerLetter!['id']),
      text: fullText,
      style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.4),
      totalDuration: Duration(seconds: (fullText.split('\n').length * 5).clamp(8, 40).toInt()),
    );
  }

  Widget _buildEmocionesContent(ThemeSet t) {
    final hasPartnerMoods = _partnerMoods.isNotEmpty;
    if (!hasPartnerMoods) {
      return Transform.rotate(angle: -0.05, alignment: Alignment.center,
        child: fillIcon(Icons.mood, t.light));
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _partnerMoods.map((m) {
            final moodText = m['mood'] as String? ?? '';
            return Text(moodText, style: const TextStyle(fontSize: 40));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPreguntasSwapContent(ThemeSet t) {
    if (_latestQuestion == null) {
      return Center(child: Text('Sin preguntas', style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 13)));
    }
    final question = _latestQuestion!['question'] as String? ?? '';
    return PhraseScrollText(
      key: ValueKey(_latestQuestion!['id']),
      text: question,
      style: GoogleFonts.bangers(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      phraseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = getTheme(widget.mode);
    final t = raw;

    return Scaffold(
      backgroundColor: t.dark,
      body: SafeArea(child: _buildContent(t)),
    );
  }

  _Layout _calcLayout(double w, double h) {
    final margin = w * 0.04;
    final gapW = w * 0.02;
    final gapH = h * 0.02;
    final headerH = h * 0.065;

    final r1Y = headerH + gapH;
    final r1H = h * 0.14;

    final cartasY = r1Y + r1H + gapH;
    final cartasH = h * 0.25;

    final r3Y = cartasY + cartasH + gapH;
    final emocionesW = w * 0.30;
    final emocionesX = margin;
    final rightColX = emocionesX + emocionesW + gapW;
    final rightColW = w - margin - rightColX;
    final r3H = h - r3Y - gapH;
    final preguntasH = r3H * 0.53;

    return _Layout(
      w: w, h: h, gapW: gapW, gapH: gapH, headerH: headerH,
      r1Y: r1Y, r1H: r1H, cartasY: cartasY, cartasH: cartasH,
      r3Y: r3Y, r3H: r3H, emocionesW: emocionesW, emocionesX: emocionesX,
      rightColX: rightColX, rightColW: rightColW,
      preguntasH: preguntasH, margin: margin,
    );
  }

  Widget _buildContent(ThemeSet t) {
    return ResponsiveWrapper(builder: (context, w, h) {
        final lay = _calcLayout(w, h);
        final activeEmociones = _swinkOpen == 'emociones';
        final activePreguntas = _swinkOpen == 'preguntas';
        return SizedBox(width: w, height: h, child: Stack(
          children: [
            bg(),
            _header(w, h, t),
            _buttonsLayout(lay, t),
            _swinkBackdrop(t),
            if (activeEmociones || !_emocionesCtrl.isDismissed)
              Positioned(
                left: lay.emocionesX, top: lay.r3Y,
                width: lay.emocionesW + lay.gapW + lay.rightColW, height: lay.r3H,
                child: _swinkEmocionesPanel(lay, t, activeEmociones),
              ),
            if (activePreguntas || !_preguntasCtrl.isDismissed)
              Positioned(
                left: lay.rightColX, top: lay.r3Y,
                width: lay.rightColW, height: lay.r3H,
                child: _swinkPreguntasPanel(lay, t, activePreguntas),
              ),
          ],
        ));
      },
    );
  }

  Widget _header(double w, double h, ThemeSet t) {
    final barH = h * 0.065;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: t.d,
          border: Border.all(color: t.d, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.favorite, color: t.light, size: 28),
          )),
          const SizedBox(width: 12),
        ]),
      ),
    ));
  }

  Widget _buttonsLayout(_Layout lay, ThemeSet t) {
    return Stack(children: [
      btnBlock(lay.retosX, lay.r1Y, lay.retosW * 1.35, lay.r1H, t.e,
        SwapWidget(
          autoPlay: _partnerRetos.isNotEmpty,
          initialDelay: const Duration(seconds: 4),
          swapDuration: const Duration(seconds: 7),
          iconDuration: const Duration(seconds: 4),
          iconChild: fillIcon(Icons.flag, t.light),
          swapChild: _buildRetosSwapContent(t),
        ),
        _navigateToRetos, bw: 4),

      btnBlock(lay.chatX + lay.retosW * 0.37, lay.r1Y, lay.chatW * 0.6, lay.r1H, t.a,
        fillIcon(Icons.chat, t.light), _navigateToChat, bw: 4),

      btnBlock(lay.cartasX, lay.cartasY, lay.cartasW, lay.cartasH, t.b,
        SwapWidget(
          autoPlay: _partnerLetter != null,
          initialDelay: const Duration(seconds: 2),
          swapDuration: const Duration(seconds: 10),
          iconDuration: const Duration(seconds: 2),
          iconChild: _buildCartasIcon(t),
          swapChild: _buildCartasSwapContent(t),
        ),
        _navigateToLetters, bw: 4),

      btnBlock(lay.emocionesX, lay.r3Y, lay.emocionesW, lay.r3H, _purple,
        _buildEmocionesContent(t), _onEmocionesTap, bw: 4),

      btnBlock(lay.rightColX, lay.r3Y, lay.rightColW, lay.preguntasH, t.e,
        SwapWidget(
          autoPlay: false,
          showSwap: _showPreguntasSwap,
          iconChild: fillIcon(Icons.help, t.light),
          swapChild: _buildPreguntasSwapContent(t),
        ),
        _onPreguntasTap, bw: 4),

      btnBlock(lay.metasX, lay.bottomY, lay.metasW, lay.bottomH, const Color(0xFFFFD700),
        fillIcon(Icons.emoji_events, Colors.black), _navigateToMetas, bw: 4),

      btnBlock(lay.mapaX, lay.bottomY, lay.mapaW, lay.bottomH, t.d,
        fillIcon(Icons.map, t.dark), _navigateToMapa, bw: 4),
    ]);
  }

  Widget _swinkBackdrop(ThemeSet t) {
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

  Widget _swinkEmocionesPanel(_Layout lay, ThemeSet t, bool active) {
    return AnimatedBuilder(
      animation: _emocionesCtrl,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: !active,
          child: Opacity(
            opacity: _emocionesOpacity.value,
            child: Transform.scale(
              scale: _emocionesScale.value,
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: _purple,
                    border: Border.all(color: t.c, width: 4),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(10, 10), blurRadius: 0)],
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: lay.iconW, height: lay.r3H,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Transform.rotate(angle: -0.05, alignment: Alignment.center,
                          child: _buildEmocionesContent(t)),
                        const SizedBox(height: 8),
                        TapTile(
                          onTap: _closeSwink,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _black, width: 3)),
                            child: Icon(Icons.close, color: t.light, size: 20),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(width: lay.gapW),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          flex: 1,
                          child: Row(children: [
                            Expanded(child: TextField(
                              controller: _emojiCtrl,
                              style: const TextStyle(fontSize: 22),
                              decoration: InputDecoration(
                                hintText: '😊',
                                hintStyle: TextStyle(color: t.light.withValues(alpha: 0.3), fontSize: 22),
                                filled: true, fillColor: t.dark.withValues(alpha: 0.3),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.c, width: 2)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.c, width: 2)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onSubmitted: (v) { _addMood(v); _emojiCtrl.clear(); },
                            )),
                            const SizedBox(width: 6),
                            TapTile(
                              onTap: () { _addMood(_emojiCtrl.text); _emojiCtrl.clear(); },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: t.c, borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: t.c, width: 2)),
                                child: Icon(Icons.send, color: t.light, size: 20),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4, runSpacing: 4,
                          children: _mostUsedEmojis.map((e) => TapTile(
                            onTap: () { _addMood(e); _emojiCtrl.clear(); },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: t.dark.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: t.c, width: 2)),
                              child: Text(e, style: const TextStyle(fontSize: 20)),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              ..._myMoods.map((m) => _moodRow(m, 'Yo', t)),
                              ..._partnerMoods.map((m) => _moodRow(m, 'Pareja', t)),
                              if (_myMoods.isEmpty && _partnerMoods.isEmpty)
                                Text('Sin emociones hoy', style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 12)),
                            ]),
                          ),
                        ),
                      ]),
                    )),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMood(Map<String, dynamic> m) async {
    try {
      await SupabaseConfig.client.from('moods').delete().eq('id', m['id']);
      _scheduleReload();
    } catch (e) { debugPrint('deleteMood error: $e'); }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> q) async {
    try {
      await SupabaseConfig.client.from('custom_questions').delete().eq('id', q['id']);
      _scheduleReload();
    } catch (e) { debugPrint('deleteQuestion error: $e'); }
  }

  Widget _moodRow(Map<String, dynamic> m, String label, ThemeSet t) {
    final mood = m['mood'] as String? ?? '';
    final time = m['created_at'] != null
        ? DateTime.parse(m['created_at'] as String).toLocal().toString().substring(11, 16)
        : '';
    final isMine = m['user_id'] == widget.myId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(mood, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 6),
        Text(time, style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 11)),
        if (isMine) ...[
          const SizedBox(width: 6),
          GestureDetector(onTap: () { HapticFeedback.heavyImpact(); _deleteMood(m); }, child: Icon(Icons.close, color: t.light.withValues(alpha: 0.4), size: 14)),
        ],
      ]),
    );
  }

  Widget _swinkPreguntasPanel(_Layout lay, ThemeSet t, bool active) {
    return AnimatedBuilder(
      animation: _preguntasCtrl,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: !active,
          child: Opacity(
            opacity: _preguntasOpacity.value,
            child: Transform.scale(
              scale: _preguntasScale.value,
              alignment: Alignment.topCenter,
              child: _answeringQuestion
                  ? _buildAnswerPanelContent(lay, t)
                  : _buildPreguntasPanelContent(lay, t),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreguntasPanelContent(_Layout lay, ThemeSet t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _purple,
          border: Border.all(color: t.c, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(10, 10), blurRadius: 0)],
        ),
        child: Column(children: [
          Container(
            height: lay.preguntasH,
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: const SizedBox()),
                TapTile(
                  onTap: _closeSwink,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _black, width: 2)),
                    child: Icon(Icons.close, color: t.light, size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:
                    _allQuestions.map((q) => _questionTile(q, t)).toList(),
                  ),
                ),
              ),
            ]),
          ),
          Container(height: 3, color: _black),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TapTile(
              onTap: () {
                HapticFeedback.heavyImpact();
                setState(() {
                  _answeringQuestion = true;
                  _questionToAnswer = null;
                });
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.d, width: 3)),
                child: Center(child: Icon(Icons.add, color: t.dark, size: 28)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAnswerPanelContent(_Layout lay, ThemeSet t) {
    final isNewQuestion = _questionToAnswer == null;
    final question = _questionToAnswer?['question'] as String? ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _purple,
          border: Border.all(color: _purple, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(8, 8), blurRadius: 0)],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(isNewQuestion ? 'Nueva pregunta' : 'Responder pregunta', style: GoogleFonts.bangers(color: t.light, fontSize: 14, fontWeight: FontWeight.bold))),
            TapTile(
              onTap: () => setState(() {
                _answeringQuestion = false;
                _questionToAnswer = null;
                _answerController.clear();
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.e, width: 2)),
                child: Icon(Icons.close, color: t.light, size: 16),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (!isNewQuestion)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: t.dark.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.dark.withValues(alpha: 0.3), width: 2)),
              child: Text(question, style: GoogleFonts.bangers(color: t.light, fontSize: 14)),
            ),
          if (!isNewQuestion) const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            maxLines: 4,
            style: GoogleFonts.bangers(color: t.light, fontSize: 14),
            decoration: InputDecoration(
              hintText: isNewQuestion ? 'Escribe tu pregunta...' : 'Escribe tu respuesta...',
              hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4), fontSize: 14),
              filled: true, fillColor: t.dark.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.dark.withValues(alpha: 0.3), width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.dark.withValues(alpha: 0.3), width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 8),
          TapTile(
            onTap: () => isNewQuestion ? _sendNewQuestion(_answerController.text) : _answerQuestion(_answerController.text),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.d, width: 3)),
              child: Center(child: Text(isNewQuestion ? 'Enviar pregunta' : 'Enviar respuesta', style: GoogleFonts.bangers(color: t.dark, fontSize: 14, fontWeight: FontWeight.bold))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _questionTile(Map<String, dynamic> q, ThemeSet t) {
    final question = q['question'] as String? ?? '';
    final answer = q['answer'] as String?;
    final fromMe = q['from_user'] == widget.myId;
    final isAnswered = answer != null && answer.isNotEmpty;
    final qToUser = q['to_user'] as String?;
    final answererInitial = qToUser == widget.myId ? _myInitial : _partnerInitial;
    final askerInitial = fromMe ? _myInitial : _partnerInitial;
    return GestureDetector(
      onTap: () {
        if (!isAnswered && !fromMe) {
          HapticFeedback.heavyImpact();
          setState(() {
            _answeringQuestion = true;
            _questionToAnswer = q;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: t.dark.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _black, width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: fromMe ? const Color(0xFF00F0FF) : const Color(0xFFFF66C4), borderRadius: BorderRadius.circular(6)), child: Text(askerInitial, style: GoogleFonts.bangers(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
              const SizedBox(width: 4),
              Expanded(child: Text(question, style: GoogleFonts.bangers(color: t.light, fontSize: 12))),
              if (fromMe) GestureDetector(onTap: () { HapticFeedback.heavyImpact(); _deleteQuestion(q); }, child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.close, color: Color(0xFFFF4444), size: 16))),
            ]),
            if (isAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$answererInitial: $answer', style: GoogleFonts.bangers(color: t.d, fontSize: 11)),
              ),
            if (!isAnswered && !fromMe)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Toca para responder', style: GoogleFonts.bangers(color: t.d.withValues(alpha: 0.7), fontSize: 10)),
              ),
          ]),
        ),
      ),
    );
  }

}

// This is a fix for the deprecated AnimatedBuilder - using AnimatedWidget or similar
// Flutter has renamed AnimatedBuilder to AnimatedWidget in some versions.
// Keeping AnimatedBuilder as is since it's still available.
