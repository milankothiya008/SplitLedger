import 'package:SmartSpend/models/budget.dart';
import 'package:SmartSpend/utils/format.dart';
import 'package:SmartSpend/utils/period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget', () {
    final b = Budget(amount: 1000, start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30));

    test('includes the whole last day', () {
      expect(b.contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(b.contains(DateTime(2026, 10, 1)), isFalse);
      expect(b.contains(DateTime(2026, 8, 31, 23, 59)), isFalse);
    });

    test('status and days left', () {
      expect(b.statusOn(DateTime(2026, 8, 31)), BudgetStatus.upcoming);
      expect(b.statusOn(DateTime(2026, 9, 27, 18)), BudgetStatus.active);
      expect(b.statusOn(DateTime(2026, 10, 1)), BudgetStatus.past);
      expect(b.daysLeft(DateTime(2026, 9, 27, 18)), 4);
      expect(b.daysLeft(DateTime(2026, 9, 30)), 1);
      expect(b.daysLeft(DateTime(2026, 10, 2)), 0);
      expect(b.totalDays, 30);
    });

    test('overlap is inclusive of shared edge days', () {
      final touching = Budget(amount: 1, start: DateTime(2026, 9, 30), end: DateTime(2026, 10, 5));
      final after = Budget(amount: 1, start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 5));
      expect(b.overlaps(touching), isTrue);
      expect(b.overlaps(after), isFalse);
    });

    test('overall vs category collections', () {
      expect(b.collection, 'Budget');
      final food = Budget(category: 'Food', amount: 1, start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 2));
      expect(food.collection, 'CategoryBudget');
      expect(food.toMap('u')['Category'], 'Food');
    });
  });

  group('Periods', () {
    final now = DateTime(2026, 9, 27, 15); // a Sunday

    test('week runs Monday to Sunday and excludes the day before', () {
      final w = spanFor(Period.week, now: now);
      expect(w.start, DateTime(2026, 9, 21));
      expect(w.contains(DateTime(2026, 9, 20, 22)), isFalse);
      expect(w.contains(DateTime(2026, 9, 27, 23, 59)), isTrue);
    });

    test('month excludes the last day of the previous month', () {
      final m = spanFor(Period.month, now: now);
      expect(m.contains(DateTime(2026, 8, 31, 20)), isFalse);
      expect(m.contains(DateTime(2026, 9, 30, 23)), isTrue);
      expect(m.contains(DateTime(2026, 10, 1)), isFalse);
    });

    test('yesterday across a month boundary', () {
      final y = spanFor(Period.yesterday, now: DateTime(2026, 10, 1, 9));
      expect(y.start, DateTime(2026, 9, 30));
      expect(y.end, DateTime(2026, 10, 1));
    });
  });

  test('money uses Indian grouping', () {
    expect(money(123456), '₹1,23,456');
    expect(money(99.5), '₹99.50');
  });
}
