import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/models/budget.dart';
import 'package:SmartSpend/screens/BudgetDetail.dart';
import 'package:SmartSpend/screens/SetBudget.dart';
import 'package:SmartSpend/theme/app_theme.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/widgets/budget_widgets.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Budgets tab: create budgets and track spending against them.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  void _openForm(BuildContext context, [Budget? budget]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetFormPage(budget: budget)));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    if (data.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final active = data.budgetsWith(BudgetStatus.active);
    final upcoming = data.budgetsWith(BudgetStatus.upcoming);
    final past = data.budgetsWith(BudgetStatus.past);
    final none = active.isEmpty && upcoming.isEmpty && past.isEmpty;

    Widget card(Budget b) => BudgetCard(
          budget: b,
          spent: data.spentFor(b),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetDetailPage(budget: b))),
          onEdit: () => _openForm(context, b),
          onDelete: () => confirmDeleteBudget(context, b),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          if (!none)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New budget'),
              ),
            ),
        ],
      ),
      body: PageListView(
        children: [
          if (none)
            AppCard(
              child: Column(
                children: [
                  EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'Plan your spending',
                    message: 'Set an overall limit for a month, or separate limits for categories '
                        'like Food and Shopping. Spending is tracked automatically as you add expenses.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Set your first budget'),
                    ),
                  ),
                  const Divider(),
                  const _HowItWorks(),
                ],
              ),
            )
          else ...[
            if (active.isNotEmpty) _Overview(active: active, data: data),
            if (active.isNotEmpty) ...[
              const SectionHeader('Active'),
              _CardGrid([for (final b in active) card(b)]),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppCard(
                  child: EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'No budget running right now',
                    message: 'Your budgets are either finished or haven\'t started yet.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Set a budget'),
                    ),
                  ),
                ),
              ),
            if (upcoming.isNotEmpty) ...[
              const SectionHeader('Upcoming'),
              _CardGrid([for (final b in upcoming) card(b)]),
            ],
            if (past.isNotEmpty) ...[
              const SectionHeader('Past'),
              _CardGrid([for (final b in past) card(b)]),
            ],
          ],
        ],
      ),
    );
  }
}

/// One column on phones, two on wider screens.
class _CardGrid extends StatelessWidget {
  const _CardGrid(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 760 ? 2 : 1;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    });
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.active, required this.data});
  final List<Budget> active;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    var onTrack = 0, near = 0, over = 0;
    for (final b in active) {
      final ratio = b.amount <= 0 ? 0 : data.spentFor(b) / b.amount;
      if (ratio > 1) {
        over++;
      } else if (ratio >= 0.75) {
        near++;
      } else {
        onTrack++;
      }
    }
    final overall = data.activeOverall;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overall != null) ...[
            Text('Safe to spend today', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Builder(builder: (_) {
              final left = overall.amount - data.spentFor(overall);
              final days = overall.daysLeft(DateTime.now());
              final perDay = left > 0 && days > 0 ? left / days : 0.0;
              return Text(
                money(perDay),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: left > 0 ? scheme.onSurface : AppColors.danger,
                ),
              );
            }),
            Text(
              'Based on your overall budget, ${fmtRange(overall.start, overall.end)}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _Count(onTrack, 'On track', AppColors.success),
              _Count(near, 'Near limit', AppColors.warning),
              _Count(over, 'Over budget', AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.count, this.label, this.color);
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const steps = [
      (Icons.tune_rounded, 'Choose a limit', 'Overall, or per category.'),
      (Icons.date_range_rounded, 'Pick a period', 'This month, a week, or any dates.'),
      (Icons.insights_rounded, 'Track it', 'See what\'s left and get alerts near the limit.'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          for (final s in steps)
            SizedBox(
              width: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(s.$1, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(s.$3, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
