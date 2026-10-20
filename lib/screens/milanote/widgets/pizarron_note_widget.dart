import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/board_element.dart';
import '../models/active_text_target.dart';
import '../models/note_style_config.dart';
import 'pizarron_body_interior.dart';
import 'pizarron_card_frame.dart';
import 'pizarron_checklist_interior.dart';
import 'pizarron_inline_image.dart';
import 'pizarron_paragraph_state_helper.dart';
import 'pizarron_title_block.dart';

export '../models/active_text_target.dart';

/// El objeto único de Nota / Lista de Tareas del Pizarrón.
class PizarronNoteWidget extends StatefulWidget {
  final BoardElement element;
  final NoteStyleConfig styleConfig;
  final bool isEditing;
  final double Function() getCurrentCanvasScale;
  final VoidCallback onTapNote;
  final void Function(ActiveTextTarget target)? onTapWithTarget;
  final void Function(double dxWorld, double dyWorld) onDragNote;
  final void Function(double dwWorld, double dhWorld) onResizeNote;
  final void Function(double scaleFactor, Offset focalWorld) onPinchScaleNote;
  final void Function(String newTitle, String newContent) onTextChanged;
  final void Function(NoteStyleConfig updatedConfig) onStyleChanged;
  final void Function(ActiveTextTarget target) onActiveTargetChanged;
  final ActiveTextTarget activeTarget;

  const PizarronNoteWidget({
    super.key,
    required this.element,
    required this.styleConfig,
    required this.isEditing,
    required this.getCurrentCanvasScale,
    required this.onTapNote,
    this.onTapWithTarget,
    required this.onDragNote,
    required this.onResizeNote,
    required this.onPinchScaleNote,
    required this.onTextChanged,
    required this.onStyleChanged,
    required this.onActiveTargetChanged,
    required this.activeTarget,
  });

  @override
  State<PizarronNoteWidget> createState() => _PizarronNoteWidgetState();
}

class _PizarronNoteWidgetState extends State<PizarronNoteWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();

  final List<TextEditingController> _paragraphControllers = [];
  final List<FocusNode> _paragraphFocusNodes = [];
  final List<TextEditingController> _checklistControllers = [];

  late AnimationController _shineController;
  String? _cachedBgBase64Key;
  Uint8List? _cachedBgBytes;
  String? _cachedInlineBase64Key;
  Uint8List? _cachedInlineBytes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.element.title);
    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) {
        widget.onActiveTargetChanged(const ActiveTextTarget.title());
      }
    });

    _syncParagraphs(widget.element.content);
    _syncChecklists();
    _shineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    if (widget.styleConfig.hasShine) _shineController.repeat();
    _updateCaches();
    if (widget.isEditing) _applyTargetFocus(widget.activeTarget);
  }

  @override
  void didUpdateWidget(covariant PizarronNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.styleConfig.hasShine != oldWidget.styleConfig.hasShine) {
      widget.styleConfig.hasShine ? _shineController.repeat() : _shineController.reset();
    }
    if (!widget.isEditing) {
      if (_titleController.text != widget.element.title) _titleController.text = widget.element.title;
      final currentJoined = _paragraphControllers.map((c) => c.text).join('\n');
      if (currentJoined != widget.element.content) _syncParagraphs(widget.element.content);
    } else if (oldWidget.element.id != widget.element.id) {
      _titleController.text = widget.element.title;
      _syncParagraphs(widget.element.content);
    }
    if ((!oldWidget.isEditing && widget.isEditing) ||
        (widget.isEditing && widget.activeTarget != oldWidget.activeTarget)) {
      _applyTargetFocus(widget.activeTarget);
    }
    _syncChecklists();
    _updateCaches();
  }

  void _applyTargetFocus(ActiveTextTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isEditing) return;
      if (target.isTitle) {
        if (!_titleFocus.hasFocus) _titleFocus.requestFocus();
      } else if (target.paragraphIndex != null) {
        final i = target.paragraphIndex!;
        if (i >= 0 && i < _paragraphFocusNodes.length && !_paragraphFocusNodes[i].hasFocus) {
          _paragraphFocusNodes[i].requestFocus();
        }
      } else if (_paragraphFocusNodes.isNotEmpty && !_paragraphFocusNodes.any((f) => f.hasFocus)) {
        _paragraphFocusNodes.last.requestFocus();
      }
    });
  }

  void _updateCaches() {
    if (widget.styleConfig.bgImageBase64 != _cachedBgBase64Key) {
      _cachedBgBase64Key = widget.styleConfig.bgImageBase64;
      _cachedBgBytes = PizarronInlineImageWidget.tryDecodeBase64(_cachedBgBase64Key);
    }
    if (widget.styleConfig.inlineImageBase64 != _cachedInlineBase64Key) {
      _cachedInlineBase64Key = widget.styleConfig.inlineImageBase64;
      _cachedInlineBytes = PizarronInlineImageWidget.tryDecodeBase64(_cachedInlineBase64Key);
    }
  }

  void _syncParagraphs(String content) {
    PizarronParagraphStateHelper.syncControllers(
      content: content,
      controllers: _paragraphControllers,
      focusNodes: _paragraphFocusNodes,
      onActiveTargetChanged: widget.onActiveTargetChanged,
    );
  }

  void _syncChecklists() {
    if (widget.element.type != 'checklist') return;
    final items = widget.styleConfig.checklistItems;
    while (_checklistControllers.length > items.length) {
      _checklistControllers.removeLast().dispose();
    }
    for (int i = 0; i < items.length; i++) {
      final text = items[i]['text']?.toString() ?? '';
      if (i < _checklistControllers.length) {
        if (!widget.isEditing && _checklistControllers[i].text != text) {
          _checklistControllers[i].text = text;
        }
      } else {
        _checklistControllers.add(TextEditingController(text: text));
      }
    }
  }

  void _handleParagraphChanged(int index, String value) {
    PizarronParagraphStateHelper.handleSplitOnEnter(
      index: index,
      value: value,
      controllers: _paragraphControllers,
      focusNodes: _paragraphFocusNodes,
      styleConfig: widget.styleConfig,
      onStyleChanged: widget.onStyleChanged,
      onActiveTargetChanged: widget.onActiveTargetChanged,
      onRebindNeeded: () => PizarronParagraphStateHelper.rebindFocusNodes(
        focusNodes: _paragraphFocusNodes,
        onActiveTargetChanged: widget.onActiveTargetChanged,
      ),
      onStateRefreshed: () => setState(() {}),
    );
    widget.onTextChanged(
      _titleController.text,
      _paragraphControllers.map((c) => c.text).join('\n'),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    for (final c in _paragraphControllers) {
      c.dispose();
    }
    for (final f in _paragraphFocusNodes) {
      f.dispose();
    }
    for (final c in _checklistControllers) {
      c.dispose();
    }
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = math.max(120.0, widget.element.width);
    final h = math.max(100.0, widget.element.height);
    final cfg = widget.styleConfig;

    final titleBlock = PizarronTitleBlock(
      cfg: cfg,
      isEditing: widget.isEditing,
      controller: _titleController,
      focusNode: _titleFocus,
      activeTarget: widget.activeTarget,
      onFocusRequested: () {
        if (widget.isEditing) {
          _titleFocus.requestFocus();
          widget.onActiveTargetChanged(const ActiveTextTarget.title());
        } else if (widget.onTapWithTarget != null) {
          widget.onTapWithTarget!(const ActiveTextTarget.title());
        } else {
          widget.onTapNote();
        }
      },
      onSubmitted: () {
        if (_paragraphFocusNodes.isNotEmpty) {
          _paragraphFocusNodes.first.requestFocus();
          widget.onActiveTargetChanged(const ActiveTextTarget.paragraph(0));
        }
      },
      onChanged: () => widget.onTextChanged(
        _titleController.text,
        _paragraphControllers.map((c) => c.text).join('\n'),
      ),
    );

    return PizarronCardFrame(
      size: Size(w, h),
      cfg: cfg,
      isEditing: widget.isEditing,
      cachedBgBytes: _cachedBgBytes,
      shineController: _shineController,
      getCurrentCanvasScale: widget.getCurrentCanvasScale,
      onResizeNote: widget.onResizeNote,
      child: widget.element.type == 'checklist'
          ? PizarronChecklistInterior(
              cfg: cfg,
              isEditing: widget.isEditing,
              checklistControllers: _checklistControllers,
              titleBlock: titleBlock,
              onStyleChanged: widget.onStyleChanged,
            )
          : Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                titleBlock,
                const SizedBox(height: 6),
                Expanded(
                  child: PizarronBodyInterior(
                    cfg: cfg,
                    isEditing: widget.isEditing,
                    paragraphControllers: _paragraphControllers,
                    paragraphFocusNodes: _paragraphFocusNodes,
                    activeTarget: widget.activeTarget,
                    cachedInlineBytes: _cachedInlineBytes,
                    cardHeight: h,
                    onParagraphChanged: _handleParagraphChanged,
                    onTargetFocused: (t) {
                      if (widget.isEditing) {
                        widget.onActiveTargetChanged(t);
                      } else if (widget.onTapWithTarget != null) {
                        widget.onTapWithTarget!(t);
                      } else {
                        widget.onTapNote();
                      }
                    },
                    onBodyAreaTapped: () {
                      if (widget.isEditing) {
                        if (_paragraphFocusNodes.isNotEmpty) {
                          _paragraphFocusNodes.last.requestFocus();
                          widget.onActiveTargetChanged(
                            ActiveTextTarget.paragraph(_paragraphFocusNodes.length - 1),
                          );
                        }
                      } else if (widget.onTapWithTarget != null) {
                        widget.onTapWithTarget!(const ActiveTextTarget.bodyDefault());
                      } else {
                        widget.onTapNote();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
