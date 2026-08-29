import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/finances_provider.dart';
import '../../models/transaction.dart';
import '../../app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loca_screen.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/app_feedback.dart';

const _c = Color(0xFF00FF66);
const _cIncome = Color(0xFF008844);
const _red = Color(0xFFFF4444);
const _blue = Color(0xFF0088FF);
const _bg = Color(0xFF111111);

const _finTheme = ThemeSet(
  a: Color(0xFF00FF66),
  b: Color(0xFF0088FF),
  c: Color(0xFFFF4444),
  d: Color(0xFFFFDE59),
  e: Color(0xFF008844),
  dark: Color(0xFF111111),
  light: Color(0xFFFFFFFF),
  mid: Color(0xFF222222),
  
);

/// Finanzas estilo "Nosotros": tiles de balance/ingresos/gastos con swap,
/// grÃ¡fico por categorÃ­a detrÃ¡s de un tile y UNA transacciÃ³n por bloque
/// (ingreso verde / gasto rojo). Alta (+) fija en la columna lateral.
class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});
  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FinancesProvider>().load());
  }

  void _addTransaction({Transaction? existing}) {
    final titleCtrl = TextEditingController(text: existing?.description ?? '');
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    String type = existing?.type ?? 'expense';
    final category = existing?.category ?? 'other';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      backgroundColor: _c,
      title: Icon(existing != null ? Icons.edit : Icons.add, color: const Color(0xFF111111), size: 34),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14), decoration: InputDecoration(hintText: 'descripcion', hintStyle: GoogleFonts.bangers(color: const Color(0xFF333333), fontSize: 14), filled: true, fillColor: Colors.white24, enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF111111), width: 2)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF111111), width: 3)))),
        const SizedBox(height: 12),
        TextField(controller: amountCtrl, keyboardType: TextInputType.number, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14), decoration: InputDecoration(hintText: 'monto', hintStyle: GoogleFonts.bangers(color: const Color(0xFF333333), fontSize: 14), filled: true, fillColor: Colors.white24, enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF111111), width: 2)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF111111), width: 3)))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _segBtn('GASTO', type == 'expense', () => setLocal(() => type = 'expense'), _red),
          _segBtn('INGRESO', type == 'income', () => setLocal(() => type = 'income'), _cIncome),
        ]),
      ]),
      actions: [
        TapTile(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF111111), width: 2)), child: const Icon(Icons.close, color: _c, size: 20))),
        TapTile(onTap: () {
          final amt = double.tryParse(amountCtrl.text);
          if (amt != null && titleCtrl.text.isNotEmpty) {
            final pv = context.read<FinancesProvider>();
            if (existing != null && existing.id != null) {
              pv.update(existing.id!, Transaction(id: existing.id, userId: existing.userId, type: type, category: category, amount: amt, description: titleCtrl.text));
            } else {
              pv.add(Transaction(userId: AppState.myId ?? '', type: type, category: category, amount: amt, description: titleCtrl.text));
            }
            AppFeedback.saved(context, 'Transacción guardada');
          }
          Navigator.pop(ctx);
        }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF111111), width: 2)), child: Icon(existing != null ? Icons.check : Icons.add, color: _c, size: 20))),
      ],
    )));
  }

  Widget _segBtn(String label, bool active, VoidCallback onTap, Color color) {
    return TapTile(onTap: () { HapticFeedback.heavyImpact(); onTap(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(
      color: active ? color : _bg, 
      border: Border.all(color: active ? color : color.withValues(alpha: 0.5), width: 2), 
      borderRadius: BorderRadius.circular(14)), child: Text(label, style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 12, color: active ? Colors.white : color))));
  }

  void _deleteTransaction(Transaction t) {
    final id = t.id;
    if (id == null) return;
    context.read<FinancesProvider>().delete(id);
    AppFeedback.deleted(context, 'TransacciÃ³n eliminada', onUndo: () {
      context.read<FinancesProvider>().add(
        Transaction(userId: t.userId, type: t.type, category: t.category,
            amount: t.amount, description: t.description),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancesProvider>(
      builder: (context, pv, _) {
        final tx = pv.transactions;
        // Mosaico: solo las 6 transacciones mÃ¡s recientes. El resto se ve
        // desde "historial".
        final shownTx = tx.take(6).toList();
        final entries = <LocaEntry>[
          LocaEntry(
            icon: Icons.account_balance,
            color: _cIncome,
            iconColor: const Color(0xFF111111),
            label: 'saldo',
            weight: 3,
            swapBuilder: (_) => _numSwap('\$${pv.balance.toStringAsFixed(0)}', Colors.white),
            tapToSwap: true,
          ),
          LocaEntry(
            icon: Icons.trending_up,
            color: _cIncome,
            label: 'ingresos',
            weight: 3,
            swapBuilder: (_) => _numSwap('\$${pv.totalIncome.toStringAsFixed(0)}', Colors.white),
            tapToSwap: true,
          ),
          LocaEntry(
            icon: Icons.trending_down,
            color: _red,
            label: 'gastos',
            weight: 3,
            swapBuilder: (_) => _numSwap('\$${pv.totalExpenses.toStringAsFixed(0)}', Colors.white),
            tapToSwap: true,
          ),
          LocaEntry(
            icon: Icons.bar_chart,
            color: _blue,
            label: 'grÃ¡fico',
            panel: 0,
          ),
          if (pv.hasError)
            LocaEntry(icon: Icons.cloud_off, color: _red, onTap: () => context.read<FinancesProvider>().load()),
          for (var i = 0; i < shownTx.length; i++)
            LocaEntry(
              icon: shownTx[i].type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              color: shownTx[i].type == 'income' ? _c : _red,
              iconColor: shownTx[i].type == 'income' ? const Color(0xFF111111) : Colors.white,
              label: shownTx[i].description ?? shownTx[i].category,
              panel: 1 + i,
            ),
          LocaEntry(
            icon: Icons.history,
            color: _blue,
            label: 'historial',
            weight: 2,
            panel: 1 + shownTx.length,
            isAction: true,
          ),
          LocaEntry(
            icon: Icons.add,
            color: _c,
            iconColor: const Color(0xFF111111),
            label: 'agregar',
            weight: 2,
            onTap: () => _addTransaction(),
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 73,
          theme: _finTheme,
          entries: entries,
          panels: [
            (_, close) => _chartPanel(close, pv),
            for (var i = 0; i < shownTx.length; i++)
              (_, close) => _txPanel(close, shownTx[i]),
            (_, close) => _txHistoryPanel(close, pv),
          ],
        );
      },
    );
  }

  Widget _numSwap(String text, Color color) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: GoogleFonts.bangers(color: color, fontSize: 36, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _chartPanel(VoidCallback close, FinancesProvider pv) {
    return LocaScreen.panel(
      color: _blue,
      borderColor: _blue,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(Icons.bar_chart, color: Colors.white, size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, _blue, Icons.close),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(child: _chartBody(pv)),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _chartBody(FinancesProvider pv) {
    final cats = pv.expensesByCategory;
    if (cats.isEmpty) {
      return const Center(child: Icon(Icons.bar_chart, color: Color(0x66FFFFFF), size: 48));
    }
    final max = cats.first.total;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: cats.take(6).map((c) {
        final pct = max > 0 ? c.total / max : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Text(c.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  Container(height: 18, width: double.infinity, color: Colors.white24),
                  FractionallySizedBox(
                    widthFactor: pct.clamp(0.01, 1.0),
                    child: Container(height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(width: 50, child: Text('\$${c.total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.bangers(fontSize: 11, color: Colors.white))),
          ]),
        );
      }).toList(),
    );
  }

  Widget _txPanel(VoidCallback close, Transaction t) {
    final isIncome = t.type == 'income';
    final myInitial = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    final partnerInitial = myInitial == 'F' ? 'R' : 'F';
    final ownerInitial = t.userId == AppState.myId ? myInitial : partnerInitial;
    final color = isIncome ? _c : _red;
    return LocaScreen.panel(
      color: const Color(0xFF1A1A1A),
      borderColor: color,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: color, size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, color, Icons.close),
          ]),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 44),
                const SizedBox(height: 10),
                Text(t.description ?? t.category, textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('\$${t.amount.toStringAsFixed(0)}', style: GoogleFonts.bangers(color: color, fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                  child: Text(ownerInitial, style: GoogleFonts.bangers(color: isIncome ? const Color(0xFF111111) : Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Spacer(),
            TapTile(onTap: () => _addTransaction(existing: t), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(12), border: Border.all(color: _blue, width: 2)), child: const Icon(Icons.edit, color: Colors.white, size: 22))),
            const SizedBox(width: 8),
            TapTile(onTap: () { if (t.id != null) _deleteTransaction(t); }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(12), border: Border.all(color: _red, width: 2)), child: const Icon(Icons.delete, color: Colors.white, size: 22))),
            const SizedBox(width: 8),
          ]),
        ),
        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _txHistoryPanel(VoidCallback close, FinancesProvider pv) {
    final tx = pv.transactions;
    return LocaScreen.panel(
      color: const Color(0xFF1A1A1A),
      borderColor: _blue,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(Icons.history, color: _blue, size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, _blue, Icons.close),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: tx.isEmpty
              ? const Center(child: Icon(Icons.receipt, color: Color(0x66FFFFFF), size: 60))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: tx.length,
                  itemBuilder: (context, i) => _txHistoryRow(tx[i]),
                ),
        ),
      ]),
    );
  }

  Widget _txHistoryRow(Transaction t) {
    final isIncome = t.type == 'income';
    final color = isIncome ? _c : _red;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Row(children: [
          Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.description ?? t.category,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          ),
          Text('\$${t.amount.toStringAsFixed(0)}',
              style: GoogleFonts.bangers(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          TapTile(
            onTap: () => _addTransaction(existing: t),
            child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, color: _blue, size: 18)),
          ),
          const SizedBox(width: 4),
          TapTile(
            onTap: () { if (t.id != null) _deleteTransaction(t); },
            child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete, color: _red, size: 18)),
          ),
        ]),
      ),
    );
  }
}