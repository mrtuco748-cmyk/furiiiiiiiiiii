import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../supabase_config.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../theme/app_theme.dart';

const _c = Color(0xFF39FF14);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);
const _black = Color(0xFF000000);

class QuestionScreen extends StatefulWidget {
  final String myId;
  final String partnerId;
  final AppMode mode;
  const QuestionScreen({super.key, required this.myId, required this.partnerId, required this.mode});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

enum _PageState { loading, error, empty, data }

class _QuestionScreenState extends State<QuestionScreen> {
  _PageState _state = _PageState.loading;
  final _questionCtrl = TextEditingController();
  List<Map<String, dynamic>> _history = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _state = _PageState.loading);
    try {
      final data = await SupabaseConfig.client
          .from('custom_questions')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      final history = List<Map<String, dynamic>>.from(data);
      setState(() {
        _history = history;
        _state = history.isEmpty ? _PageState.empty : _PageState.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _PageState.error);
    }
  }

  Future<void> _sendQuestion() async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.heavyImpact();
    setState(() => _sending = true);
    try {
      await SupabaseConfig.client.from('custom_questions').insert({
        'question': text,
        'from_user': widget.myId,
        'to_user': widget.partnerId,
      });
      _questionCtrl.clear();
      await _loadHistory();
    } catch (e) {
      debugPrint('QuestionScreen._send error: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  Widget fillIcon(IconData icon, Color color) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)));
  }

  Widget bg() {
    return Positioned.fill(child: CustomPaint(painter: ConcretePainter()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return ResponsiveWrapper(builder: (context, w, h) {
        return SizedBox(width: w, height: h, child: Stack(
          children: [
            bg(),
            _header(w, h),
            _questionInputBlock(w, h),
            _historyBlock(w, h),
            _sendBlock(w, h),
            _decorBlock(w, h),
          ],
        ));
      },
    );
  }

  Widget _header(double w, double h) {
    final barH = h * 0.065;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _c,
          border: Border.all(color: _black, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(children: [
          TapTile(
            onTap: () { HapticFeedback.heavyImpact(); Navigator.of(context).pop(); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: fillIcon(Icons.arrow_back, Colors.black),
            ),
          ),
        ]),
      ),
    ));
  }

  Widget _questionInputBlock(double w, double h) {
    final top = h * 0.08;
    return Positioned(left: w * 0.06, top: top, width: w * 0.88, height: h * 0.28, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _c, width: 5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(left: 14, top: 10), child: Icon(Icons.help, color: _c, size: 28)),
            Expanded(child: TextField(
              controller: _questionCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _historyBlock(double w, double h) {
    final top = h * 0.38;
    return Positioned(left: w * 0.10, top: top, width: w * 0.80, height: h * 0.20, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _c, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: switch (_state) {
            _PageState.loading => Center(child: fillIcon(Icons.hourglass_top, _c)),
            _PageState.error => _errorContent(),
            _PageState.empty => Center(child: fillIcon(Icons.question_answer, const Color(0xFF333333))),
            _PageState.data => ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _history.length.clamp(0, 5),
              itemBuilder: (ctx, i) {
                final q = _history[i];
                final answered = q['answered'] == true;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: answered ? _c : _mid, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(answered ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: answered ? _c : _dark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Icon(Icons.question_answer, color: answered ? _c : const Color(0xFF555555), size: 20)),
                  ]),
                );
              },
            ),
          },
        ),
      ),
    );
  }

  Widget _errorContent() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off, color: _c, size: 28),
      const SizedBox(height: 6),
      TapTile(
        onTap: () { HapticFeedback.heavyImpact(); _loadHistory(); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _c, border: Border.all(color: _black, width: 3),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.refresh, color: Colors.black, size: 22),
          ),
        ),
      ),
    ]));
  }

  Widget _sendBlock(double w, double h) {
    final top = h * 0.62;
    return Positioned(left: w * 0.25, top: top, width: w * 0.50, height: h * 0.07, child: TapTile(
        onTap: _sendQuestion,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _black, width: 5),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Center(child: _sending
              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
              : fillIcon(Icons.send, Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorBlock(double w, double h) {
    final size = w * 0.10;
    return Positioned(right: w * 0.06, bottom: h * 0.08, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: _c,
            border: Border.all(color: _black, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: fillIcon(Icons.question_mark, Colors.black),
        ),
      ));
  }
}
