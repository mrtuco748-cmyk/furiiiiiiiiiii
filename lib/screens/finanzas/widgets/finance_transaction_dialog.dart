import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_state.dart';
import '../../../models/transaction.dart';
import '../../../providers/finances_provider.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/tap_tile.dart';

const _c = Color(0xFF00FF66);
const _cIncome = Color(0xFF008844);
const _red = Color(0xFFFF4444);
const _blue = Color(0xFF0088FF);
const _bg = Color(0xFF111111);

const _categories = [
  'other',
  'comida',
  'transporte',
  'ocio',
  'hogar',
  'salud',
  'sueldo',
];

/// Diálogo para agregar o editar transacciones financieras.
class FinanceTransactionDialog extends StatefulWidget {
  final Transaction? existing;
  final FinancesProvider provider;

  const FinanceTransactionDialog({
    super.key,
    this.existing,
    required this.provider,
  });

  static Future<void> show(BuildContext context, FinancesProvider provider,
      {Transaction? existing}) {
    return showDialog(
      context: context,
      builder: (ctx) => FinanceTransactionDialog(
        existing: existing,
        provider: provider,
      ),
    );
  }

  @override
  State<FinanceTransactionDialog> createState() =>
      _FinanceTransactionDialogState();
}

class _FinanceTransactionDialogState extends State<FinanceTransactionDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late String _type;
  late String _category;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _amountCtrl = TextEditingController(
        text: widget.existing != null
            ? widget.existing!.amount.toStringAsFixed(0)
            : '');
    _type = widget.existing?.type ?? 'expense';
    _category = widget.existing?.category ?? 'other';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt != null && _titleCtrl.text.isNotEmpty) {
      if (widget.existing != null && widget.existing!.id != null) {
        widget.provider.update(
          widget.existing!.id!,
          Transaction(
            id: widget.existing!.id,
            userId: widget.existing!.userId,
            type: _type,
            category: _category,
            amount: amt,
            description: _titleCtrl.text,
          ),
        );
      } else {
        widget.provider.add(
          Transaction(
            userId: AppState.myId ?? '',
            type: _type,
            category: _category,
            amount: amt,
            description: _titleCtrl.text,
          ),
        );
      }
      AppFeedback.saved(context, 'Transacción guardada');
    }
    Navigator.pop(context);
  }

  Widget _segBtn(
      String label, bool active, VoidCallback onTap, Color color) {
    return TapTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : _bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.bangers(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: active ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _catChip(String value, String current, VoidCallback onTap) {
    final active = value == current;
    return TapTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _blue : _bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: GoogleFonts.bangers(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: active ? Colors.white : _blue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _c,
      title: Icon(
        widget.existing != null ? Icons.edit : Icons.add,
        color: const Color(0xFF111111),
        size: 34,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.bangers(
                  color: const Color(0xFF111111), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'descripcion',
                hintStyle: GoogleFonts.bangers(
                    color: const Color(0xFF333333), fontSize: 14),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.bangers(
                  color: const Color(0xFF111111), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'monto',
                hintStyle: GoogleFonts.bangers(
                    color: const Color(0xFF333333), fontSize: 14),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _segBtn('GASTO', _type == 'expense',
                    () => setState(() => _type = 'expense'), _red),
                _segBtn('INGRESO', _type == 'income',
                    () => setState(() => _type = 'income'), _cIncome),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cat in _categories)
                  _catChip(
                      cat, _category, () => setState(() => _category = cat)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.close, color: _c, size: 20),
          ),
        ),
        TapTile(
          onTap: _save,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.existing != null ? Icons.check : Icons.add,
              color: _c,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
