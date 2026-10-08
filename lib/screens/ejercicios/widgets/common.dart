import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/workout_log.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

class StreakCard extends StatelessWidget {
  final double w;
  final int myStreak;
  final int partnerStreak;
  final String partnerName;

  const StreakCard(this.w, this.myStreak, this.partnerStreak, this.partnerName,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: EjerciciosStyle.panelDeco(),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: EjerciciosStyle.cyan, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Racha: $myStreak día${myStreak == 1 ? '' : 's'} · '
              '$partnerName: $partnerStreak',
              style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class DoneBadge extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;

  const DoneBadge(this.label, this.done, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? color : EjerciciosStyle.panel,
        border: Border.all(color: done ? color : EjerciciosStyle.panel, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.bangers(
          color: done ? EjerciciosStyle.bg : EjerciciosStyle.white.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ReactionChip extends StatelessWidget {
  final String label;
  final int count;

  const ReactionChip(this.label, this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: EjerciciosStyle.panelLight,
        border: Border.all(color: EjerciciosStyle.panelLight, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 1 ? '$label $count' : label,
        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 11),
      ),
    );
  }
}

class ReactionBar extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final Future<void> Function(String key) onTap;

  const ReactionBar(this.reactions, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (final e in reactions.entries)
          TapTile(
            onTap: () => onTap(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: EjerciciosStyle.panelLight,
                border: Border.all(color: EjerciciosStyle.cyan, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                e.value.length > 1 ? '${e.key} ${e.value.length}' : e.key,
                style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}

class Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const Stat(this.label, this.value, {this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.bangers(
              color: color ?? EjerciciosStyle.cyan,
              fontSize: 16,
              fontWeight: FontWeight.w900)),
      Text(label,
          style: GoogleFonts.bangers(
              color: EjerciciosStyle.white.withValues(alpha: 0.55), fontSize: 9)),
    ]);
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard(this.title, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: EjerciciosStyle.panelDeco(),
      child: Row(
        children: [
          Icon(icon, color: EjerciciosStyle.cyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.bangers(
              color: EjerciciosStyle.cyan,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ImproveRow extends StatelessWidget {
  final WorkoutLog log;

  const ImproveRow(this.log, {super.key});

  @override
  Widget build(BuildContext context) {
    final w = log.weight;
    final weightTxt = w == null
        ? ''
        : (w == w.roundToDouble() ? '${w.round()}kg' : '${w}kg');
    final seriesTxt =
        log.series != null && log.reps != null ? '${log.series}x${log.reps}' : '';
    final date = log.loggedOn;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Text('${date.day}/${date.month}/${date.year}',
            style: GoogleFonts.bangers(
                color: EjerciciosStyle.white.withValues(alpha: 0.6), fontSize: 11)),
        const Spacer(),
        if (seriesTxt.isNotEmpty)
          Text(seriesTxt,
              style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 12)),
        const SizedBox(width: 8),
        Text(weightTxt,
            style: GoogleFonts.bangers(color: EjerciciosStyle.cyan, fontSize: 13)),
      ]),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const ActionButton(this.icon, this.color, this.iconColor, this.onTap,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}