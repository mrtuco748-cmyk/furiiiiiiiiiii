import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_state.dart';
import '../../../models/transaction.dart';
import '../../../widgets/loca_screen.dart';
import '../../../widgets/tap_tile.dart';

const _c = Color(0xFF00FF66);
const _red = Color(0xFFFF4444);
const _blue = Color(0xFF0088FF);

/// Panel desplegable que muestra el detalle de una transacción.
class FinanceDetailPanel extends StatelessWidget {
  final VoidCallback close;
  final Transaction transaction;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const FinanceDetailPanel({
    super.key,
    required this.close,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final myInitial = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    final partnerInitial = myInitial == 'F' ? 'R' : 'F';
    final ownerInitial =
        transaction.userId == AppState.myId ? myInitial : partnerInitial;
    final color = isIncome ? _c : _red;

    return LocaScreen.panel(
      color: const Color(0xFF1A1A1A),
      borderColor: color,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 22,
                ),
                const Spacer(),
                LocaScreen.closeIcon(close, color, Icons.close),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 44,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      transaction.description ?? transaction.category,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${transaction.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.bangers(
                        color: color,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ownerInitial,
                        style: GoogleFonts.bangers(
                          color: isIncome
                              ? const Color(0xFF111111)
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Spacer(),
                TapTile(
                  onTap: () {
                    close();
                    onEdit(transaction);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                TapTile(
                  onTap: () {
                    close();
                    onDelete(transaction);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
