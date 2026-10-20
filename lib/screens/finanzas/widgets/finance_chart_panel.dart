import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/finances_provider.dart';
import '../../../widgets/loca_screen.dart';

const _blue = Color(0xFF0088FF);

/// Panel desplegable que muestra el gráfico de gastos por categoría.
class FinanceChartPanel extends StatelessWidget {
  final VoidCallback close;
  final FinancesProvider provider;

  const FinanceChartPanel({
    super.key,
    required this.close,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return LocaScreen.panel(
      color: _blue,
      borderColor: _blue,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.white, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(close, _blue, Icons.close),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildChartBody()),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildChartBody() {
    final cats = provider.expensesByCategory;
    if (cats.isEmpty) {
      return const Center(
          child: Icon(Icons.bar_chart, color: Color(0x66FFFFFF), size: 48));
    }
    final max = cats.first.total;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: cats.take(6).map((c) {
        final pct = max > 0 ? c.total / max : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(c.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                          height: 18,
                          width: double.infinity,
                          color: Colors.white24),
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.01, 1.0),
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                child: Text(
                  '\$${c.total.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.bangers(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
