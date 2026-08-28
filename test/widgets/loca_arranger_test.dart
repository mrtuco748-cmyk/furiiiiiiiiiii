import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/widgets/loca_arranger.dart';

void main() {
  const w = 500.0;
  const h = 800.0;

  double area(LocaRect r) => r.width * r.height;

  bool overlaps(LocaRect a, LocaRect b) {
    const eps = 0.001;
    return a.left < b.left + b.width - eps &&
        b.left < a.left + a.width - eps &&
        a.top < b.top + b.height - eps &&
        b.top < a.top + a.height - eps;
  }

  group('LocaArranger.arrange', () {
    test('devuelve exactamente `cantidad` rects', () {
      for (var n = 1; n <= 8; n++) {
        expect(LocaArranger.arrange(width: w, height: h, cantidad: n, seed: 7).length, n);
      }
    });

    test('cubre el lienzo completo sin solapamientos', () {
      for (var n = 1; n <= 8; n++) {
        final rects = LocaArranger.arrange(width: w, height: h, cantidad: n, seed: 3);
        final total = rects.fold<double>(0, (sum, r) => sum + area(r));
        expect(total, closeTo(w * h, 0.01), reason: 'area total para n=$n');
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(overlaps(rects[i], rects[j]), isFalse, reason: 'overlap ($i,$j) para n=$n');
          }
        }
      }
    });

    test('todos los rects quedan dentro del lienzo', () {
      for (var n = 1; n <= 8; n++) {
        final rects = LocaArranger.arrange(width: w, height: h, cantidad: n, seed: 11);
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.top, greaterThanOrEqualTo(0));
          expect(r.left + r.width, lessThanOrEqualTo(w + 0.001));
          expect(r.top + r.height, lessThanOrEqualTo(h + 0.001));
          expect(r.width, greaterThan(0));
          expect(r.height, greaterThan(0));
        }
      }
    });

    test('es determinístico para la misma semilla', () {
      final a = LocaArranger.arrange(width: w, height: h, cantidad: 5, seed: 42);
      final b = LocaArranger.arrange(width: w, height: h, cantidad: 5, seed: 42);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].left, closeTo(b[i].left, 0.0001));
        expect(a[i].top, closeTo(b[i].top, 0.0001));
        expect(a[i].width, closeTo(b[i].width, 0.0001));
        expect(a[i].height, closeTo(b[i].height, 0.0001));
      }
    });

    test('semillas distintas generan distribuciones distintas', () {
      final a = LocaArranger.arrange(width: w, height: h, cantidad: 4, seed: 1);
      final b = LocaArranger.arrange(width: w, height: h, cantidad: 4, seed: 2);
      final different = List.generate(a.length, (i) {
        return (a[i].left - b[i].left).abs() > 0.001 ||
            (a[i].top - b[i].top).abs() > 0.001;
      }).any((d) => d);
      expect(different, isTrue);
    });

    test('todas las rotaciones son 0 (ningún bloque torcido)', () {
      for (var n = 1; n <= 8; n++) {
        final rects = LocaArranger.arrange(width: w, height: h, cantidad: n, seed: 9);
        for (final r in rects) {
          expect(r.rotation, 0);
        }
      }
    });

    test('ninguna dimensión degenera en micro-tira (<12% del lienzo)', () {
      final rects = LocaArranger.arrange(width: w, height: h, cantidad: 6, seed: 5);
      for (final r in rects) {
        expect(r.width, greaterThanOrEqualTo(w * 0.12 - 0.001));
        expect(r.height, greaterThanOrEqualTo(h * 0.12 - 0.001));
      }
    });

    test('un rect nunca degenera en tira (aspect entre 0.4 y 2.0, cuadrado/rectángulo)', () {
      final rects = LocaArranger.arrange(width: w, height: h, cantidad: 8, seed: 5);
      for (final r in rects) {
        final aspect = r.width / r.height;
        expect(aspect, greaterThanOrEqualTo(0.4));
        expect(aspect, lessThanOrEqualTo(2.0));
      }
    });

    test('con pesos, el ítem con más texto recibe un bloque más grande', () {
      for (var seed = 1; seed <= 20; seed++) {
        final rects = LocaArranger.arrange(
          width: w, height: h, cantidad: 4, seed: seed,
          weights: [6, 1, 1, 1],
        );
        final heavy = rects[0].width * rects[0].height;
        final avg = ((w * h) / 4);
        expect(heavy, greaterThan(avg + 1),
            reason: 'seed $seed: pesado debería superar al promedio');
      }
    });

    test('sin pesos el comportamiento se mantiene balanceado', () {
      final rects = LocaArranger.arrange(width: w, height: h, cantidad: 4, seed: 3);
      for (final r in rects) {
        final area = r.width * r.height;
        expect(area, closeTo(w * h / 4, w * h * 0.3));
      }
    });

    test('muchos ítems en lienzo chico no degenera (sin NaN/negativos)', () {
      // Caso que disparaba el crash: la subdivisión deja nodos más chicos que
      // minW y el clamp producía hijos de ancho <= 0 -> NaN en double.clamp.
      for (var n = 20; n <= 200; n += 20) {
        final rects = LocaArranger.arrange(width: w, height: h, cantidad: n, seed: 5);
        expect(rects.length, n, reason: 'cantidad $n');
        for (final r in rects) {
          expect(r.width, greaterThan(0), reason: 'ancho > 0 para n=$n');
          expect(r.height, greaterThan(0), reason: 'alto > 0 para n=$n');
          expect(r.width.isFinite, isTrue);
          expect(r.height.isFinite, isTrue);
        }
      }
    });

    test('pesos sesgados extremos no producen dimensiones inválidas', () {
      for (var seed = 1; seed <= 15; seed++) {
        final weights = List<double>.generate(60, (i) => i == 0 ? 1000 : 1);
        final rects = LocaArranger.arrange(
          width: w, height: h, cantidad: 60, seed: seed, weights: weights,
        );
        expect(rects.length, 60);
        for (final r in rects) {
          expect(r.width, greaterThan(0));
          expect(r.height, greaterThan(0));
          expect(r.width.isFinite && r.height.isFinite, isTrue);
        }
      }
    });
  });
}