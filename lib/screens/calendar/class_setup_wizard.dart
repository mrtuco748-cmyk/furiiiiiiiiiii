import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule.dart';
import '../../app_state.dart';

class ClassSetupWizard extends StatefulWidget {
  const ClassSetupWizard({super.key});
  @override
  State<ClassSetupWizard> createState() => _ClassSetupWizardState();
}

class _ClassSetupWizardState extends State<ClassSetupWizard> {
  int _step = 0;
  int _classCount = 1;
  bool _saving = false;
  final _controllers = <_ClassForm>[];
  final _pageCtrl = PageController();
  static const _days = ['Lun','Mar','Mie','Jue','Vie','Sab','Dom'];
  static const _dayIds = [1, 2, 3, 4, 5, 6, 7];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      _controllers.clear();
      for (var i = 0; i < _classCount; i++) {
        _controllers.add(_ClassForm());
      }
      setState(() => _step = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients) {
          _pageCtrl.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      });
    } else if (_step <= _classCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients) {
          _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      });
    }
  }

  Future<void> _save(ScheduleProvider pv) async {
    HapticFeedback.heavyImpact();
    if (_saving) return;
    setState(() => _saving = true);
    try {
      for (final c in _controllers) {
        final name = c.nameCtrl.text.trim();
        final start = c.startCtrl.text.trim();
        final end = c.endCtrl.text.trim();
        if (name.isEmpty || start.isEmpty || end.isEmpty) continue;
        for (final d in c.selectedDays) {
          final date = DateTime.now().add(Duration(days: (d - DateTime.now().weekday + 7) % 7));
          await pv.addSchedule(Schedule(
            title: name,
            description: c.profCtrl.text.trim().isNotEmpty ? 'Prof: ${c.profCtrl.text.trim()}' : '',
            date: date,
            startTime: start,
            endTime: end,
            type: 'Clase',
            color: 0xFF7B2D8E,
            userId: AppState.identity ?? '',
          ));
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text('$e'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF00FF66);
    final dark = const Color(0xFF1A1A1A);

    return Material(color: dark, child: SafeArea(child: Column(children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: green, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18))), child: Center(child: Text(_step == 0 ? 'CONFIGURACION INICIAL' : 'Clase ${_step} de $_classCount', style: GoogleFonts.bangers(color: dark, fontSize: 20, fontWeight: FontWeight.bold)))),
      Expanded(child: _step == 0 ? _askCount(green, dark) : _classForms(green, dark)),
      if (_step == 0)
        Padding(padding: const EdgeInsets.all(16), child: GestureDetector(onTap: _next, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14), border: Border.all(color: dark, width: 4), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]), child: Center(child: Text('Siguiente ->', style: GoogleFonts.bangers(color: dark, fontSize: 18, fontWeight: FontWeight.bold)))))),
      if (_step > 0)
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          if (_step > 1) GestureDetector(onTap: () { setState(() => _step--); _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(14), border: Border.all(color: green, width: 3)), child: Text('<-', style: GoogleFonts.bangers(color: green, fontSize: 18)))),
          const Spacer(),
          GestureDetector(onTap: () {
            if (_saving) return;
            if (_step >= _classCount) { _save(context.read<ScheduleProvider>()); }
            else { setState(() => _step++); _next(); }
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: _saving ? const Color(0xFF666666) : green, borderRadius: BorderRadius.circular(14), border: Border.all(color: dark, width: 3)), child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_step >= _classCount ? 'Guardar' : 'Siguiente ->', style: GoogleFonts.bangers(color: dark, fontSize: 18, fontWeight: FontWeight.bold)))),
        ])),
    ])));
  }

  Widget _askCount(Color green, Color dark) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.school, color: green, size: 60),
      const SizedBox(height: 20),
      Text('Cuantas materias tienes\nesta semana?', style: GoogleFonts.bangers(color: green, fontSize: 22), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _countBtn(() { if (_classCount > 1) setState(() => _classCount--); }, Icons.remove),
        const SizedBox(width: 16),
        Text('$_classCount', style: GoogleFonts.bangers(color: Colors.white, fontSize: 40)),
        const SizedBox(width: 16),
        _countBtn(() { if (_classCount < 12) setState(() => _classCount++); }, Icons.add),
      ]),
    ]));
  }

  Widget _countBtn(VoidCallback tap, IconData icon) {
    return GestureDetector(onTap: () { HapticFeedback.selectionClick(); tap(); }, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00FF66), width: 3)), child: Icon(icon, color: const Color(0xFF00FF66), size: 28)));
  }

  Widget _classForms(Color green, Color dark) {
    return PageView.builder(
      controller: _pageCtrl,
      itemCount: _classCount,
      itemBuilder: (context, idx) {
        final c = _controllers[idx];
        return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          _field(c.nameCtrl, 'Nombre de la materia?', green, dark),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field(c.startCtrl, 'Empieza? (HH:MM)', green, dark)),
            const SizedBox(width: 8),
            Expanded(child: _field(c.endCtrl, 'Termina? (HH:MM)', green, dark)),
          ]),
          const SizedBox(height: 14),
          _field(c.profCtrl, 'Profesor? (opcional)', green, dark),
          const SizedBox(height: 16),
          Text('Que dias?', style: GoogleFonts.bangers(color: green, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: List.generate(7, (i) {
            final selected = c.selectedDays.contains(_dayIds[i]);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) { c.selectedDays.remove(_dayIds[i]); }
                  else { c.selectedDays.add(_dayIds[i]); }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? green : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? dark : green, width: 2),
                ),
                child: Text(_days[i], style: GoogleFonts.bangers(color: selected ? dark : green, fontSize: 14)),
              ),
            );
          })),
        ]));
      },
    );
  }

  Widget _field(TextEditingController ctrl, String hint, Color green, Color dark) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.bangers(color: const Color(0xFF666666), fontSize: 14),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: green, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: green, width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00BFFF), width: 3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ClassForm {
  final nameCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final profCtrl = TextEditingController();
  final selectedDays = <int>[1, 2, 3, 4, 5];
}
