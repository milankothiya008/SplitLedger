import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/format.dart';

enum BudgetStatus { active, upcoming, past }

/// A spending limit over an inclusive date range.
///
/// Overall budgets live in the `Budget` collection; category budgets live in
/// `CategoryBudget` and carry a `Category` field.
class Budget {
  final String? id;
  final String? category;
  final double amount;
  final DateTime start;
  final DateTime end;

  Budget({
    this.id,
    this.category,
    required this.amount,
    required DateTime start,
    required DateTime end,
  })  : start = dateOnly(start),
        end = dateOnly(end);

  bool get isOverall => category == null;
  String get collection => isOverall ? 'Budget' : 'CategoryBudget';
  String get title => category ?? 'Overall budget';

  DateTime get endExclusive => DateTime(end.year, end.month, end.day + 1);
  int get totalDays => end.difference(start).inDays + 1;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(endExclusive);

  bool overlaps(Budget other) => !other.start.isAfter(end) && !other.end.isBefore(start);

  BudgetStatus statusOn(DateTime now) {
    final today = dateOnly(now);
    if (today.isBefore(start)) return BudgetStatus.upcoming;
    if (today.isAfter(end)) return BudgetStatus.past;
    return BudgetStatus.active;
  }

  /// Days remaining including today; 0 once the budget has ended.
  int daysLeft(DateTime now) {
    final today = dateOnly(now);
    if (today.isAfter(end)) return 0;
    final from = today.isBefore(start) ? start : today;
    return end.difference(from).inDays + 1;
  }

  Map<String, dynamic> toMap(String uid) => {
        'Id': uid,
        'Amount': amount,
        'StartDate': Timestamp.fromDate(start),
        'EndDate': Timestamp.fromDate(end),
        if (!isOverall) 'Category': category,
      };

  static Budget? fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool isCategory,
  }) {
    final d = doc.data();
    final start = d['StartDate'];
    final end = d['EndDate'];
    final amount = d['Amount'];
    final category = d['Category'];
    if (start is! Timestamp || end is! Timestamp || amount is! num) return null;
    if (isCategory && category is! String) return null;
    return Budget(
      id: doc.id,
      category: isCategory ? category as String : null,
      amount: amount.toDouble(),
      start: start.toDate(),
      end: end.toDate(),
    );
  }
}
