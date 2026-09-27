import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/models/budget.dart';
import 'package:SmartSpend/screens/AddExpense.dart';
import 'package:SmartSpend/screens/BudgetDetail.dart';
import 'package:SmartSpend/screens/ProfilePage.dart';
import 'package:SmartSpend/screens/SetBudget.dart';
import 'package:SmartSpend/theme/app_theme.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/utils/period.dart';
import 'package:SmartSpend/widgets/budget_widgets.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:SmartSpend/widgets/expense_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.onNavigate});

  /// Switches the shell to another tab (1 = Expenses, 3 = Budgets).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    if (data.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = data.user;
    final firstName = (user?.displayName ?? '').trim().split(' ').first;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final month = spanFor(Period.month);
    final daysSoFar = DateTime.now().day;
    final monthTotal = data.totalIn(month);

    final budgets = data.budgetsWith(BudgetStatus.active);
    final recent = data.expenses.take(6).toList();

    final budgetSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Active budgets',
            actionLabel: budgets.isEmpty ? null : 'See all', onAction: () => onNavigate(3)),
        if (budgets.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.savings_outlined,
              title: 'No active budget',
              message: 'Set a spending limit and SmartSpend will track it as you add expenses.',
              action: FilledButton.icon(
                onPressed: () => _open(context, const BudgetFormPage()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Set a budget'),
              ),
            ),
          )
        else
          for (final b in budgets.take(3)) ...[
            BudgetCard(
              budget: b,
              spent: data.spentFor(b),
              onTap: () => _open(context, BudgetDetailPage(budget: b)),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );

    final recentSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Recent expenses',
            actionLabel: recent.isEmpty ? null : 'See all', onAction: () => onNavigate(1)),
        if (recent.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message: 'Add your first expense to start tracking where your money goes.',
              action: FilledButton.icon(
                onPressed: () => _open(context, const AddExpense()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add expense'),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(indent: 74),
                  ExpenseTile(
                    expense: recent[i],
                    showDate: true,
                    onTap: () => _open(context, AddExpense(expense: recent[i])),
                  ),
                ],
              ],
            ),
          ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: PageListView(
          top: 16,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting(), style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(
                        firstName.isEmpty ? 'Welcome back' : 'Hi, $firstName',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                _ProfileButton(user?.displayName, user?.photoURL),
              ],
            ),
            if (data.error != null) ...[
              const SizedBox(height: 16),
              AppCard(
                color: scheme.errorContainer,
                child: Row(children: [
                  Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(child: Text(data.error!, style: TextStyle(color: scheme.onErrorContainer))),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            _MonthHero(total: monthTotal, budget: data.activeOverall, data: data),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth >= 640 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 108,
                ),
                children: [
                  _StatTile(Icons.today_rounded, 'Today', data.totalIn(spanFor(Period.today))),
                  _StatTile(Icons.history_rounded, 'Yesterday', data.totalIn(spanFor(Period.yesterday))),
                  _StatTile(Icons.date_range_rounded, 'This week', data.totalIn(spanFor(Period.week))),
                  _StatTile(Icons.show_chart_rounded, 'Daily average', monthTotal / daysSoFar,
                      caption: 'this month'),
                ],
              );
            }),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: budgetSection),
                  const SizedBox(width: 20),
                  Expanded(child: recentSection),
                ],
              )
            else ...[
              budgetSection,
              recentSection,
            ],
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton(this.name, this.photoUrl);
  final String? name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = (name ?? '').trim().isEmpty ? '?' : name!.trim()[0].toUpperCase();
    return Tooltip(
      message: 'Profile & settings',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: scheme.primaryContainer,
          foregroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          onForegroundImageError: photoUrl != null ? (_, __) {} : null,
          child: Text(initial, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _MonthHero extends StatelessWidget {
  const _MonthHero({required this.total, required this.budget, required this.data});

  final double total;
  final Budget? budget;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const onHero = Colors.white;
    final muted = Colors.white.withValues(alpha: 0.75);
    final b = budget;

    Widget budgetPart;
    if (b == null) {
      budgetPart = Row(
        children: [
          Expanded(
            child: Text('No overall budget running. Set one to see how much you can still spend.',
                style: TextStyle(color: muted, height: 1.35)),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetFormPage())),
            child: const Text('Set budget'),
          ),
        ],
      );
    } else {
      final spent = data.spentFor(b);
      final ratio = b.amount <= 0 ? 0.0 : spent / b.amount;
      final left = b.amount - spent;
      final days = b.daysLeft(now);
      final perDay = days > 0 && left > 0 ? left / days : 0.0;
      budgetPart = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Budget ${money(b.amount)}', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(ratio * 100).toStringAsFixed(0)}% used',
                  style: const TextStyle(color: onHero, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              color: ratio >= 1 ? const Color(0xFFFF8A8A) : ratio >= 0.75 ? const Color(0xFFFFC857) : Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            left >= 0
                ? '${money(left)} left · ${money(perDay)}/day for $days ${days == 1 ? 'day' : 'days'}'
                : '${money(-left)} over budget',
            style: TextStyle(color: left >= 0 ? onHero : const Color(0xFFFFB4B4), fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.brand, Color(0xFF4655C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spent this month', style: TextStyle(color: muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(money(total), style: const TextStyle(color: onHero, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          budgetPart,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.icon, this.label, this.value, {this.caption});

  final IconData icon;
  final String label;
  final double value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(money(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              if (caption != null)
                Text(caption!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
