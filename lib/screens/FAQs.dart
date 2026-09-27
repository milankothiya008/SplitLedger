import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';

class FaqsPage extends StatelessWidget {
  const FaqsPage({super.key});

  static const _faqs = [
    (
      'How do I add an expense?',
      'Tap "Add expense" (the + button). Enter the amount, pick a category, optionally change the date or add a note, and save.',
    ),
    (
      'How do I edit or delete an expense?',
      'Open the Expenses tab (or tap an expense on the Home screen). Tap any expense to edit it; use the delete icon at the top to remove it.',
    ),
    (
      'How do I set a budget?',
      'Go to the Budgets tab and tap "Set budget". Choose "All spending" for an overall limit or "One category" for a category limit, enter the amount, and pick a period such as This month.',
    ),
    (
      'How is my budget tracked?',
      'Every expense dated within the budget period counts towards it automatically (only the chosen category for category budgets). You\'ll see what\'s left, how much you can safely spend per day, and a warning when you pass 75% or go over.',
    ),
    (
      'Can I have more than one budget?',
      'Yes. You can have one overall budget and one budget per category for any period. Budgets of the same kind can\'t overlap in dates.',
    ),
    (
      'Where can I see charts of my spending?',
      'The Insights tab shows a category breakdown and a spending trend for any period you choose.',
    ),
    (
      'How do I switch to dark mode?',
      'Open your profile (top-right on Home), tap the settings icon, and choose Light, Dark or System under Appearance.',
    ),
    (
      'How do I clear all my data?',
      'In Settings, choose "Reset all data". This permanently deletes all your expenses and budgets and cannot be undone.',
    ),
    (
      'Can I export my transactions?',
      'Not yet. Export to PDF or Excel is planned for a future update.',
    ),
    (
      'Is my financial data secure?',
      'Your data is stored in Google Firebase and is only accessible to your signed-in account.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: PageListView(
        maxWidth: 720,
        bottom: 32,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      expandedAlignment: Alignment.centerLeft,
                      title: Text(_faqs[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: [
                        Text(_faqs[i].$2, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
