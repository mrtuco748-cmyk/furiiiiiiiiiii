import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Un [Stack] especial para lienzos infinitos o con zoom/paneo.
///
/// En Flutter, el `RenderStack` estándar hereda de `RenderBox` cuya implementación
/// de `hitTest` verifica `if (_size!.contains(position))`. En un lienzo transformado
/// por cámara (matriz de mundo a pantalla), los elementos hijos tienen coordenadas de mundo
/// que frecuentemente exceden el tamaño del viewport de la pantalla (ej. x: 800, y: 1200 o negativos).
///
/// `UnboundedHitTestStack` no descarta el hit test por el tamaño del RenderBox de la pantalla,
/// sino que evalúa directamente a todos sus hijos en sus coordenadas reales de mundo,
/// permitiendo que toques, clics y campos de texto (`TextField`) funcionen en cualquier posición del infinito.
class UnboundedHitTestStack extends Stack {
  const UnboundedHitTestStack({
    super.key,
    super.alignment = AlignmentDirectional.topStart,
    super.textDirection,
    super.fit = StackFit.loose,
    super.clipBehavior = Clip.none,
    super.children = const <Widget>[],
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderUnboundedHitTestStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }
}

class RenderUnboundedHitTestStack extends RenderStack {
  RenderUnboundedHitTestStack({
    super.children,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Evaluar directamente los hijos sin recortar por `_size!.contains(position)`
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
