import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/finances_provider.dart';
import '../../models/transaction.dart';
import '../../app_state.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';

const _c = Color(0xFF00FF66);
const _cIncome = Color(0xFF008844);
const _red = Color(0xFFFF4444);
const _blue = Color(0xFF0088FF);
const _yellow = Color(0xFFFFDE59);

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
    String category = existing?.category ?? 'other';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      backgroundColor: _c,
      title: Text(existing != null ? 'EDITAR' : 'TRANSACCION', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, color: const Color(0xFF111111), fontSize: 20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14), decoration: InputDecoration(hintText: 'descripcion', hintStyle: GoogleFonts.bangers(color: const Color(0xFF333333), fontSize: 14), filled: true, fillColor: _c.withValues(alpha: 0.3), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF111111), width: 2)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF111111), width: 3)))),
        const SizedBox(height: 12),
        TextField(controller: amountCtrl, keyboardType: TextInputType.number, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14), decoration: InputDecoration(hintText: 'monto', hintStyle: GoogleFonts.bangers(color: const Color(0xFF333333), fontSize: 14), filled: true, fillColor: _c.withValues(alpha: 0.3), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF111111), width: 2)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF111111), width: 3)))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _segBtn('GASTO', type == 'expense', () => setLocal(() => type = 'expense'), _red),
          _segBtn('INGRESO', type == 'income', () => setLocal(() => type = 'income'), _cIncome),
        ]),
      ]),
      actions: [
        GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF111111), width: 2)), child: Text('X', style: GoogleFonts.bangers(color: _c, fontSize: 16)))),
        GestureDetector(onTap: () {
          final amt = double.tryParse(amountCtrl.text);
          if (amt != null && titleCtrl.text.isNotEmpty) {
            final pv = context.read<FinancesProvider>();
            if (existing != null && existing.id != null) {
              pv.update(existing.id!, Transaction(id: existing.id, userId: existing.userId, type: type, category: category, amount: amt, description: titleCtrl.text));
            } else {
              pv.add(Transaction(userId: AppState.myId ?? '', type: type, category: category, amount: amt, description: titleCtrl.text));
            }
          }
          Navigator.pop(ctx);
        }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF111111), width: 2)), child: Text(existing != null ? 'OK' : '+', style: GoogleFonts.bangers(color: _c, fontWeight: FontWeight.bold, fontSize: 18)))),
      ],
    )));
  }

  Widget _segBtn(String label, bool active, VoidCallback onTap, Color color) {
    return GestureDetector(onTap: () { HapticFeedback.heavyImpact(); onTap(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: active ? color : color.withValues(alpha: 0.3), border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(14)), child: Text(label, style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 12, color: active ? Colors.white : color))));
  }

  @override
  Widget build(BuildContext context) {
    final darkBg = const Color(0xFF111111);
    return Scaffold(backgroundColor: _c, body: ResponsiveWrapper(builder: (context, w, h) {
      return SizedBox(width: w, height: h, child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        _header(w, h, darkBg), _balanceBlock(w, h, darkBg), _incomeBlock(w, h), _expenseBlock(w, h),
        _chartBlock(w, h), _listBlock(w, h, darkBg), _fabs(w, h, darkBg),
      ]));
    }));
  }

  Widget _header(double w, double h, Color dark) {
    return Positioned(left: 0, top: 0, width: w, height: h * 0.07, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(18)), child: Center(child: Text('FINANZAS', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 18, color: dark))))));
  }

  Widget _fabs(double w, double h, Color dark) {
    return Positioned(right: w * 0.06, bottom: h * 0.04, child: TapTile(onTap: () => _addTransaction(), child: Container(width: w * 0.13, height: w * 0.13, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(16), border: Border.all(color: dark, width: 4)), child: Center(child: Icon(Icons.add, color: dark, size: 28)))));
  }

  Widget _balanceBlock(double w, double h, Color dark) {
    return Positioned(left: w * 0.08, top: h * 0.09, width: w * 0.84, height: h * 0.09, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(18)),
      child: Consumer<FinancesProvider>(builder: (context, pv, _) => Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.account_balance, color: dark, size: 36), const SizedBox(width: 10),
        Text('\$${pv.balance.toStringAsFixed(0)}', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 26, color: dark)),
      ]))),
    )));
  }

  Widget _incomeBlock(double w, double h) {
    return Positioned(left: w * 0.04, top: h * 0.21, width: w * 0.43, height: h * 0.09, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _cIncome, borderRadius: BorderRadius.circular(18)),
      child: Consumer<FinancesProvider>(builder: (context, pv, _) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.trending_up, color: Colors.white, size: 28), const SizedBox(width: 4),
        Text('\$${pv.totalIncome.toStringAsFixed(0)}', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ])),
    )));
  }

  Widget _expenseBlock(double w, double h) {
    return Positioned(right: w * 0.04, top: h * 0.21, width: w * 0.43, height: h * 0.09, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(18)),
      child: Consumer<FinancesProvider>(builder: (context, pv, _) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.trending_down, color: Colors.white, size: 28), const SizedBox(width: 4),
        Text('\$${pv.totalExpenses.toStringAsFixed(0)}', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ])),
    )));
  }

  Widget _chartBlock(double w, double h) {
    return Positioned(left: w * 0.04, top: h * 0.33, width: w * 0.92, height: h * 0.23, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(18)),
      child: Consumer<FinancesProvider>(builder: (context, pv, _) {
        final cats = pv.expensesByCategory;
        if (pv.loading) return Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3));
        if (cats.isEmpty) return Center(child: Icon(Icons.bar_chart, color: Colors.white.withValues(alpha: 0.4), size: 40));
        final max = cats.first.total;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: cats.take(5).map((c) {
          final pct = max > 0 ? c.total / max : 0.0;
          return Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [
            Text(c.icon, style: const TextStyle(fontSize: 14)), const SizedBox(width: 6),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(children: [
              Container(height: 16, width: double.infinity, color: _blue.withValues(alpha: 0.6)),
              FractionallySizedBox(widthFactor: pct.clamp(0.01, 1.0), child: Container(height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)))),
            ]))),
            const SizedBox(width: 6), SizedBox(width: 45, child: Text('\$${c.total.toStringAsFixed(0)}', style: GoogleFonts.bangers(fontSize: 10, color: Colors.white), textAlign: TextAlign.right)),
          ]));
        }).toList());
      }),
    )));
  }

  Widget _listBlock(double w, double h, Color dark) {
    return Positioned(left: w * 0.04, top: h * 0.59, width: w * 0.92, height: h * 0.35, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(18)),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Consumer<FinancesProvider>(builder: (context, pv, _) {
        if (pv.loading) return Center(child: CircularProgressIndicator(color: dark, strokeWidth: 3));
        if (pv.transactions.isEmpty) return Center(child: Icon(Icons.receipt_long, color: dark.withValues(alpha: 0.4), size: 40));
        return ListView.builder(padding: const EdgeInsets.all(6), itemCount: pv.transactions.length, itemBuilder: (context, index) => Padding(padding: const EdgeInsets.only(bottom: 5), child: _txCard(pv.transactions[index], dark)));
      })))),
    );
  }

  Widget _txCard(Transaction t, Color dark) {
    final isIncome = t.type == 'income';
    final myInitial = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    final partnerInitial = myInitial == 'F' ? 'R' : 'F';
    final ownerInitial = t.userId == AppState.myId ? myInitial : partnerInitial;
    final borderColor = isIncome ? _c : _red;
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: borderColor, border: Border.all(color: borderColor, width: 2), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(6)), child: Text(ownerInitial, style: GoogleFonts.bangers(color: isIncome ? dark : Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
        const SizedBox(width: 6),
        Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: isIncome ? dark : Colors.white, size: 16), const SizedBox(width: 6),
        Expanded(child: Text(t.description ?? t.category, style: GoogleFonts.bangers(fontSize: 11, color: isIncome ? dark : Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text('\$${t.amount.toStringAsFixed(0)}', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 12, color: isIncome ? dark : Colors.white)),
        GestureDetector(onTap: () => _addTransaction(existing: t), child: Icon(Icons.edit, color: (isIncome ? dark : Colors.white).withValues(alpha: 0.6), size: 14)),
        GestureDetector(onTap: () { if (t.id != null) context.read<FinancesProvider>().delete(t.id!); }, child: const Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.close, color: Color(0xFFFF4444), size: 16))),
      ]),
    ));
  }
}
