import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/format.dart';
import 'common.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.onTap, this.showDate = false});

  final Expense expense;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = expense.message.trim();
    final when = showDate ? '${relativeDay(expense.date)} · ${fmtTime(expense.date)}' : fmtTime(expense.date);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CategoryAvatar(expense.category),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.category,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    note.isEmpty ? when : '$note · $when',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '-${money(expense.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expenses grouped under "Today", "Yesterday", "Mon, 22 Sep 2026" headings.
class GroupedExpenseList extends StatelessWidget {
  const GroupedExpenseList({super.key, required this.expenses, required this.onTap});

  final List<Expense> expenses;
  final ValueChanged<Expense> onTap;

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<Expense>>{};
    for (final e in expenses) {
      groups.putIfAbsent(dateOnly(e.date), () => []).add(e);
    }
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(relativeDay(entry.key),
                      style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant, fontSize: 13)),
                ),
                Text(money(entry.value.fold(0.0, (t, e) => t + e.amount)),
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) const Divider(indent: 74),
                  ExpenseTile(expense: entry.value[i], onTap: () => onTap(entry.value[i])),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
