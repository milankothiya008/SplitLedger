import 'package:flutter/material.dart';

import 'format.dart';

enum Period { today, yesterday, week, month, year, all, custom }

extension PeriodLabel on Period {
  String get label => switch (this) {
        Period.today => 'Today',
        Period.yesterday => 'Yesterday',
        Period.week => 'This week',
        Period.month => 'This month',
        Period.year => 'This year',
        Period.all => 'All time',
        Period.custom => 'Custom',
      };
}

/// A half-open time span: [start, end).
class DateSpan {
  final DateTime start;
  final DateTime end;
  const DateSpan(this.start, this.end);

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  /// Number of calendar days covered.
  int get days => end.difference(start).inDays.clamp(1, 1 << 30);

  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);
}

DateSpan spanFor(Period period, {DateTimeRange? custom, DateTime? now}) {
  final t = dateOnly(now ?? DateTime.now());
  DateTime day(int offset) => DateTime(t.year, t.month, t.day + offset);

  switch (period) {
    case Period.today:
      return DateSpan(t, day(1));
    case Period.yesterday:
      return DateSpan(day(-1), t);
    case Period.week:
      final monday = day(-(t.weekday - 1));
      return DateSpan(monday, DateTime(monday.year, monday.month, monday.day + 7));
    case Period.month:
      return DateSpan(DateTime(t.year, t.month, 1), DateTime(t.year, t.month + 1, 1));
    case Period.year:
      return DateSpan(DateTime(t.year, 1, 1), DateTime(t.year + 1, 1, 1));
    case Period.all:
      return DateSpan(DateTime(2000), DateTime(3000));
    case Period.custom:
      final r = custom ?? DateTimeRange(start: t, end: t);
      final s = dateOnly(r.start);
      final e = dateOnly(r.end);
      return DateSpan(s, DateTime(e.year, e.month, e.day + 1));
  }
}

String periodTitle(Period period, DateTimeRange? custom) {
  if (period == Period.custom && custom != null) {
    return fmtRange(custom.start, custom.end);
  }
  return period.label;
}
