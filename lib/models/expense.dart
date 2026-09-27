import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String category;
  final double amount;
  final String message;
  final DateTime date;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.message,
    required this.date,
  });

  /// Returns null for malformed documents (missing date or amount) so a single
  /// bad record can't break every screen.
  static Expense? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final date = d['Date'];
    final amount = d['Amount'];
    if (date is! Timestamp || amount is! num) return null;

    final category = d['Category'];
    final message = d['Message'];
    return Expense(
      id: doc.id,
      category: category is String && category.trim().isNotEmpty ? category : 'Others',
      amount: amount.toDouble(),
      message: message is String ? message : '',
      date: date.toDate(),
    );
  }

  Map<String, dynamic> toMap(String uid) => {
        'Id': uid,
        'Category': category,
        'Amount': amount,
        'Message': message,
        'Date': Timestamp.fromDate(date),
      };
}
