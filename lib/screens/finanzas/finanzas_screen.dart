import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/finances_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/loca_screen.dart';
import 'widgets/finance_chart_panel.dart';
import 'widgets/finance_detail_panel.dart';
import 'widgets/finance_history_panel.dart';
import 'widgets/finance_transaction_dialog.dart';

const _c = Color(0xFF00FF66);
const _cIncome = Color(0xFF008844);
const _red = Color(0xFFFF4444);
const _blue = Color(0xFF0088FF);

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
/// gráfico por categoría detrás de un tile y UNA transacción por bloque
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
    Future.microtask(() {
      if (mounted) context.read<FinancesProvider>().load();
    });
  }

  void _addTransaction({Transaction? existing}) {
    FinanceTransactionDialog.show(
      context,
      context.read<FinancesProvider>(),
      existing: existing,
    );
  }

  void _deleteTransaction(Transaction t) {
    final id = t.id;
    if (id == null) return;
    context.read<FinancesProvider>().delete(id);
    AppFeedback.deleted(context, 'Transacción eliminada', onUndo: () {
      context.read<FinancesProvider>().add(
        Transaction(
          userId: t.userId,
          type: t.type,
          category: t.category,
          amount: t.amount,
          description: t.description,
        ),
      );
    });
  }

  Widget _numSwap(String text, Color color) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: GoogleFonts.bangers(
              color: color, fontSize: 36, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancesProvider>(
      builder: (context, pv, _) {
        final tx = pv.transactions;
        final shownTx = tx.take(6).toList();
        final entries = <LocaEntry>[
          LocaEntry(
            icon: Icons.account_balance,
            color: _cIncome,
            iconColor: const Color(0xFF111111),
            label: 'saldo',
            weight: 3,
            swapBuilder: (_) =>
                _numSwap('\$${pv.balance.toStringAsFixed(0)}', Colors.white),
            tapToSwap: true,
          ),
          LocaEntry(
            icon: Icons.trending_up,
            color: _cIncome,
            label: 'ingresos',
            weight: 3,
            swapBuilder: (_) => _numSwap(
                '\$${pv.totalIncome.toStringAsFixed(0)}', Colors.white),
            tapToSwap: true,
          ),
          LocaEntry(
            icon: Icons.trending_down,
            color: _red,
            label: 'gastos',
            weight: 3,
            swapBuilder: (_) => _numSwap(
                '\$${pv.totalExpenses.toStringAsFixed(0)}', Colors.white),
            tapToSwap: true,
          ),
          const LocaEntry(
            icon: Icons.bar_chart,
            color: _blue,
            label: 'gráfico',
            panel: 0,
          ),
          if (pv.hasError)
            LocaEntry(
                icon: Icons.cloud_off,
                color: _red,
                onTap: () => context.read<FinancesProvider>().load()),
          for (var i = 0; i < shownTx.length; i++)
            LocaEntry(
              icon: shownTx[i].type == 'income'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: shownTx[i].type == 'income' ? _c : _red,
              iconColor: shownTx[i].type == 'income'
                  ? const Color(0xFF111111)
                  : Colors.white,
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
            (_, close) => FinanceChartPanel(close: close, provider: pv),
            for (var i = 0; i < shownTx.length; i++)
              (_, close) => FinanceDetailPanel(
                    close: close,
                    transaction: shownTx[i],
                    onEdit: (t) => _addTransaction(existing: t),
                    onDelete: _deleteTransaction,
                  ),
            (_, close) => FinanceHistoryPanel(
                  close: close,
                  provider: pv,
                  onEdit: (t) => _addTransaction(existing: t),
                  onDelete: _deleteTransaction,
                ),
          ],
        );
      },
    );
  }
}
