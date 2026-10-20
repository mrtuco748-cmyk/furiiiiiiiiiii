import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_state.dart';
import '../../../supabase_config.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/tap_tile.dart';

/// Diálogo modal para crear o editar una meta de la pareja.
class MetaEditDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final ThemeSet theme;
  final VoidCallback onSaved;

  const MetaEditDialog({
    super.key,
    this.existing,
    required this.theme,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? existing,
    required ThemeSet theme,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => MetaEditDialog(
        existing: existing,
        theme: theme,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<MetaEditDialog> createState() => _MetaEditDialogState();
}

class _MetaEditDialogState extends State<MetaEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.existing?['title'] ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?['description'] ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context);

    try {
      if (widget.existing != null) {
        await SupabaseConfig.client
            .from('goals')
            .update({
              'title': title,
              'description': _descCtrl.text.trim(),
            })
            .eq('id', widget.existing!['id']);
      } else {
        await SupabaseConfig.client.from('goals').insert({
          'couple_id': AppState.myId,
          'title': title,
          'description': _descCtrl.text.trim(),
        });
      }
      if (mounted) AppFeedback.saved(context, 'Meta guardada');
      widget.onSaved();
    } catch (e) {
      developer.log('guardar meta fallo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AlertDialog(
      backgroundColor: t.mid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Icon(
        widget.existing != null ? Icons.edit : Icons.emoji_events,
        color: t.light,
        size: 34,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: GoogleFonts.bangers(color: t.light),
            decoration: InputDecoration(
              hintText: 'Titulo...',
              hintStyle: GoogleFonts.bangers(
                  color: t.light.withValues(alpha: 0.4)),
              filled: true,
              fillColor: t.e.withValues(alpha: 0.25),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            style: GoogleFonts.bangers(color: t.light),
            decoration: InputDecoration(
              hintText: 'Descripcion...',
              hintStyle: GoogleFonts.bangers(
                  color: t.light.withValues(alpha: 0.4)),
              filled: true,
              fillColor: t.e.withValues(alpha: 0.25),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: t.mid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.close, color: t.light, size: 20),
          ),
        ),
        TapTile(
          onTap: _submit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: t.e,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check, color: t.light, size: 20),
          ),
        ),
      ],
    );
  }
}
