import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/transaction.dart';
import '../../../providers/finances_provider.dart';
import '../../../widgets/loca_screen.dart';
import '../../../widgets/tap_tile.dart';

const _c = Color(0xFF00FF66);
const _red = Color(0xFFFF4444);
const _blue = Color(0xFF0088FF);

/// Panel desplegable que muestra la lista completa de historial de transacciones.
class FinanceHistoryPanel extends StatelessWidget {
  final VoidCallback close;
  final FinancesProvider provider;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const FinanceHistoryPanel({
    super.key,
    required this.close,
    required this.provider,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tx = provider.transactions;
    return LocaScreen.panel(
      color: const Color(0xFF1A1A1A),
      borderColor: _blue,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.history, color: _blue, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(close, _blue, Icons.close),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: tx.isEmpty
                ? const Center(
                    child:
                        Icon(Icons.receipt, color: Color(0x66FFFFFF), size: 60))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: tx.length,
                    itemBuilder: (context, i) => _buildRow(tx[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Transaction t) {
    final isIncome = t.type == 'income';
    final color = isIncome ? _c : _red;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.description ?? t.category,
                style: GoogleFonts.bangers(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '\$${t.amount.toStringAsFixed(0)}',
              style: GoogleFonts.bangers(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            TapTile(
              onTap: () {
                close();
                onEdit(t);
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit, color: _blue, size: 18),
              ),
            ),
            const SizedBox(width: 4),
            TapTile(
              onTap: () => onDelete(t),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete, color: _red, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
