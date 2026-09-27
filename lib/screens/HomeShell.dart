import 'package:SmartSpend/screens/AddExpense.dart';
import 'package:SmartSpend/screens/BudgetsPage.dart';
import 'package:SmartSpend/screens/ChartPage.dart';
import 'package:SmartSpend/screens/Dashboard.dart';
import 'package:SmartSpend/screens/RecordPage.dart';
import 'package:SmartSpend/screens/SetBudget.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';

/// Main app frame: bottom navigation on phones, a side rail on wide screens.
/// Tabs are kept alive in an IndexedStack so switching is instant.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _budgetsTab = 3;
  int _index = 0;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Expenses'),
    (Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Insights'),
    (Icons.savings_outlined, Icons.savings_rounded, 'Budgets'),
  ];

  void _go(int i) => setState(() => _index = i);

  void _primaryAction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _index == _budgetsTab ? const BudgetFormPage() : const AddExpense(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(onNavigate: _go),
      const RecordPage(),
      const ChartPage(),
      const BudgetsPage(),
    ];
    final body = IndexedStack(index: _index, children: pages);
    final isBudgets = _index == _budgetsTab;
    final actionLabel = isBudgets ? 'Set budget' : 'Add expense';

    if (!isWide(context)) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'primary-action',
          onPressed: _primaryAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
          ],
        ),
      );
    }

    final extended = MediaQuery.sizeOf(context).width >= 1200;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 220,
            selectedIndex: _index,
            onDestinationSelected: _go,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                crossAxisAlignment: extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/images/logo.jpg', width: 36, height: 36),
                        ),
                        if (extended) ...[
                          const SizedBox(width: 10),
                          Text('SmartSpend',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18, color: scheme.onSurface)),
                        ],
                      ],
                    ),
                  ),
                  extended
                      ? FloatingActionButton.extended(
                          heroTag: 'primary-action',
                          elevation: 0,
                          onPressed: _primaryAction,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(actionLabel),
                        )
                      : FloatingActionButton(
                          heroTag: 'primary-action',
                          elevation: 0,
                          tooltip: actionLabel,
                          onPressed: _primaryAction,
                          child: const Icon(Icons.add_rounded),
                        ),
                ],
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
