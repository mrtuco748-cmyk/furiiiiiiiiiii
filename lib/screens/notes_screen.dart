import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../theme/app_theme.dart';

const _c = Color(0xFFFFDE59);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);
const _black = Color(0xFF000000);
const _noteColors = [
  Color(0xFFFFDE59), Color(0xFFFF6B00), Color(0xFFFF5757),
  Color(0xFFFF1493), Color(0xFFFF66C4), Color(0xFF9D00FF),
  Color(0xFF7000FF), Color(0xFF00F0FF), Color(0xFF00FF66), Color(0xFF39FF14),
];

class NotesScreen extends StatefulWidget {
  final AppMode mode;
  const NotesScreen({super.key, required this.mode});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

enum _PageState { loading, error, empty, data }

class _NotesScreenState extends State<NotesScreen> {
  _PageState _state = _PageState.loading;
  List<Map<String, dynamic>> _notes = const [];
  RealtimeChannel? _channel;
  final _searchCtrl = TextEditingController();
  int _columns = 2;
  bool _adding = false;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  int _selectedColor = 0;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _state = _PageState.loading);
    try {
      final data = await SupabaseConfig.client
          .from('notes')
          .select('*')
          .order('created_at', ascending: false)
          .limit(30);
      if (!mounted) return;
      final notes = List<Map<String, dynamic>>.from(data);
      setState(() {
        _notes = notes;
        _state = notes.isEmpty ? _PageState.empty : _PageState.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _PageState.error);
    }
  }

  void _subscribeRealtime() {
    _channel = SupabaseConfig.client
        .channel('notes_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notes',
          callback: (payload) {
            final row = payload.newRecord;
            if (mounted) {
              setState(() {
                _notes.insert(0, row);
                _state = _PageState.data;
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _addNote() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) return;
    HapticFeedback.heavyImpact();
    final fullContent = title.isNotEmpty && content.isNotEmpty
        ? '$title\n$content'
        : title.isNotEmpty ? title : content;
    try {
      await SupabaseConfig.client.from('notes').insert({
        'user_id': AppState.myId,
        'content': fullContent,
        'color': ['#7000FF', '#FF5757', '#00FF66', '#FFDE59', '#00F0FF'][_selectedColor],
      });
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() => _adding = false);
      _loadNotes();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la nota', style: TextStyle(fontFamily: 'monospace')), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredNotes {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _notes;
    return _notes.where((n) {
      final title = (n['title']?.toString() ?? '').toLowerCase();
      final content = (n['content']?.toString() ?? '').toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showNote(String title, String content, String date, Color tint) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tint, width: 4)),
        title: Text(title, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: tint, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(content, style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          Text(_formatDate(date), style: const TextStyle(fontFamily: 'monospace', color: Colors.white38, fontSize: 11)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Icon(Icons.close, color: _c, size: 28),
          ),
        ],
      ),
    );
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
        if (_adding) return _addView(w, h);
        return SizedBox(width: w, height: h, child: Stack(
          children: [
            bg(),
            _header(w, h),
            _searchBlock(w, h),
            _notesArea(w, h),
            _columnControls(w, h),
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: fillIcon(Icons.arrow_back, Colors.black),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('NOTAS', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ),
          ),
          TapTile(
            onTap: () { HapticFeedback.heavyImpact(); setState(() => _adding = true); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: fillIcon(Icons.add, Colors.black),
            ),
          ),
        ]),
      ),
    ));
  }

  Widget _searchBlock(double w, double h) {
    final top = h * 0.08;
    return Positioned(left: w * 0.10, top: top, width: w * 0.80, height: h * 0.055, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.search, color: _c, size: 20)),
              border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notesArea(double w, double h) {
    final top = h * 0.145;
    final filtered = _filteredNotes;
    final areaW = w * 0.90;

    return Positioned(left: w * 0.05, top: top, width: areaW, height: h * 0.79, child: ClipRRect(
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
            _PageState.empty => _emptyContent(),
            _PageState.data => Padding(
              padding: const EdgeInsets.all(8),
              child: _columns == 1
                  ? ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _noteCard(filtered[i], i),
                    )
                  : _staggeredGrid(filtered, areaW - 16),
            ),
          },
        ),
      ),
    );
  }

  Widget _staggeredGrid(List<Map<String, dynamic>> notes, double areaW) {
    final cardW = (_columns == 2) ? areaW * 0.46 : areaW * 0.30;
    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: notes.asMap().entries.map((entry) {
          return SizedBox(width: cardW, child: _noteCard(entry.value, entry.key));
        }).toList(),
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note, int index) {
    final colorIdx = (note['color_idx'] as int?) ?? 0;
    final tint = _noteColors[colorIdx % _noteColors.length];
    final title = note['title']?.toString() ?? '';
    final content = note['content']?.toString() ?? '';
    final date = note['created_at']?.toString() ?? '';
    final displayText = title.isNotEmpty ? title : (content.length > 50 ? '${content.substring(0, 50)}...' : content);
    final preview = content.isNotEmpty ? (content.length > 30 ? '${content.substring(0, 30)}...' : content) : '';

    return TapTile(
        onTap: () { HapticFeedback.heavyImpact(); _showNote(title, content, date, tint); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tint,
              border: Border.all(color: _black, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (displayText.isNotEmpty)
                  Text(displayText, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (preview.isNotEmpty && title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(preview, style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (displayText.isEmpty)
                  Icon(Icons.note, color: Colors.black.withValues(alpha: 0.5), size: 24),
              ],
            ),
          ),
        ),
      );
  }

  Widget _errorContent() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      fillIcon(Icons.cloud_off, _c),
      const SizedBox(height: 10),
      TapTile(
        onTap: () { HapticFeedback.heavyImpact(); _loadNotes(); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _c, border: Border.all(color: _black, width: 3),
              borderRadius: BorderRadius.circular(14)),
            child: fillIcon(Icons.refresh, Colors.black),
          ),
        ),
      ),
    ]));
  }

  Widget _emptyContent() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      fillIcon(Icons.note_add_outlined, _c),
      const SizedBox(height: 14),
      TapTile(
        onTap: () { HapticFeedback.heavyImpact(); setState(() => _adding = true); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _c, border: Border.all(color: _black, width: 4),
              borderRadius: BorderRadius.circular(18)),
            child: fillIcon(Icons.add, Colors.black),
          ),
        ),
      ),
    ]));
  }

  Widget _columnControls(double w, double h) {
    final right = w * 0.04;
    final top = h * 0.21;
    final btnSize = w * 0.09;
    final icons = [Icons.grid_view, Icons.grid_3x3, Icons.grid_4x4];
    return Positioned(
      right: right, top: top,
      child: Column(children: List.generate(3, (i) => Padding(
        padding: EdgeInsets.only(bottom: i < 2 ? 4 : 0),
        child: _colBtn(i + 2, btnSize, icons[i]),
      ))),
    );
  }

  Widget _colBtn(int n, double size, IconData icon) {
    final active = _columns == n;
    return TapTile(
        onTap: () { HapticFeedback.heavyImpact(); setState(() => _columns = n); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: active ? _c : _mid,
              border: Border.all(color: _c, width: active ? 3 : 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
            ),
            child: Icon(icon, color: active ? Colors.black : _c, size: 18),
          ),
        ),
      );
  }

  Widget _addView(double w, double h) {
    return SizedBox(width: w, height: h, child: Stack(
      children: [
        bg(),
        Positioned(left: 0, top: 0, width: w, height: h * 0.07, child: ClipRRect(
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
                onTap: () { HapticFeedback.heavyImpact(); setState(() => _adding = false); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: fillIcon(Icons.close, Colors.black),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('NUEVA NOTA', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                ),
              ),
              TapTile(
                onTap: _addNote,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: fillIcon(Icons.check, Colors.black),
                ),
              ),
            ]),
          ),
        )),
        Positioned(left: w * 0.05, top: h * 0.10, width: w * 0.90, height: h * 0.10, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _mid,
              border: Border.all(color: _c, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Row(children: [
              const Padding(padding: EdgeInsets.only(left: 14), child: Icon(Icons.title, color: _c, size: 24)),
              Expanded(child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.all(14),
                ),
              )),
            ]),
          ),
        )),
        Positioned(left: w * 0.10, top: h * 0.22, width: w * 0.80, height: h * 0.07, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _noteColors.asMap().entries.map((e) {
            return TapTile(
              onTap: () { HapticFeedback.heavyImpact(); setState(() => _selectedColor = e.key); },
              child: Container(
                width: 30, height: 30, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: e.value, shape: BoxShape.circle,
                  border: Border.all(color: _selectedColor == e.key ? Colors.white : _black, width: _selectedColor == e.key ? 4 : 2),
                  boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 0)],
                ),
              ),
            );
          }).toList(),
        )),
        Positioned(left: w * 0.05, top: h * 0.31, width: w * 0.90, height: h * 0.50, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _mid,
              border: Border.all(color: _c, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(left: 14, top: 14), child: Icon(Icons.edit_note, color: _c, size: 24)),
              Expanded(child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.all(14),
                ),
              )),
            ]),
          ),
        )),
      ],
    ));
  }
}
