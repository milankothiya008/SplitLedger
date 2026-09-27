import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/models/budget.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

enum _Preset { thisMonth, nextMonth, thisWeek, custom }

extension on _Preset {
  String get label => switch (this) {
        _Preset.thisMonth => 'This month',
        _Preset.nextMonth => 'Next month',
        _Preset.thisWeek => 'This week',
        _Preset.custom => 'Custom dates',
      };
}

/// Create a budget, or edit one when [budget] is given.
class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({super.key, this.budget});

  final Budget? budget;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late bool _overall;
  String? _category;
  late _Preset _preset;
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;
  bool _showCategoryError = false;
  Budget? _conflict;

  bool get _editing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _amount = TextEditingController(
      text: b == null ? '' : (b.amount == b.amount.roundToDouble() ? b.amount.toStringAsFixed(0) : b.amount.toStringAsFixed(2)),
    );
    _amount.addListener(() => setState(() {}));
    _overall = b?.isOverall ?? true;
    _category = b?.category;
    if (b == null) {
      _applyPreset(_Preset.thisMonth);
    } else {
      _start = b.start;
      _end = b.end;
      _preset = _Preset.values.firstWhere(
        (p) => p != _Preset.custom && _rangeFor(p).$1 == b.start && _rangeFor(p).$2 == b.end,
        orElse: () => _Preset.custom,
      );
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _rangeFor(_Preset p) {
    final t = dateOnly(DateTime.now());
    switch (p) {
      case _Preset.thisMonth:
        return (DateTime(t.year, t.month, 1), DateTime(t.year, t.month + 1, 0));
      case _Preset.nextMonth:
        return (DateTime(t.year, t.month + 1, 1), DateTime(t.year, t.month + 2, 0));
      case _Preset.thisWeek:
        final monday = DateTime(t.year, t.month, t.day - (t.weekday - 1));
        return (monday, DateTime(monday.year, monday.month, monday.day + 6));
      case _Preset.custom:
        return (_start, _end);
    }
  }

  void _applyPreset(_Preset p) {
    final r = _rangeFor(p);
    _preset = p;
    _start = r.$1;
    _end = r.$2;
    _conflict = null;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      helpText: 'Budget period',
      saveText: 'Done',
    );
    if (picked != null) {
      setState(() {
        _preset = _Preset.custom;
        _start = dateOnly(picked.start);
        _end = dateOnly(picked.end);
        _conflict = null;
      });
    }
  }

  Future<void> _save() async {
    final validForm = _formKey.currentState!.validate();
    setState(() => _showCategoryError = !_overall && _category == null);
    if (!validForm || _showCategoryError) return;

    final data = context.read<AppData>();
    final candidate = Budget(
      id: widget.budget?.id,
      category: _overall ? null : _category,
      amount: double.parse(_amount.text.trim()),
      start: _start,
      end: _end,
    );
    final conflict = data.conflictFor(candidate);
    if (conflict != null) {
      setState(() => _conflict = conflict);
      return;
    }

    setState(() => _saving = true);
    try {
      await data.saveBudget(candidate);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Could not save the budget. Please try again.', error: true);
      return;
    }
    if (!mounted) return;
    showSnack(context, _editing ? 'Budget updated' : 'Budget set — we\'ll track it as you spend');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final amount = double.tryParse(_amount.text.trim());
    final days = _end.difference(_start).inDays + 1;
    final conflict = _conflict;

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit budget' : 'New budget')),
      body: Form(
        key: _formKey,
        child: PageListView(
          maxWidth: 720,
          bottom: 24,
          children: [
            Text('What do you want to limit?', style: titleStyle),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    label: Text('All spending'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.category_outlined),
                    label: Text('One category'),
                  ),
                ],
                selected: {_overall},
                onSelectionChanged: _editing
                    ? null
                    : (s) => setState(() {
                          _overall = s.first;
                          _conflict = null;
                          _showCategoryError = false;
                        }),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _overall
                  ? 'Counts every expense in the period, whatever the category.'
                  : 'Counts only expenses in the category you choose.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            if (!_overall) ...[
              const SizedBox(height: 20),
              Row(children: [
                Text('Category', style: titleStyle),
                const SizedBox(width: 12),
                if (_showCategoryError) Text('Pick a category', style: TextStyle(color: scheme.error, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              CategoryPicker(
                selected: _category,
                onSelected: (c) => setState(() {
                  _category = c;
                  _conflict = null;
                  _showCategoryError = false;
                }),
              ),
            ],
            const SizedBox(height: 24),
            Text('Limit', style: titleStyle),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              autofocus: !_editing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?'))],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                helperText: amount != null && amount > 0 ? 'About ${money(amount / days)} per day over $days days' : null,
              ),
              validator: (v) {
                final value = double.tryParse((v ?? '').trim());
                if (value == null || value <= 0) return 'Enter a limit greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Period', style: titleStyle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _Preset.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: _preset == p,
                    showCheckmark: false,
                    onSelected: (_) => p == _Preset.custom ? _pickRange() : setState(() => _applyPreset(p)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: _pickRange,
              child: Row(
                children: [
                  Icon(Icons.event_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fmtRange(_start, _end), style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('$days ${days == 1 ? 'day' : 'days'}',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('Change', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (conflict != null) ...[
              const SizedBox(height: 16),
              AppCard(
                color: scheme.errorContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You already have ${conflict.isOverall ? 'an overall' : 'a ${conflict.category}'} budget '
                          'for ${fmtRange(conflict.start, conflict.end)}, which overlaps these dates.',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => BudgetFormPage(budget: conflict)),
                        ),
                        child: const Text('Edit that budget instead'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    : Text(_editing ? 'Save changes' : 'Set budget'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
