import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'pizarron_camera_math.dart';

/// Controlador de animación y límites de cámara para el Pizarrón.
class PizarronCameraController {
  final TickerProvider vsync;
  final VoidCallback onTick;

  Offset cameraPan = Offset.zero;
  double cameraScale = 1.0;
  static const double minScale = 0.35;
  static const double maxScale = 2.40;

  late final AnimationController animController;
  Offset _animStartPan = Offset.zero;
  Offset _animTargetPan = Offset.zero;
  double _animStartScale = 1.0;
  double _animTargetScale = 1.0;

  PizarronCameraController({
    required this.vsync,
    required this.onTick,
  }) {
    animController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 340),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(animController.value);
        cameraPan = Offset.lerp(_animStartPan, _animTargetPan, t)!;
        cameraScale = ui.lerpDouble(_animStartScale, _animTargetScale, t)!;
        onTick();
      });
  }

  void animateTo({required Offset targetPan, required double targetScale}) {
    animController.stop();
    _animStartPan = cameraPan;
    _animTargetPan = targetPan;
    _animStartScale = cameraScale;
    _animTargetScale = targetScale.clamp(minScale, maxScale);
    animController.forward(from: 0.0);
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      animController.stop();
      final zoom = event.scrollDelta.dy < 0 ? 1.12 : 0.89;
      final newScale = (cameraScale * zoom).clamp(minScale, maxScale);
      final focal = PizarronCameraMath.screenToWorld(
        event.localPosition,
        cameraPan,
        cameraScale,
      );
      cameraScale = newScale;
      cameraPan = event.localPosition - (focal * newScale);
      onTick();
    }
  }

  void dispose() {
    animController.dispose();
  }
}
