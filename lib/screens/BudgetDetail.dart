import 'dart:math' as math;

import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/models/budget.dart';
import 'package:SmartSpend/screens/AddExpense.dart';
import 'package:SmartSpend/screens/SetBudget.dart';
import 'package:SmartSpend/theme/app_theme.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/widgets/budget_widgets.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:SmartSpend/widgets/expense_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Asks for confirmation, deletes the budget, and reports the result.
Future<bool> confirmDeleteBudget(BuildContext context, Budget b) async {
  final ok = await confirm(
    context,
    title: 'Delete budget?',
    message: 'The ${b.title.toLowerCase()} budget for ${fmtRange(b.start, b.end)} will be removed. '
        'Your expenses are not affected.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    await context.read<AppData>().deleteBudget(b);
    if (context.mounted) showSnack(context, 'Budget deleted');
    return true;
  } catch (_) {
    if (context.mounted) showSnack(context, 'Could not delete the budget.', error: true);
    return false;
  }
}

class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({super.key, required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    // Follow live edits; if the budget was deleted elsewhere, keep the last copy.
    final b = data.budgets.firstWhere((x) => x.id == budget.id, orElse: () => budget);
    final expenses = data.expensesFor(b);
    final spent = AppData.sum(expenses);
    final now = DateTime.now();
    final status = b.statusOn(now);
    final scheme = Theme.of(context).colorScheme;

    final elapsed = switch (status) {
      BudgetStatus.upcoming => 0,
      BudgetStatus.past => b.totalDays,
      BudgetStatus.active => dateOnly(now).difference(b.start).inDays + 1,
    };
    final avgPerDay = elapsed > 0 ? spent / elapsed : 0.0;
    final projected = avgPerDay * b.totalDays;
    final left = b.amount - spent;
    final days = b.daysLeft(now);

    final stats = <(String, String, Color?)>[
      ('Daily limit', money(b.amount / b.totalDays), null),
      ('Avg spent / day', money(avgPerDay), null),
      if (status == BudgetStatus.active) ...[
        ('Safe to spend / day', money(left > 0 && days > 0 ? left / days : 0), left > 0 ? null : AppColors.danger),
        (
          'Projected total',
          money(projected),
          projected > b.amount ? AppColors.danger : AppColors.success,
        ),
      ],
    ];

    // Category split, only meaningful for overall budgets.
    final byCat = <String, double>{};
    if (b.isOverall) {
      for (final e in expenses) {
        byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
      }
    }
    final topCats = byCat.entries.toList()..sort((x, y) => y.value.compareTo(x.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(b.title),
        actions: [
          IconButton(
            tooltip: 'Edit budget',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetFormPage(budget: b))),
          ),
          IconButton(
            tooltip: 'Delete budget',
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            onPressed: () async {
              if (await confirmDeleteBudget(context, b) && context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageListView(
        maxWidth: 820,
        bottom: 32,
        children: [
          BudgetCard(budget: b, spent: spent),
          const SizedBox(height: 12),
          AppCard(
            child: LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 560 ? stats.length : 2;
              final w = (c.maxWidth - (cols - 1) * 16) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final s in stats)
                    SizedBox(
                      width: w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(s.$2, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: s.$3)),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),
          if (status == BudgetStatus.active && projected > b.amount && spent <= b.amount) ...[
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'At your current pace you\'ll spend about ${money(projected)}, '
                      '${money(projected - b.amount)} over this budget. '
                      'Try to keep it under ${money(math.max(0, left) / math.max(1, days))} a day.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (topCats.isNotEmpty) ...[
            const SectionHeader('Where it went'),
            AppCard(
              child: Column(
                children: [
                  for (final e in topCats.take(6))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CategoryAvatar(e.key, size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Text(money(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                                const SizedBox(height: 6),
                                UsageBar(value: spent > 0 ? e.value / spent : 0, color: scheme.primary, height: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          SectionHeader('Expenses in this budget (${expenses.length})'),
          if (expenses.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No expenses yet',
                message: status == BudgetStatus.upcoming
                    ? 'This budget starts on ${fmtDate(b.start)}.'
                    : 'Expenses${b.isOverall ? '' : ' in ${b.category}'} between these dates will appear here.',
              ),
            )
          else
            GroupedExpenseList(
              expenses: expenses,
              onTap: (e) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpense(expense: e))),
            ),
        ],
      ),
    );
  }
}
