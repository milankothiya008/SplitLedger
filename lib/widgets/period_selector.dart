import 'package:flutter/material.dart';

import '../utils/period.dart';

/// Horizontal row of period chips. "Custom" opens a date-range picker.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.custom,
    required this.onChanged,
  });

  final Period period;
  final DateTimeRange? custom;
  final void Function(Period period, DateTimeRange? custom) onChanged;

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: custom,
      helpText: 'Select date range',
    );
    if (picked != null) onChanged(Period.custom, picked);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in Period.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p == Period.custom ? periodTitle(p, custom) : p.label),
                avatar: p == Period.custom ? const Icon(Icons.date_range_rounded, size: 18) : null,
                selected: period == p,
                showCheckmark: false,
                onSelected: (_) => p == Period.custom ? _pickCustom(context) : onChanged(p, null),
              ),
            ),
        ],
      ),
    );
  }
}
