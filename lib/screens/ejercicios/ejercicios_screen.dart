import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/workout_log.dart';
import '../../models/workout_routine.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brutal_style.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import 'ejercicios_style.dart';
import 'widgets/challenge_detail_sheet.dart';
import 'widgets/challenge_form_dialogs.dart';
import 'widgets/ejercicios_header.dart';
import 'widgets/ejercicios_tab.dart';
import 'widgets/exercise_sheet.dart';
import 'widgets/hoy_tab.dart';
import 'widgets/log_detail_sheet.dart';
import 'widgets/new_routine_dialog.dart';
import 'widgets/retos_tab.dart';
import 'widgets/routine_detail_sheet.dart';
import 'widgets/stats_tab.dart';

class EjerciciosScreen extends StatefulWidget {
  final AppMode mode;
  final int initialTab;
  final bool isPopup;

  const EjerciciosScreen({
    super.key,
    required this.mode,
    this.initialTab = 0,
    this.isPopup = false,
  });

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkoutProvider>().load();
    });
  }

  Future<void> _toggleDay(DateTime day) async {
    HapticFeedback.lightImpact();
    final pv = context.read<WorkoutProvider>();
    final rewards = context.read<RewardsProvider>();
    final wasDone = pv.completedByUser(day, pv.myId);
    await pv.toggleCompletion(userId: pv.myId, date: day);
    if (!wasDone) {
      final ds =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      rewards.awardOnce(pv.myId, 'workout-$ds', 2);
    }
  }

  Future<void> _dialogNewLog({RoutineItem? prefill, WorkoutLog? existing, DateTime? day}) async {
    final pv = context.read<WorkoutProvider>();
    await ExerciseSheet.show(
      context,
      existing: existing,
      prefillName: prefill?.exerciseName,
      prefillSeries: prefill?.series,
      prefillReps: prefill?.reps,
      prefillWeight: prefill?.weight,
      prefillRest: prefill?.restSeconds,
      day: day,
      onSave: (log) async {
        if (existing != null && existing.id != null) {
          await pv.updateLog(log);
        } else {
          await pv.addLog(log);
        }
      },
      onDelete: (existing != null && existing.id != null)
          ? () => pv.deleteLog(existing.id!)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EjerciciosStyle.bg,
      body: ResponsiveWrapper(
        builder: (context, w, h) {
          return SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                BrutalStyle.bg(EjerciciosStyle.bg),
                Positioned.fill(
                  child: Column(
                    children: [
                      if (widget.isPopup)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 4),
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      EjerciciosHeader(
                        w: w,
                        h: h,
                        tab: _tab,
                        isPopup: widget.isPopup,
                        onPop: () => Navigator.of(context).maybePop(),
                      ),
                      if (!widget.isPopup)
                        EjerciciosTabsBar(
                          w: w,
                          h: h,
                          currentTab: _tab,
                          onTabSelected: (idx) => setState(() => _tab = idx),
                        ),
                      Expanded(child: _body(w, h)),
                    ],
                  ),
                ),
                if (_tab != 3) _fab(w, h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(double w, double h) {
    final pv = context.watch<WorkoutProvider>();
    if (pv.loading) {
      return Center(child: CircularProgressIndicator(color: EjerciciosStyle.cyan));
    }
    if (pv.hasError) {
      return _errorView(pv.error ?? 'Error', pv);
    }
    switch (_tab) {
      case 0:
        return HoyTab(
          w: w,
          h: h,
          pv: pv,
          myStreak: pv.myStreak,
          partnerStreak: pv.partnerStreak,
          partnerName: AppState.identity == 'Facu' ? 'Rocio' : 'Facu',
          onAssignRoutine: (dow) => dialogNewRoutine(context, pv, dayOfWeek: dow),
          onEditRoutine: (routine) => showRoutineDetailSheet(
            context: context,
            routine: routine,
            pv: pv,
            onPromptItem: () => promptRoutineItem(context, pv),
          ),
          onToggleDay: _toggleDay,
          onLogPrefill: (item, day) => _dialogNewLog(prefill: item, day: day),
        );
      case 1:
        return EjerciciosTab(
          w: w,
          h: h,
          pv: pv,
          onLogTap: (log) => showLogDetailSheet(
            context: context,
            log: log,
            pv: pv,
            onPrefill: (prefill) => _dialogNewLog(prefill: prefill),
            onEdit: (existing) => _dialogNewLog(existing: existing),
          ),
          onLogLongPress: (log) => sheetReactions(
            context,
            (key) => pv.toggleLogReaction(log.id!, key),
          ),
        );
      case 2:
        return RetosTab(
          w: w,
          h: h,
          pv: pv,
          onChallengeTap: (c) => showChallengeDetailSheet(
            context: context,
            challenge: c,
            pv: pv,
          ),
          onChallengeLongPress: (c) => sheetReactions(
            context,
            (key) => pv.toggleChallengeReaction(c.id!, key),
          ),
        );
      default:
        return StatsTab(w: w, h: h, pv: pv);
    }
  }

  Widget _errorView(String msg, WorkoutProvider pv) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EjerciciosStyle.panel,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: EjerciciosStyle.red, size: 48),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TapTile(
              onTap: () => pv.load(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: EjerciciosStyle.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, color: EjerciciosStyle.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab(double w, double h) {
    final pv = context.read<WorkoutProvider>();
    return Positioned(
      right: w * 0.05,
      bottom: h * 0.04,
      child: TapTile(
        onTap: () {
          HapticFeedback.lightImpact();
          if (_tab == 0) {
            dialogNewRoutine(context, pv);
          } else if (_tab == 1) {
            _dialogNewLog();
          } else {
            dialogNewChallenge(context, pv);
          }
        },
        child: Container(
          width: w * 0.13,
          height: w * 0.13,
          decoration: EjerciciosStyle.panelDeco(
            color: EjerciciosStyle.lime,
            radius: 16,
            bw: 3,
          ),
          child: const Icon(Icons.add, color: EjerciciosStyle.darkText, size: 30),
        ),
      ),
    );
  }
}
