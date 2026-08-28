import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';

/// Args para abrir EjerciciosScreen en una pestaña concreta desde el mosaico.
class EjerciciosArgs {
  final AppMode mode;
  final int tab;
  const EjerciciosArgs(this.mode, this.tab);
}

const _calendarTheme = ThemeSet(
  a: Color(0xFF00D4FF), b: Color(0xFF39FF14), c: Color(0xFFFFDE59),
  d: Color(0xFF00A8CC), e: Color(0xFF0E8A00),
  dark: Color(0xFF0A1620), light: Color(0xFFFFFFFF), mid: Color(0xFF122433),
);

const _canvasTheme = ThemeSet(
  a: Color(0xFF9D00FF), b: Color(0xFFB23BFF), c: Color(0xFF6B0FB8),
  d: Color(0xFF7B2D8E), e: Color(0xFF4A00CC),
  dark: Color(0xFF140A1A), light: Color(0xFFFFFFFF), mid: Color(0xFF201430),
);

const _workoutTheme = ThemeSet(
  a: Color(0xFF39FF14), b: Color(0xFF00D4FF), c: Color(0xFFFFDE59),
  d: Color(0xFFFF66C4), e: Color(0xFF0E8A00),
  dark: Color(0xFF0E1408), light: Color(0xFFFFFFFF), mid: Color(0xFF182E12),
);

/// Calendario estilo "Nosotros": tiles de calendario / clases que abren cada
/// sección funcional.
class CalendarMosaicoScreen extends StatelessWidget {
  const CalendarMosaicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LocaScreen(
      seed: 17,
      theme: _calendarTheme,
      entries: [
        LocaEntry(
          icon: Icons.calendar_month,
          color: const Color(0xFF00D4FF),
          label: 'Calendario',
          onTap: () { HapticFeedback.heavyImpact(); context.push(RouterRoutes.calendar); },
        ),
        LocaEntry(
          icon: Icons.event_repeat,
          color: const Color(0xFF39FF14),
          iconColor: const Color(0xFF062B06),
          label: 'Clases',
          onTap: () { HapticFeedback.heavyImpact(); context.push(RouterRoutes.classBoard); },
        ),
      ],
    );
  }
}

/// Pizarra estilo "Nosotros": un bloque gigante que abre el canvas.
class PizarraMosaicoScreen extends StatelessWidget {
  const PizarraMosaicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LocaScreen(
      seed: 23,
      theme: _canvasTheme,
      entries: [
        LocaEntry(
          icon: Icons.draw,
          color: const Color(0xFF9D00FF),
          label: 'Pizarra',
          onTap: () { HapticFeedback.heavyImpact(); context.push(RouterRoutes.pizarra); },
        ),
      ],
    );
  }
}

/// Ejercicios estilo "Nosotros": cada sección (Hoy / Ejercicios / Retos /
/// Stats) es un bloque que abre esa pestaña con toda la funcionalidad.
class EjerciciosMosaicoScreen extends StatelessWidget {
  final AppMode mode;
  const EjerciciosMosaicoScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final entries = [
      LocaEntry(
        icon: Icons.today,
        color: const Color(0xFF39FF14),
        iconColor: const Color(0xFF062B06),
        label: 'Hoy',
        onTap: () => _open(context, 0),
      ),
      LocaEntry(
        icon: Icons.fitness_center,
        color: const Color(0xFF00D4FF),
        label: 'Ejercicios',
        onTap: () => _open(context, 1),
      ),
      LocaEntry(
        icon: Icons.emoji_events,
        color: const Color(0xFFFFDE59),
        iconColor: const Color(0xFF111111),
        label: 'Retos',
        onTap: () => _open(context, 2),
      ),
      LocaEntry(
        icon: Icons.bar_chart,
        color: const Color(0xFFFF66C4),
        label: 'Stats',
        onTap: () => _open(context, 3),
      ),
    ];
    return LocaScreen(seed: 29, theme: _workoutTheme, entries: entries);
  }

  void _open(BuildContext context, int tab) {
    HapticFeedback.heavyImpact();
    context.push(RouterRoutes.ejercicios, extra: EjerciciosArgs(mode, tab));
  }
}