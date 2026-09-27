import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

class BudgetIcon extends StatelessWidget {
  const BudgetIcon(this.budget, {super.key, this.size = 44});
  final Budget budget;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!budget.isOverall) return CategoryAvatar(budget.category!, size: size);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(Icons.account_balance_wallet_rounded, color: scheme.onPrimary, size: size * 0.5),
    );
  }
}

/// Status label + colour for a budget given how much has been spent.
(String, Color, IconData) budgetHealth(Budget b, double spent) {
  final now = DateTime.now();
  final ratio = b.amount <= 0 ? 0.0 : spent / b.amount;
  switch (b.statusOn(now)) {
    case BudgetStatus.upcoming:
      return ('Upcoming', AppColors.brand, Icons.schedule_rounded);
    case BudgetStatus.past:
      return ratio > 1
          ? ('Went over', AppColors.danger, Icons.error_outline_rounded)
          : ('Stayed within', AppColors.success, Icons.check_circle_outline_rounded);
    case BudgetStatus.active:
      if (ratio > 1) return ('Over budget', AppColors.danger, Icons.error_outline_rounded);
      if (ratio >= 0.75) return ('Near limit', AppColors.warning, Icons.warning_amber_rounded);
      return ('On track', AppColors.success, Icons.check_circle_outline_rounded);
  }
}

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Budget budget;
  final double spent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final ratio = budget.amount <= 0 ? 0.0 : spent / budget.amount;
    final remaining = budget.amount - spent;
    final (label, color, icon) = budgetHealth(budget, spent);
    final status = budget.statusOn(now);
    final barColor = status == BudgetStatus.upcoming ? scheme.primary : AppColors.forUsage(ratio);

    final String timing = switch (status) {
      BudgetStatus.active => '${budget.daysLeft(now)} ${budget.daysLeft(now) == 1 ? 'day' : 'days'} left',
      BudgetStatus.upcoming => 'Starts ${fmtShortDate(budget.start)}',
      BudgetStatus.past => 'Ended ${fmtShortDate(budget.end)}',
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BudgetIcon(budget),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(fmtRange(budget.start, budget.end),
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Budget options',
                  icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
                  onSelected: (v) => v == 'edit' ? onEdit?.call() : onDelete?.call(),
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'), dense: true),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Delete'), dense: true),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(spent), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('of ${money(budget.amount)}', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              const Spacer(),
              Pill(label, color: color, icon: icon),
            ],
          ),
          const SizedBox(height: 10),
          UsageBar(value: ratio, color: barColor),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                remaining >= 0 ? '${money(remaining)} left' : '${money(-remaining)} over',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: remaining >= 0 ? scheme.onSurface : AppColors.danger,
                ),
              ),
              const Spacer(),
              Text('${(ratio * 100).toStringAsFixed(0)}% used · $timing',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
