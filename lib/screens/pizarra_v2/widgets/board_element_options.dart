import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_state.dart';
import '../../../models/board_element_v2.dart';
import '../../../providers/board_provider_v2.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);
const _panel = Color(0xFF1A1A1A);
const _darkBg = Color(0xFF0A0A0A);

/// Lógica pura de reacciones y comentarios embebidos en `el.data`.
/// Mismo formato que el chat: `{'key': [userId, ...]}` max 5 keys.
class BoardSocialData {
  static const int maxReactions = 5;
  static const List<String> defaultEmojis = ['🥰', '😘', '😍', ':v', 'xD', ':0'];

  static Map<String, List<String>> reactionsOf(Map<String, dynamic> data) {
    final raw = data['reactions'];
    if (raw is! Map) return {};
    final out = <String, List<String>>{};
    for (final e in raw.entries) {
      final v = e.value;
      out[e.key] =
          v is List ? List<String>.from(v.map((x) => x.toString())) : <String>[];
    }
    return out;
  }

  static Map<String, dynamic> withToggledReaction(
    Map<String, dynamic> data, {
    required String userId,
    required String key,
  }) {
    final next = reactionsOf(data);
    final already = next[key]?.contains(userId) ?? false;

    // Quitar mi id de todas las keys (1 reacción por usuario por key).
    for (final k in next.keys.toList()) {
      next[k] = next[k]!.where((id) => id != userId).toList();
      if (next[k]!.isEmpty) next.remove(k);
    }

    if (!already) {
      if (!next.containsKey(key) && next.length >= maxReactions) return data;
      next.putIfAbsent(key, () => <String>[]).add(userId);
    }

    final out = Map<String, dynamic>.from(data);
    out['reactions'] = next.map((k, v) => MapEntry(k, v));
    return out;
  }

  static List<Map<String, dynamic>> commentsOf(Map<String, dynamic> data) {
    final raw = data['comments'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  static Map<String, dynamic> withCommentAdded(
    Map<String, dynamic> data, {
    required String userId,
    required String text,
    String? replyToId,
  }) {
    final comments = commentsOf(data);
    comments.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': userId,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
      'replyToId': ?replyToId,
    });
    final out = Map<String, dynamic>.from(data);
    out['comments'] = comments;
    return out;
  }

  static Map<String, dynamic> withCommentEdited(
    Map<String, dynamic> data, {
    required String commentId,
    required String newText,
  }) {
    final comments = commentsOf(data);
    for (final c in comments) {
      if (c['id']?.toString() == commentId) {
        c['text'] = newText;
        break;
      }
    }
    final out = Map<String, dynamic>.from(data);
    out['comments'] = comments;
    return out;
  }

  static Map<String, dynamic> withCommentRemoved(
    Map<String, dynamic> data,
    String commentId,
  ) {
    final allComments = commentsOf(data);
    // BUG 7: Cascade-delete replies to the deleted comment.
    final toRemove = <String>{commentId};
    for (final c in allComments) {
      if (c['replyToId']?.toString() == commentId) {
        toRemove.add(c['id'] as String);
      }
    }
    final remaining =
        allComments.where((c) => !toRemove.contains(c['id'])).toList();
    final out = Map<String, dynamic>.from(data);
    out['comments'] = remaining;
    return out;
  }
}

String _initial(String uid) {
  final u = uid.toLowerCase();
  if (u.contains('facu')) return 'F';
  if (u.contains('rocio')) return 'R';
  return uid.isEmpty ? '?' : uid.substring(0, 1).toUpperCase();
}

Color _authorColor(String uid) {
  final u = uid.toLowerCase();
  if (u.contains('facu')) return _accentFacu;
  if (u.contains('rocio')) return _accentRocio;
  return _accentFacu;
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'hace ${diff.inHours}h';
  return 'hace ${diff.inDays}d';
}

String _typeIcon(BoardElementV2 el) {
  switch (el.type) {
    case BoardElementType.checklist:
      return '✓';
    case BoardElementType.drawing:
      return '✎';
    case BoardElementType.video:
      return '▶';
    case BoardElementType.audio:
      return '🎤';
    default:
      return '📝';
  }
}

// ▸▸▸ BOTTOM SHEET DE OPCIONES DEL ELEMENTO ▸▸▸

Future<void> showElementOptionsSheet(
  BuildContext context,
  BoardProviderV2 pv,
  BoardElementV2 el,
) async {
  HapticFeedback.heavyImpact();
  final userId = AppState.myId ?? '';

  await showModalBottomSheet(
    context: context,
    backgroundColor: _panel,
    barrierColor: Colors.black26,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final live = pv.findById(el.id) ?? el;
          final reactions = BoardSocialData.reactionsOf(live.data);
          final commentCount = BoardSocialData.commentsOf(live.data).length;

          void react(String key) {
            final live = pv.findById(el.id) ?? el;
            final newData = BoardSocialData.withToggledReaction(
              live.data,
              userId: userId,
              key: key,
            );
            // BUG 6: Si withToggledReaction devuelve la misma referencia,
            // el límite de 5 reacciones fue alcanzado.
            if (identical(newData, live.data)) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Máximo 5 reacciones por elemento',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF2A2A2A),
                ),
              );
              HapticFeedback.heavyImpact();
              setSheetState(() {});
              return;
            }
            try {
              pv.react(live, newData, key);
              setSheetState(() {});
              HapticFeedback.selectionClick();
            } catch (e) {
              debugPrint('BoardElementOptions.react error: $e');
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Error al guardar reacción',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }

          void customReact() {
            final ctrl = TextEditingController();
            showDialog(
              context: ctx,
              builder: (dctx) => AlertDialog(
                backgroundColor: _panel,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                content: TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLength: 10,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Emoji o texto...',
                    hintStyle:
                        TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      react(v.trim());
                      Navigator.of(dctx).pop();
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dctx).pop(),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        react(ctrl.text.trim());
                      }
                      Navigator.of(dctx).pop();
                    },
                    child: const Text('Agregar',
                        style: TextStyle(color: _accentFacu)),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_typeIcon(live)} ${live.title.isNotEmpty ? live.title : 'Elemento'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF2A2A2A), width: 1.5),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Barra de reacciones
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emoji in BoardSocialData.defaultEmojis)
                        _reactionChip(
                          emoji,
                          reactions[emoji] ?? const [],
                          userId,
                          react,
                        ),
                      for (final entry in reactions.entries)
                        if (!BoardSocialData.defaultEmojis
                            .contains(entry.key))
                          _reactionChip(
                              entry.key, entry.value, userId, react),
                      GestureDetector(
                        onTap: customReact,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF2A2A2A), width: 1.5),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white70, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Acciones
                  Row(
                    children: [
                      _actionButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Comentarios${
                            commentCount > 0 ? ' ($commentCount)' : ''}',
                        color: _accentFacu,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          showCommentsSheet(context, pv, el);
                        },
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.copy,
                        label: 'Duplicar',
                        color: const Color(0xFF39FF14),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _duplicateElement(context, pv, el);
                        },
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.archive,
                        label: 'Archivar',
                        color: const Color(0xFFFFD700),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          if (live.id != null) pv.toggleArchive(live.id!);
                        },
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.delete_outline,
                        label: 'Eliminar',
                        color: const Color(0xFFFF5757),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _confirmDelete(context, pv, live);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _reactionChip(
  String key,
  List<String> userIds,
  String myId,
  void Function(String) onTap,
) {
  final mine = userIds.contains(myId);
  final color = mine ? _accentFacu : const Color(0xFF2A2A2A);
  return GestureDetector(
    onTap: () => onTap(key),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        userIds.isEmpty ? key : '$key ${userIds.length}',
        style: TextStyle(
          color: mine ? _darkBg : Colors.white70,
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: mine ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}

Widget _actionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _duplicateElement(
    BuildContext context, BoardProviderV2 pv, BoardElementV2 el) {
  pv.add(el.copyWith(
    clearId: true,
    x: el.x + 30,
    y: el.y + 30,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    userId: AppState.myId,
    isNew: true,
  ));
  HapticFeedback.selectionClick();
}

void _confirmDelete(
    BuildContext context, BoardProviderV2 pv, BoardElementV2 el) {
  showDialog(
    context: context,
    builder: (ctx) => Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _darkBg, width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('¿Eliminar elemento?',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            el.title.isNotEmpty ? '"${el.title}"' : 'Sin título',
            style: const TextStyle(
                color: Colors.white70, fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(
                        color: Colors.white70, fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                if (el.id != null) pv.delete(el.id!);
                Navigator.of(ctx).pop();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5757),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF5757), width: 1.5),
                ),
                child: const Text('Eliminar',
                    style: TextStyle(
                        color: Color(0xFF0A0A0A),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
}

// ▸▸▸ BOTTOM SHEET DE COMENTARIOS ▸▸▸

Future<void> showCommentsSheet(
  BuildContext context,
  BoardProviderV2 pv,
  BoardElementV2 el,
) async {
  HapticFeedback.selectionClick();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _panel,
    barrierColor: Colors.black26,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CommentsSheet(pv: pv, el: el),
  );
}

class _CommentsSheet extends StatefulWidget {
  final BoardProviderV2 pv;
  final BoardElementV2 el;

  const _CommentsSheet({required this.pv, required this.el});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _inputCtrl = TextEditingController();
  Map<String, dynamic>? _replyingTo;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final live = widget.pv.findById(widget.el.id) ?? widget.el;
    final newData = BoardSocialData.withCommentAdded(
      live.data,
      userId: AppState.myId ?? '',
      text: text,
      replyToId: _replyingTo?['id'] as String?,
    );
    widget.pv.update(live.copyWith(data: newData));
    _inputCtrl.clear();
    setState(() => _replyingTo = null);
    HapticFeedback.selectionClick();
  }

  void _delete(Map<String, dynamic> comment) {
    final live = widget.pv.findById(widget.el.id) ?? widget.el;
    final newData = BoardSocialData.withCommentRemoved(
      live.data,
      comment['id'] as String,
    );
    widget.pv.update(live.copyWith(data: newData));
    setState(() {});
    HapticFeedback.heavyImpact();
  }

  Future<void> _edit(Map<String, dynamic> comment) async {
    final ctrl = TextEditingController(text: comment['text'] as String? ?? '');
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 1000,
          style:
              const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'Editar comentario...',
            hintStyle:
                TextStyle(color: Colors.white54, fontFamily: 'monospace'),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child:
                const Text('Guardar', style: TextStyle(color: _accentFacu)),
          ),
        ],
      ),
    );
    if (newText == null || newText.isEmpty || newText == comment['text']) {
      return;
    }
    final live = widget.pv.findById(widget.el.id) ?? widget.el;
    final newData = BoardSocialData.withCommentEdited(
      live.data,
      commentId: comment['id'] as String,
      newText: newText,
    );
    widget.pv.update(live.copyWith(data: newData));
    setState(() {});
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.pv,
      builder: (context, _) {
        final live = widget.pv.findById(widget.el.id) ?? widget.el;
        final comments = BoardSocialData.commentsOf(live.data);
        final top = comments.where((c) => c['replyToId'] == null).toList();
        final byParent = <String, List<Map<String, dynamic>>>{};
        for (final c in comments) {
          final parentId = c['replyToId'];
          if (parentId != null) {
            byParent.putIfAbsent(parentId.toString(), () => []).add(c);
          }
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Comentarios ${comments.isEmpty ? '' : '(${comments.length})'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF2A2A2A), width: 1.5),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Sin comentarios todavía. ¡Escribí el primero!',
                            style: TextStyle(
                              color: Colors.white54,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final c in top) ...[
                              _commentRow(context, c, false, comments),
                              for (final r in byParent[c['id']] ?? [])
                                _commentRow(context, r, true, comments),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_replyingTo != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Respondiendo a "${_truncate(_replyingTo!['text'])}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _accentFacu,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _replyingTo = null),
                              child: const Icon(Icons.close,
                                  color: Colors.white54, size: 14),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputCtrl,
                              maxLines: null,
                              minLines: 1,
                              maxLength: 1000,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Escribí un comentario...',
                                hintStyle: const TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'monospace'),
                                filled: true,
                                fillColor: const Color(0xFF2A2A2A),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _send,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _accentFacu,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _accentFacu, width: 2),
                              ),
                              child: const Icon(Icons.send,
                                  color: _darkBg, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _commentRow(
    BuildContext context,
    Map<String, dynamic> c,
    bool isReply,
    List<Map<String, dynamic>> all,
  ) {
    final mine = c['userId'] == AppState.myId;
    final repliedTo = c['replyToId'] != null
        ? all.where((x) => x['id'] == c['replyToId']).firstOrNull
        : null;
    final createdAt = DateTime.tryParse(c['createdAt'] as String? ?? '') ??
        DateTime.now();

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 28 : 0, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _authorColor(c['userId'] as String? ?? ''),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                _initial(c['userId'] as String? ?? ''),
                style: const TextStyle(
                  color: _darkBg,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (repliedTo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '→ "${_truncate(repliedTo['text'])}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Text(
                  c['text'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _timeAgo(createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _replyingTo = c),
                      child: const Text(
                        'Responder',
                        style: TextStyle(
                          color: _accentFacu,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _delete(c),
                        child: const Text(
                          'Borrar',
                          style: TextStyle(
                            color: Color(0xFFFF5757),
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(dynamic text) {
    final s = text?.toString() ?? '';
    return s.length > 60 ? '${s.substring(0, 60)}...' : s;
  }
}
