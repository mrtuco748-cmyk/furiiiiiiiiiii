import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../models/board_element_v2.dart';
import '../../../app_state.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

class BoardElementPanel extends StatefulWidget {
  final BoardElementV2 element;
  final BoardProviderV2 provider;
  final VoidCallback onClose;

  const BoardElementPanel({
    super.key,
    required this.element,
    required this.provider,
    required this.onClose,
  });

  @override
  State<BoardElementPanel> createState() => _BoardElementPanelState();
}

class _BoardElementPanelState extends State<BoardElementPanel> {
  final _textCtrl = TextEditingController();
  String? _selectedColor;
  String? _selectedFont;

  @override
  void initState() {
    super.initState();
    _textCtrl.text = widget.element.content;
    _selectedColor = widget.element.color;
    _selectedFont = widget.element.fontFamily;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.element.title.isNotEmpty
                            ? widget.element.title
                            : 'Sin título',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Options grid
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PanelOption(
                      icon: Icons.edit,
                      label: 'Editar',
                      color: _userColor(),
                      onTap: () => _showEditDialog(),
                    ),
                    _PanelOption(
                      icon: Icons.palette,
                      label: 'Color',
                      color: const Color(0xFF9D00FF),
                      onTap: () => _showColorPicker(),
                    ),
                    _PanelOption(
                      icon: Icons.text_fields,
                      label: 'Fuente',
                      color: const Color(0xFF00F0FF),
                      onTap: () => _showFontPicker(),
                    ),
                    _PanelOption(
                      icon: Icons.emoji_emotions,
                      label: 'Reacciones',
                      color: const Color(0xFFFFD700),
                      onTap: () => _showReactionPicker(),
                    ),
                    _PanelOption(
                      icon: Icons.mode_comment,
                      label: 'Comentarios',
                      color: const Color(0xFF39FF14),
                      onTap: () => _showComments(),
                    ),
                    _PanelOption(
                      icon: Icons.content_copy,
                      label: 'Duplicar',
                      color: const Color(0xFFFF6B00),
                      onTap: () => _duplicate(),
                    ),
                    _PanelOption(
                      icon:
                          widget.element.isLocked ? Icons.lock : Icons.lock_open,
                      label: widget.element.isLocked
                          ? 'Desbloquear'
                          : 'Bloquear',
                      color: const Color(0xFFFF5757),
                      onTap: () => _toggleLock(),
                    ),
                    _PanelOption(
                      icon: Icons.delete,
                      label: 'Eliminar',
                      color: const Color(0xFFFF0000),
                      onTap: () => _delete(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Color _userColor() {
    final identity = (AppState.identity ?? '').toLowerCase();
    if (identity.contains('facu')) return _accentFacu;
    if (identity.contains('rocio')) return _accentRocio;
    return _accentFacu;
  }

  // ---- EDIT ----

  Future<void> _showEditDialog() async {
    _textCtrl.text = widget.element.content;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Editar contenido',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        content: TextField(
          controller: _textCtrl,
          autofocus: true,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'Contenido...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _textCtrl.text),
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.provider.update(widget.element.copyWith(content: result));
      widget.onClose();
    }
  }

  // ---- COLOR ----

  Future<void> _showColorPicker() async {
    final colors = <String, Color>{
      '#FF5757': const Color(0xFFFF5757),
      '#FFDE59': const Color(0xFFFFDE59),
      '#00FF66': const Color(0xFF00FF66),
      '#00F0FF': const Color(0xFF00F0FF),
      '#FF66C4': const Color(0xFFFF66C4),
      '#9D00FF': const Color(0xFF9D00FF),
      '#FF8800': const Color(0xFFFF8800),
      '#0088FF': const Color(0xFF0088FF),
      '#1A1A1A': const Color(0xFF1A1A1A),
      '#333333': const Color(0xFF333333),
    };

    String? selected;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Color de fondo',
            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.entries.map((e) {
              final isSelected = selected == e.key ||
                  (selected == null && widget.element.color == e.key);
              return GestureDetector(
                onTap: () {
                  setDlg(() => selected = e.key);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: e.value,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4FC3F7)
                          : const Color(0xFF333333),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (selected != null) {
                  widget.provider
                      .update(widget.element.copyWith(color: selected));
                  widget.onClose();
                }
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar',
                  style: TextStyle(color: Color(0xFF4FC3F7))),
            ),
          ],
        ),
      ),
    );
  }

  // ---- FONT ----

  Future<void> _showFontPicker() async {
    final fonts = [
      'monospace',
      'Roboto',
      'Courier',
      'Arial',
      'Georgia',
      'Verdana',
      'Times',
      'Comic Sans MS',
    ];

    String? selected = widget.element.fontFamily;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Fuente',
            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: fonts.map((f) {
                final isSelected = selected == f;
                return ListTile(
                  title: Text(
                    f,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: f,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF4FC3F7))
                      : null,
                  onTap: () => setDlg(() => selected = f),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (selected != null) {
                  widget.provider
                      .update(widget.element.copyWith(fontFamily: selected));
                  widget.onClose();
                }
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar',
                  style: TextStyle(color: Color(0xFF4FC3F7))),
            ),
          ],
        ),
      ),
    );
  }

  // ---- REACTIONS ----

  Future<void> _showReactionPicker() async {
    final emojis = ['🥰', '😘', '😍', ':v', 'xD', ':0'];
    // For now, just show a dialog - reactions need a data model
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Reacciones',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        content: Wrap(
          spacing: 12,
          children: emojis
              .map((e) => GestureDetector(
                    onTap: () {
                      // Add reaction to element data
                      final currentReactions =
                          widget.element.data['reactions'] as Map? ?? {};
                      final myId = AppState.myId ?? '';
                      final keyReactions =
                          currentReactions[e] as List? ?? [];
                      if (!keyReactions.contains(myId)) {
                        keyReactions.add(myId);
                        currentReactions[e] = keyReactions;
                        widget.provider.update(widget.element.copyWith(
                          data: {...widget.element.data, 'reactions': currentReactions},
                        ));
                      }
                      Navigator.pop(ctx);
                      widget.onClose();
                    },
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- COMMENTS ----

  Future<void> _showComments() async {
    final inputCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final comments = _liveComments();
          return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Comentarios',
            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (comments.isEmpty)
                  const Text(
                    'Sin comentarios',
                    style: TextStyle(color: Colors.white54),
                  ),
                ...comments.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4FC3F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                ((c['user'] as String?) ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF0A0A0A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c['text'] as String? ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inputCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Escribí un comentario...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF4FC3F7)),
                      onPressed: () {
                        final text = inputCtrl.text.trim();
                        if (text.isEmpty) return;
                        final current = _liveComments();
                        final newComments = List<Map>.from(current);
                        newComments.add({
                          'user': AppState.identity ?? '?',
                          'text': text,
                          'time': DateTime.now().millisecondsSinceEpoch,
                        });
                        widget.provider.update(widget.element.copyWith(
                          data: {
                            ...widget.element.data,
                            'comments': newComments,
                          },
                        ));
                        inputCtrl.clear();
                        setDlg(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
        },
      ),
    );
  }

  List<Map> _liveComments() {
    final id = widget.element.id;
    if (id == null) {
      return (widget.element.data['comments'] as List?)?.cast<Map>() ?? [];
    }
    for (final e in widget.provider.elements) {
      if (e.id == id) {
        return (e.data['comments'] as List?)?.cast<Map>() ?? [];
      }
    }
    return (widget.element.data['comments'] as List?)?.cast<Map>() ?? [];
  }

  // ---- DUPLICATE ----

  void _duplicate() {
    HapticFeedback.heavyImpact();
    final dup = widget.element.copyWith(
      id: null,
      x: widget.element.x + 20,
      y: widget.element.y + 20,
      isNew: true,
    );
    widget.provider.add(dup);
    widget.onClose();
  }

  // ---- TOGGLE LOCK ----

  void _toggleLock() {
    HapticFeedback.selectionClick();
    widget.provider
        .update(widget.element.copyWith(isLocked: !widget.element.isLocked));
    widget.onClose();
  }

  // ---- DELETE ----

  void _delete() {
    HapticFeedback.heavyImpact();
    if (widget.element.id != null) {
      widget.provider.delete(widget.element.id!);
    }
    widget.onClose();
  }
}

class _PanelOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PanelOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
