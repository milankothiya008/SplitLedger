import 'package:intl/intl.dart';

final _money0 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _money2 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _compact = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

/// ₹1,23,456 for whole amounts, ₹1,234.50 otherwise.
String money(double value) {
  final whole = (value - value.roundToDouble()).abs() < 0.005;
  return whole ? _money0.format(value) : _money2.format(value);
}

/// ₹1.2L style, for tight spaces like chart axes.
String compactMoney(double value) => value == 0 ? '₹0' : _compact.format(value);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String fmtShortDate(DateTime d) => DateFormat('d MMM').format(d);
String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);

String fmtRange(DateTime start, DateTime end) {
  if (isSameDay(start, end)) return fmtDate(start);
  if (start.year == end.year) return '${fmtShortDate(start)} – ${fmtDate(end)}';
  return '${fmtDate(start)} – ${fmtDate(end)}';
}

/// "Today", "Yesterday", or "Mon, 22 Sep 2026".
String relativeDay(DateTime d) {
  final today = dateOnly(DateTime.now());
  final day = dateOnly(d);
  if (day == today) return 'Today';
  if (day == DateTime(today.year, today.month, today.day - 1)) return 'Yesterday';
  return DateFormat('EEE, d MMM yyyy').format(d);
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
