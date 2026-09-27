import 'dart:math' as math;

import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/screens/AddExpense.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/utils/period.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:SmartSpend/widgets/expense_widgets.dart';
import 'package:SmartSpend/widgets/period_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Expenses tab: filter by period, search, and tap any expense to edit it.
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final _search = TextEditingController();
  Period _period = Period.month;
  DateTimeRange? _custom;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    if (data.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final span = spanFor(_period, custom: _custom);
    final query = _search.text.trim().toLowerCase();
    final list = data
        .expensesIn(span)
        .where((e) =>
            query.isEmpty ||
            e.category.toLowerCase().contains(query) ||
            e.message.toLowerCase().contains(query))
        .toList();
    final total = AppData.sum(list);

    // Average over the days of the period that have actually happened.
    final tomorrow = dateOnly(DateTime.now()).add(const Duration(days: 1));
    final from = _period == Period.all && list.isNotEmpty ? dateOnly(list.last.date) : span.start;
    final to = span.end.isAfter(tomorrow) ? tomorrow : span.end;
    final days = math.max(1, to.difference(from).inDays);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: PageListView(
        children: [
          PeriodSelector(
            period: _period,
            custom: _custom,
            onChanged: (p, c) => setState(() {
              _period = p;
              _custom = c;
            }),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                _Metric(label: periodTitle(_period, _custom), value: money(total), emphasize: true),
                _Metric(label: 'Transactions', value: '${list.length}'),
                _Metric(label: 'Avg / day', value: money(total / days)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by category or note',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
          if (list.isEmpty)
            EmptyState(
              icon: query.isEmpty ? Icons.receipt_long_outlined : Icons.search_off_rounded,
              title: query.isEmpty ? 'No expenses in this period' : 'No matches',
              message: query.isEmpty
                  ? 'Try a different period, or add an expense with the + button.'
                  : 'Nothing matches "${_search.text.trim()}". Try another search.',
            )
          else
            GroupedExpenseList(
              expenses: list,
              onTap: (e) => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddExpense(expense: e)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: emphasize ? 20 : 17,
                fontWeight: FontWeight.w800,
                color: emphasize ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
