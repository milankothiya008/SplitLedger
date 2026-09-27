import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/models/budget.dart';
import 'package:SmartSpend/models/expense.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Add a new expense, or edit/delete an existing one when [expense] is given.
class AddExpense extends StatefulWidget {
  const AddExpense({super.key, this.expense});

  final Expense? expense;

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _category;
  late DateTime _date;
  bool _saving = false;
  bool _showCategoryError = false;

  bool get _editing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(text: e == null ? '' : _plain(e.amount));
    _note = TextEditingController(text: e?.message ?? '');
    _category = e?.category;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  /// Budget alerts for adding [amount] in [category] on [date], computed before
  /// the write so the numbers aren't affected by the live update.
  String? _budgetAlert(AppData data, String category, double amount, DateTime date) {
    final old = widget.expense;
    for (final b in data.budgetsAffectedBy(category, date)) {
      var before = data.spentFor(b);
      if (old != null && b.contains(old.date) && (b.isOverall || b.category == old.category)) {
        before -= old.amount;
      }
      final after = before + amount;
      if (after > b.amount && before <= b.amount) {
        return 'Heads up: you are ${money(after - b.amount)} over your ${_name(b)} budget.';
      }
      if (after >= b.amount * 0.75 && before < b.amount * 0.75) {
        return 'You have used ${(after / b.amount * 100).toStringAsFixed(0)}% of your ${_name(b)} budget.';
      }
    }
    return null;
  }

  static String _name(Budget b) => b.isOverall ? 'overall' : b.category!;

  Future<void> _save() async {
    final validForm = _formKey.currentState!.validate();
    setState(() => _showCategoryError = _category == null);
    if (!validForm || _category == null) return;

    final data = context.read<AppData>();
    final amount = double.parse(_amount.text.trim());
    final note = _note.text.trim();
    final alert = _budgetAlert(data, _category!, amount, _date);

    setState(() => _saving = true);
    try {
      if (_editing) {
        await data.updateExpense(Expense(
          id: widget.expense!.id,
          category: _category!,
          amount: amount,
          message: note,
          date: _date,
        ));
      } else {
        await data.addExpense(category: _category!, amount: amount, message: note, date: _date);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Could not save the expense. Please try again.', error: true);
      return;
    }

    if (!mounted) return;
    showSnack(context, alert ?? (_editing ? 'Expense updated' : 'Expense added'));
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete expense?',
      message: 'This ${widget.expense!.category} expense of ${money(widget.expense!.amount)} will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<AppData>().deleteExpense(widget.expense!.id);
      if (!mounted) return;
      showSnack(context, 'Expense deleted');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not delete the expense.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit expense' : 'Add expense'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: PageListView(
          maxWidth: 720,
          bottom: 24,
          children: [
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: TextFormField(
                controller: _amount,
                autofocus: !_editing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?'))],
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  hintText: '0',
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) return 'Enter an amount greater than 0';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                if (_showCategoryError)
                  Text('Pick a category', style: TextStyle(color: scheme.error, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            CategoryPicker(
              selected: _category,
              onSelected: (c) => setState(() {
                _category = c;
                _showCategoryError = false;
              }),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              final dateField = InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  child: Text(relativeDay(_date)),
                ),
              );
              final noteField = TextFormField(
                controller: _note,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                  counterText: '',
                ),
                onFieldSubmitted: (_) => _save(),
              );
              if (c.maxWidth < 520) {
                return Column(children: [dateField, const SizedBox(height: 16), noteField]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dateField),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: noteField),
                ],
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ContentWidth(
            maxWidth: 688,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : Text(_editing ? 'Save changes' : 'Save expense'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
