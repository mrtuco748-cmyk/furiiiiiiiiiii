import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Widget interior de listas de tareas (checklist) del Pizarrón.
class PizarronChecklistInterior extends StatelessWidget {
  final NoteStyleConfig cfg;
  final bool isEditing;
  final List<TextEditingController> checklistControllers;
  final Widget titleBlock;
  final void Function(NoteStyleConfig updatedConfig) onStyleChanged;

  const PizarronChecklistInterior({
    super.key,
    required this.cfg,
    required this.isEditing,
    required this.checklistControllers,
    required this.titleBlock,
    required this.onStyleChanged,
  });

  CrossAxisAlignment _crossAxisForAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = cfg.checklistItems;
    final textColor = PizarronPalette.parseHex(cfg.bodyColor);
    final titleColor = PizarronPalette.parseHex(cfg.titleColor);
    final itemStyle = PizarronFontCatalog.resolveFont(
      cfg.bodyFont,
      fontSize: cfg.bodySize,
      color: textColor,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: _crossAxisForAlign(cfg.textAlign),
      children: [
        titleBlock,
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            physics: isEditing
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final nextItems = items
                                .map((m) => Map<String, dynamic>.from(m))
                                .toList();
                            final done = nextItems[i]['done'] == true;
                            nextItems[i]['done'] = !done;
                            onStyleChanged(
                              cfg.copyWith(checklistItems: nextItems),
                            );
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: items[i]['done'] == true
                                  ? const Color(0xFF2EE50F)
                                  : textColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: items[i]['done'] == true
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Color(0xFF141820),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: IgnorePointer(
                            ignoring: !isEditing,
                            child: TextField(
                              controller: i < checklistControllers.length
                                  ? checklistControllers[i]
                                  : null,
                              readOnly: !isEditing,
                              style: itemStyle.copyWith(
                                decoration: items[i]['done'] == true
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: items[i]['done'] == true
                                    ? textColor.withValues(alpha: 0.45)
                                    : textColor,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 2),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                final nextItems = items
                                    .map((m) => Map<String, dynamic>.from(m))
                                    .toList();
                                nextItems[i]['text'] = val;
                                onStyleChanged(
                                  cfg.copyWith(checklistItems: nextItems),
                                );
                              },
                            ),
                          ),
                        ),
                        if (isEditing && items.length > 1)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final nextItems = items
                                  .map((m) => Map<String, dynamic>.from(m))
                                  .toList()
                                ..removeAt(i);
                              if (i < checklistControllers.length) {
                                checklistControllers.removeAt(i).dispose();
                              }
                              onStyleChanged(
                                cfg.copyWith(checklistItems: nextItems),
                              );
                            },
                            child: Icon(
                              Icons.remove_circle_rounded,
                              size: 18,
                              color: textColor.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (isEditing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final nextItems = items
                            .map((m) => Map<String, dynamic>.from(m))
                            .toList()
                          ..add({'text': '', 'done': false});
                        onStyleChanged(
                          cfg.copyWith(checklistItems: nextItems),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: titleColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
