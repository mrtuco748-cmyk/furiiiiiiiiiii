import 'package:flutter/material.dart';
import '../models/active_text_target.dart';
import '../models/note_style_config.dart';

/// Gestor de sincronización de párrafos y controladores de texto para notas del Pizarrón.
class PizarronParagraphStateHelper {
  static void syncControllers({
    required String content,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required void Function(ActiveTextTarget target) onActiveTargetChanged,
  }) {
    final lines = content.isEmpty ? <String>[''] : content.split('\n');
    while (controllers.length > lines.length) {
      controllers.removeLast().dispose();
      focusNodes.removeLast().dispose();
    }
    for (int i = 0; i < lines.length; i++) {
      if (i < controllers.length) {
        if (controllers[i].text != lines[i]) {
          controllers[i].text = lines[i];
        }
      } else {
        final ctrl = TextEditingController(text: lines[i]);
        final fn = FocusNode();
        final idx = i;
        fn.addListener(() {
          if (fn.hasFocus) {
            onActiveTargetChanged(ActiveTextTarget.paragraph(idx));
          }
        });
        controllers.add(ctrl);
        focusNodes.add(fn);
      }
    }
  }

  static void handleSplitOnEnter({
    required int index,
    required String value,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required NoteStyleConfig styleConfig,
    required void Function(NoteStyleConfig updatedConfig) onStyleChanged,
    required void Function(ActiveTextTarget target) onActiveTargetChanged,
    required VoidCallback onRebindNeeded,
    required VoidCallback onStateRefreshed,
  }) {
    if (!value.contains('\n')) return;

    final parts = value.split('\n');
    controllers[index].text = parts.first;
    final rest = parts.sublist(1).join(' ');

    final newCtrl = TextEditingController(text: rest);
    final newFn = FocusNode();
    final insertIdx = index + 1;

    controllers.insert(insertIdx, newCtrl);
    focusNodes.insert(insertIdx, newFn);
    onRebindNeeded();

    final current =
        Map<int, ParagraphStyleOverride>.from(styleConfig.paragraphOverrides);
    final updated = <int, ParagraphStyleOverride>{};
    current.forEach((k, v) {
      if (k < insertIdx) {
        updated[k] = v;
      } else {
        updated[k + 1] = v;
      }
    });
    if (current.containsKey(index)) updated[insertIdx] = current[index]!;
    onStyleChanged(styleConfig.copyWith(paragraphOverrides: updated));

    onStateRefreshed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (insertIdx < focusNodes.length) {
        focusNodes[insertIdx].requestFocus();
        onActiveTargetChanged(ActiveTextTarget.paragraph(insertIdx));
      }
    });
  }

  static void rebindFocusNodes({
    required List<FocusNode> focusNodes,
    required void Function(ActiveTextTarget target) onActiveTargetChanged,
  }) {
    for (int i = 0; i < focusNodes.length; i++) {
      final idx = i;
      final oldNode = focusNodes[i];
      final hadFocus = oldNode.hasFocus;
      oldNode.dispose();
      final newNode = FocusNode();
      newNode.addListener(() {
        if (newNode.hasFocus) {
          onActiveTargetChanged(ActiveTextTarget.paragraph(idx));
        }
      });
      focusNodes[i] = newNode;
      if (hadFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          newNode.requestFocus();
        });
      }
    }
  }
}
