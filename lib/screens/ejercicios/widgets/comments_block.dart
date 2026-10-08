import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/workout_social.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

class CommentsBlock extends StatefulWidget {
  final List<WorkoutComment> comments;
  final void Function(String text) onAdd;
  final void Function(String commentId) onDelete;
  final void Function() refresh;

  const CommentsBlock(
    this.comments,
    this.onAdd,
    this.onDelete,
    this.refresh, {
    super.key,
  });

  @override
  State<CommentsBlock> createState() => _CommentsBlockState();
}

class _CommentsBlockState extends State<CommentsBlock> {
  late final TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<WorkoutProvider>().myId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: EjerciciosStyle.cyan, size: 18),
            const SizedBox(width: 6),
            Text(
              'Comentarios',
              style: GoogleFonts.bangers(
                color: EjerciciosStyle.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.comments.isEmpty)
          Text(
            'Sin comentarios',
            style: GoogleFonts.bangers(
              color: EjerciciosStyle.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          )
        else
          for (final c in widget.comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.replyToId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.subdirectory_arrow_right,
                          color: EjerciciosStyle.white.withValues(alpha: 0.4), size: 14),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.text,
                      style: GoogleFonts.bangers(
                        color: EjerciciosStyle.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (c.userId == myId)
                    TapTile(
                      onTap: () async {
                        widget.onDelete(c.id);
                        widget.refresh();
                      },
                      child:
                          const Icon(Icons.close, color: EjerciciosStyle.red, size: 16),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLength: 1000,
                style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 13),
                decoration: EjerciciosStyle.inputDeco('Comentar...').copyWith(
                  counterText: '',
                ),
                onSubmitted: (text) async {
                  if (text.trim().isEmpty) return;
                  widget.onAdd(text);
                  ctrl.clear();
                  widget.refresh();
                },
              ),
            ),
            const SizedBox(width: 6),
            TapTile(
              onTap: () async {
                if (ctrl.text.trim().isEmpty) return;
                widget.onAdd(ctrl.text);
                ctrl.clear();
                widget.refresh();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: EjerciciosStyle.cyan,
                  border: Border.all(color: EjerciciosStyle.cyan, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send, color: EjerciciosStyle.darkText, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}