import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../widgets/mood_display.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../theme/app_theme.dart';

const _c = Color(0xFF9D00FF);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);
const _moodColors = [
  Color(0xFFFF5757), Color(0xFFFF6B00), Color(0xFFFFDE59), Color(0xFF39FF14),
  Color(0xFF00FF66), Color(0xFF00F0FF), Color(0xFF0088FF), Color(0xFF7000FF),
  Color(0xFF9D00FF), Color(0xFFFF66C4), Color(0xFFFF1493), Color(0xFFCC0000),
  Color(0xFFFF8800), Color(0xFFAACC00), Color(0xFF00CC88), Color(0xFF0088CC),
  Color(0xFF4400CC), Color(0xFFAA00FF), Color(0xFFFF4444), Color(0xFFFFBB33),
];

class MoodScreen extends StatefulWidget {
  final AppMode mode;
  const MoodScreen({super.key, required this.mode});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _textCtrl = TextEditingController();
  Color _selectedColor = _moodColors[0];
  String _previewEmotion = ':)';
  bool _saving = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _selectColor(Color color) {
    HapticFeedback.heavyImpact();
    setState(() => _selectedColor = color);
  }

  Future<void> _saveMood() async {
    HapticFeedback.heavyImpact();
    setState(() => _saving = true);
    final text = _textCtrl.text.trim().isEmpty ? _previewEmotion : _textCtrl.text.trim();
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      await SupabaseConfig.client.from('moods').upsert({
        'user_id': AppState.myId,
        'mood': text,
        'note': text,
        'date': today,
      });
    } catch (e) {
      debugPrint('MoodScreen._save error: $e');
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return SizedBox(width: w, height: h, child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
            _header(w, h),
            _textInputBlock(w, h),
            _previewBlock(w, h),
            _colorGridBlock(w, h),
            _saveBlock(w, h),
          ],
        ));
      },
    );
  }

  Widget _header(double w, double h) {
    final barH = h * 0.07;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _c,
          border: Border.all(color: _c, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(children: [
          TapTile(
            onTap: () { HapticFeedback.heavyImpact(); Navigator.of(context).pop(); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            ),
          ),
          const Expanded(child: Center(
            child: Text('ANIMO', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(width: 44),
        ]),
      ),
    ));
  }

  Widget _textInputBlock(double w, double h) {
    final top = h * 0.08;
    return Positioned(left: w * 0.07, top: top, width: w * 0.85, height: h * 0.11, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Row(children: [
            const Padding(padding: EdgeInsets.only(left: 14), child: Icon(Icons.edit, color: _c, size: 24)),
            Expanded(child: TextField(
              controller: _textCtrl,
              onChanged: (v) => setState(() => _previewEmotion = v.isNotEmpty ? v : ':)'),
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _previewBlock(double w, double h) {
    final top = h * 0.21;
    return Positioned(left: w * 0.30, top: top, width: w * 0.40, height: h * 0.18, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _selectedColor, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Center(child: MoodDisplay(emotion: _previewEmotion, color: _selectedColor, size: h * 0.14)),
        ),
      ),
    );
  }

  Widget _colorGridBlock(double w, double h) {
    final top = h * 0.42;
    const count = 20;
    final squareSize = w * 0.12;

    return Positioned(left: w * 0.05, top: top, width: w * 0.90, height: h * 0.40, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(count, (i) {
                final color = _moodColors[i];
                final selected = _selectedColor == color;
                return TapTile(
                    onTap: () => _selectColor(color),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: squareSize, height: squareSize,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: Colors.black, width: selected ? 5 : 3),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
                        ),
                      ),
                    ),
                  );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveBlock(double w, double h) {
    final top = h * 0.85;
    return Positioned(left: w * 0.20, top: top, width: w * 0.60, height: h * 0.07, child: TapTile(
        onTap: _saveMood,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _c, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Center(child: _saving
              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Icon(Icons.check, color: Colors.white, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}
