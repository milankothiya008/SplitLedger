import 'dart:math' as math;

import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/data/categories.dart';
import 'package:SmartSpend/models/expense.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/utils/period.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:SmartSpend/widgets/period_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Insights tab: where the money went (by category) and when (trend).
class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _CategoryTotal {
  final String name;
  final double amount;
  final int count;
  final Color color;
  const _CategoryTotal(this.name, this.amount, this.count, this.color);
}

class _Bucket {
  final String label;
  final String tooltip;
  final double amount;
  const _Bucket(this.label, this.tooltip, this.amount);
}

class _ChartPageState extends State<ChartPage> {
  Period _period = Period.month;
  DateTimeRange? _custom;
  int _touched = -1;

  List<_CategoryTotal> _byCategory(List<Expense> list) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in list) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (var i = 0; i < sorted.length; i++)
        _CategoryTotal(sorted[i].key, sorted[i].value, counts[sorted[i].key]!, chartColor(i)),
    ];
  }

  List<_Bucket> _trend(DateSpan span, List<Expense> list) {
    final today = dateOnly(DateTime.now());
    var start = span.start;
    var end = span.end; // exclusive
    if (_period == Period.all) {
      if (list.isEmpty) return [];
      start = DateTime(list.last.date.year, list.last.date.month, 1);
      end = DateTime(today.year, today.month + 1, 1);
    }
    final days = end.difference(start).inDays;
    if (days < 2) return [];

    if (days <= 45) {
      final sums = List<double>.filled(days, 0);
      for (final e in list) {
        final i = dateOnly(e.date).difference(start).inDays;
        if (i >= 0 && i < days) sums[i] += e.amount;
      }
      final useWeekday = days <= 7;
      return [
        for (var i = 0; i < days; i++)
          () {
            final d = DateTime(start.year, start.month, start.day + i);
            return _Bucket(
              useWeekday ? DateFormat('E').format(d) : '${d.day}',
              DateFormat('EEE, d MMM').format(d),
              sums[i],
            );
          }(),
      ];
    }

    // Monthly buckets (at most the last 24 months).
    final months = <DateTime>[];
    for (var m = DateTime(start.year, start.month, 1); m.isBefore(end); m = DateTime(m.year, m.month + 1, 1)) {
      months.add(m);
    }
    final shown = months.length > 24 ? months.sublist(months.length - 24) : months;
    final sums = {for (final m in shown) m: 0.0};
    for (final e in list) {
      final key = DateTime(e.date.year, e.date.month, 1);
      if (sums.containsKey(key)) sums[key] = sums[key]! + e.amount;
    }
    return [
      for (final m in shown) _Bucket(DateFormat('MMM').format(m), DateFormat('MMMM yyyy').format(m), sums[m]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    if (data.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final span = spanFor(_period, custom: _custom);
    final list = data.expensesIn(span).toList();
    final total = AppData.sum(list);
    final cats = _byCategory(list);
    final buckets = _trend(span, list);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final donut = _DonutCard(
      cats: cats,
      total: total,
      touched: _touched,
      onTouch: (i) => setState(() => _touched = i),
    );
    final breakdown = _BreakdownCard(
      cats: cats,
      total: total,
      touched: _touched,
      onTap: (i) => setState(() => _touched = _touched == i ? -1 : i),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: PageListView(
        children: [
          PeriodSelector(
            period: _period,
            custom: _custom,
            onChanged: (p, c) => setState(() {
              _period = p;
              _custom = c;
              _touched = -1;
            }),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Nothing to show yet',
                message: 'There are no expenses in this period. Pick another period or add an expense.',
              ),
            )
          else ...[
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(children: [
                      donut,
                      if (buckets.isNotEmpty) ...[const SizedBox(height: 16), _TrendCard(buckets: buckets)],
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: breakdown),
                ],
              )
            else ...[
              donut,
              const SizedBox(height: 16),
              breakdown,
              if (buckets.isNotEmpty) ...[const SizedBox(height: 16), _TrendCard(buckets: buckets)],
            ],
          ],
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.cats, required this.total, required this.touched, required this.onTouch});

  final List<_CategoryTotal> cats;
  final double total;
  final int touched;
  final ValueChanged<int> onTouch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = touched >= 0 && touched < cats.length ? cats[touched] : null;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spending by category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 270,
                    sectionsSpace: 2,
                    centerSpaceRadius: 78,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        onTouch(response?.touchedSection?.touchedSectionIndex ?? -1);
                      },
                    ),
                    sections: [
                      for (var i = 0; i < cats.length; i++)
                        PieChartSectionData(
                          value: cats[i].amount,
                          color: cats[i].color,
                          radius: i == touched ? 34 : 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(focus?.name ?? 'Total',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(money(focus?.amount ?? total),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    if (focus != null)
                      Text('${(focus.amount / total * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: focus.color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.cats, required this.total, required this.touched, required this.onTap});

  final List<_CategoryTotal> cats;
  final double total;
  final int touched;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          for (var i = 0; i < cats.length; i++)
            InkWell(
              onTap: () => onTap(i),
              child: Container(
                color: i == touched ? cats[i].color.withValues(alpha: 0.08) : null,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    CategoryAvatar(cats[i].name, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(cats[i].name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(money(cats[i].amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          UsageBar(value: cats[i].amount / total, color: cats[i].color, height: 6),
                          const SizedBox(height: 4),
                          Text(
                            '${(cats[i].amount / total * 100).toStringAsFixed(1)}% · '
                            '${cats[i].count} ${cats[i].count == 1 ? 'expense' : 'expenses'}',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.buckets});

  final List<_Bucket> buckets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = buckets.map((b) => b.amount).fold(0.0, math.max);
    final step = math.max(1, (buckets.length / 10).ceil());
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spending trend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY * 1.15,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 1 : maxY * 1.15 / 4,
                  getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxY <= 0 ? 1 : maxY * 1.15 / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(compactMoney(value),
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= buckets.length || i % step != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(buckets[i].label,
                              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: scheme.inverseSurface,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${buckets[group.x].tooltip}\n${money(rod.toY)}',
                      TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: buckets[i].amount,
                        color: scheme.primary,
                        width: buckets.length > 20 ? 6 : 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
