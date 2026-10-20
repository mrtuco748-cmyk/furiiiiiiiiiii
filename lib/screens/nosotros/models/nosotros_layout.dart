class NosotrosLayout {
  final double w, h, gapW, gapH, headerH;
  final double r1Y, r1H, cartasY, cartasH;
  final double r3Y, r3H, emocionesW, emocionesX;
  final double rightColX, rightColW, preguntasH, margin;

  const NosotrosLayout({
    required this.w,
    required this.h,
    required this.gapW,
    required this.gapH,
    required this.headerH,
    required this.r1Y,
    required this.r1H,
    required this.cartasY,
    required this.cartasH,
    required this.r3Y,
    required this.r3H,
    required this.emocionesW,
    required this.emocionesX,
    required this.rightColX,
    required this.rightColW,
    required this.preguntasH,
    required this.margin,
  });

  factory NosotrosLayout.calculate(double w, double h) {
    final margin = w * 0.04;
    final gapW = w * 0.02;
    final gapH = h * 0.02;
    final headerH = h * 0.065;

    final r1Y = headerH + gapH;
    final r1H = h * 0.14;

    final cartasY = r1Y + r1H + gapH;
    final cartasH = h * 0.25;

    final r3Y = cartasY + cartasH + gapH;
    final emocionesW = w * 0.30;
    final emocionesX = margin;
    final rightColX = emocionesX + emocionesW + gapW;
    final rightColW = w - margin - rightColX;
    final r3H = h - r3Y - gapH;
    final preguntasH = r3H * 0.53;

    return NosotrosLayout(
      w: w, h: h, gapW: gapW, gapH: gapH, headerH: headerH,
      r1Y: r1Y, r1H: r1H, cartasY: cartasY, cartasH: cartasH,
      r3Y: r3Y, r3H: r3H, emocionesW: emocionesW, emocionesX: emocionesX,
      rightColX: rightColX, rightColW: rightColW,
      preguntasH: preguntasH, margin: margin,
    );
  }

  double get retosW => (w - margin * 2 - gapW) * 0.5;
  double get chatW => retosW;
  double get retosX => margin;
  double get chatX => retosX + retosW + gapW;
  double get cartasW => w - margin * 2;
  double get cartasX => margin;
  double get bottomH => r3H - preguntasH - gapH;
  double get metasW => (rightColW - gapW) / 2;
  double get mapaW => metasW;
  double get metasX => rightColX;
  double get mapaX => metasX + metasW + gapW;
  double get bottomY => r3Y + preguntasH + gapH;
  double get panelW => emocionesW + gapW + rightColW;
  double get iconW => emocionesW * 0.7;
}
