import 'dart:ui';
import '../models/drawing_point.dart';

/// Algoritmos de estabilización geométrica en tiempo real:
/// 1. Micro-corrección sutil contra temblores (anti-jitter) para trazos limpios.
/// 2. Trazo predictivo con nivel de 1 a 10 (amortiguación elástica y extrapolación de velocidad).
class DrawingStrokeStabilizer {
  Offset? _lastRawPoint;
  Offset? _prevRawPoint;
  Offset? _lastSmoothedPoint;
  Offset? _prevTargetPoint;

  Offset? get lastRawPoint => _lastRawPoint;
  Offset? get lastSmoothedPoint => _lastSmoothedPoint;

  void reset() {
    _lastRawPoint = null;
    _prevRawPoint = null;
    _lastSmoothedPoint = null;
    _prevTargetPoint = null;
  }

  void start(Offset point) {
    _lastRawPoint = point;
    _prevRawPoint = null;
    _lastSmoothedPoint = point;
    _prevTargetPoint = null;
  }

  (Offset point, bool shouldSkip) update(
    Offset localPosition, {
    required bool isPredictiveEnabled,
    required int predictiveLevel,
  }) {
    final lastSmoothed = _lastSmoothedPoint ?? localPosition;
    final distance = (localPosition - lastSmoothed).distance;

    // Filtro de ruido estático: si el dedo apenas se mueve (< 1.0 px), ignorar jitter
    if (distance < 1.0) {
      return (lastSmoothed, true);
    }

    // 1. Corrección base anti-temblores (subtle low-pass EMA)
    final subtleCorrected = filterMicroJitter(
      currentRaw: localPosition,
      lastSmoothed: lastSmoothed,
      prevRaw: _prevRawPoint,
    );

    // 2. Si el trazo predictivo no está activo, usar la corrección sutil directa
    Offset targetPoint = subtleCorrected;
    if (isPredictiveEnabled) {
      targetPoint = applyPredictiveStroke(
        currentTarget: subtleCorrected,
        lastPoint: lastSmoothed,
        prevTarget: _prevTargetPoint ?? _prevRawPoint,
        level: predictiveLevel,
      );
    }

    _prevRawPoint = _lastRawPoint;
    _lastRawPoint = localPosition;
    _prevTargetPoint = targetPoint;
    _lastSmoothedPoint = targetPoint;

    return (targetPoint, false);
  }

  List<DrawingPoint> finish(double pressure) {
    if (_lastRawPoint == null || _lastSmoothedPoint == null) {
      reset();
      return const [];
    }

    final raw = _lastRawPoint!;
    final smoothed = _lastSmoothedPoint!;
    reset();

    final dist = (raw - smoothed).distance;
    if (dist < 2.0) {
      return [DrawingPoint(offset: raw, pressure: pressure)];
    }

    final mid = Offset((smoothed.dx + raw.dx) / 2, (smoothed.dy + raw.dy) / 2);
    return [
      DrawingPoint(offset: mid, pressure: pressure * 0.9),
      DrawingPoint(offset: raw, pressure: pressure * 0.7),
    ];
  }

  /// Filtro sutil en tiempo real contra micro-temblores (anti-jitter).
  static Offset filterMicroJitter({
    required Offset currentRaw,
    required Offset lastSmoothed,
    Offset? prevRaw,
  }) {
    double weight = 0.72; // 72% actual, 28% histórico (ágil y natural)
    if (prevRaw != null) {
      final v1 = lastSmoothed - prevRaw;
      final v2 = currentRaw - lastSmoothed;
      if (v1.distance > 2.0 && v2.distance > 2.0) {
        final dot = (v1.dx * v2.dx + v1.dy * v2.dy) / (v1.distance * v2.distance);
        if (dot < 0.35) weight = 0.94; // Preservar esquinas agudas
      }
    }
    return Offset(
      lastSmoothed.dx + (currentRaw.dx - lastSmoothed.dx) * weight,
      lastSmoothed.dy + (currentRaw.dy - lastSmoothed.dy) * weight,
    );
  }

  /// Trazo predictivo con nivel del 1 al 10.
  static Offset applyPredictiveStroke({
    required Offset currentTarget,
    required Offset lastPoint,
    Offset? prevTarget,
    required int level,
  }) {
    final clampedLevel = level.clamp(1, 10);
    final pullFactor = 0.52 - ((clampedLevel - 1) / 9.0) * 0.38;

    final dragged = Offset(
      lastPoint.dx + (currentTarget.dx - lastPoint.dx) * pullFactor,
      lastPoint.dy + (currentTarget.dy - lastPoint.dy) * pullFactor,
    );

    if (prevTarget != null) {
      final velocity = currentTarget - prevTarget;
      if (velocity.distance > 1.5) {
        final forwardFactor = (clampedLevel * 0.06).clamp(0.06, 0.55);
        return Offset(
          dragged.dx + velocity.dx * forwardFactor,
          dragged.dy + velocity.dy * forwardFactor,
        );
      }
    }

    return dragged;
  }
}
