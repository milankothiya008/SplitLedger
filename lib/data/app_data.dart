import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../utils/period.dart';

/// Single source of truth for the signed-in user's expenses and budgets.
///
/// Listens to Firestore in real time, so every screen updates as soon as an
/// expense or budget is added, edited or deleted — no manual refreshing.
class AppData extends ChangeNotifier {
  AppData() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onUser);
  }

  /// Static data with no Firebase connection, for tests and screenshots.
  @visibleForTesting
  AppData.preview({required List<Expense> expenses, required List<Budget> budgets}) {
    this.expenses = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    _overall = budgets.where((b) => b.isOverall).toList();
    _category = budgets.where((b) => !b.isOverall).toList();
  }

  static const _streams = {'Expenses', 'Budget', 'CategoryBudget'};

  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;
  final List<StreamSubscription> _subs = [];
  final Set<String> _ready = {};

  User? user;
  String? error;
  List<Expense> expenses = const [];
  List<Budget> _overall = const [];
  List<Budget> _category = const [];

  bool get isLoading => user != null && _ready.length < _streams.length;
  List<Budget> get budgets => [..._overall, ..._category];
  String get _uid => user!.uid;

  // ---------------------------------------------------------------- listening

  void _onUser(User? u) {
    if (u?.uid == user?.uid) {
      user = u;
      return;
    }
    _cancelSubs();
    user = u;
    error = null;
    expenses = const [];
    _overall = const [];
    _category = const [];
    if (u != null) {
      _listen(u.uid);
      _ensureProfile(u);
    }
    notifyListeners();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _query(String collection, String uid) =>
      _db.collection(collection).where('Id', isEqualTo: uid).snapshots();

  void _listen(String uid) {
    _subs.add(_query('Expenses', uid).listen((s) {
      expenses = s.docs.map(Expense.fromDoc).whereType<Expense>().toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _markReady('Expenses');
    }, onError: (Object e) => _onError('Expenses', e)));

    _subs.add(_query('Budget', uid).listen((s) {
      _overall = s.docs.map((d) => Budget.fromDoc(d, isCategory: false)).whereType<Budget>().toList();
      _markReady('Budget');
    }, onError: (Object e) => _onError('Budget', e)));

    _subs.add(_query('CategoryBudget', uid).listen((s) {
      _category = s.docs.map((d) => Budget.fromDoc(d, isCategory: true)).whereType<Budget>().toList();
      _markReady('CategoryBudget');
    }, onError: (Object e) => _onError('CategoryBudget', e)));
  }

  void _markReady(String name) {
    _ready.add(name);
    notifyListeners();
  }

  void _onError(String name, Object e) {
    debugPrint('Firestore $name stream error: $e');
    error = 'Could not load your data. Check your connection and try again.';
    _markReady(name);
  }

  void _cancelSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _ready.clear();
  }

  Future<void> _ensureProfile(User u) async {
    try {
      final ref = _db.collection('Users').doc(u.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'Name': u.displayName,
          'Email': u.email,
          'Gender': null,
          'Mobile': null,
          'Address': null,
          'Pincode': null,
        });
      }
    } catch (e) {
      debugPrint('Could not create user profile: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelSubs();
    super.dispose();
  }

  // ---------------------------------------------------------------- queries

  Iterable<Expense> expensesIn(DateSpan span) => expenses.where((e) => span.contains(e.date));

  static double sum(Iterable<Expense> list) => list.fold(0.0, (t, e) => t + e.amount);

  double totalIn(DateSpan span) => sum(expensesIn(span));

  List<Expense> expensesFor(Budget b) => expenses
      .where((e) => b.contains(e.date) && (b.isOverall || e.category == b.category))
      .toList();

  double spentFor(Budget b) => sum(expensesFor(b));

  List<Budget> budgetsWith(BudgetStatus status) {
    final now = DateTime.now();
    final list = budgets.where((b) => b.statusOn(now) == status).toList();
    list.sort((a, b) {
      if (a.isOverall != b.isOverall) return a.isOverall ? -1 : 1;
      return status == BudgetStatus.past ? b.end.compareTo(a.end) : a.start.compareTo(b.start);
    });
    return list;
  }

  Budget? get activeOverall {
    final active = budgetsWith(BudgetStatus.active).where((b) => b.isOverall);
    return active.isEmpty ? null : active.first;
  }

  /// Another budget of the same kind (overall, or same category) whose dates overlap.
  Budget? conflictFor(Budget candidate) {
    for (final b in budgets) {
      if (b.id != null && b.id == candidate.id) continue;
      if (b.category == candidate.category && b.overlaps(candidate)) return b;
    }
    return null;
  }

  /// Active budgets that an expense in [category] on [date] counts towards.
  List<Budget> budgetsAffectedBy(String category, DateTime date) => budgets
      .where((b) => b.contains(date) && (b.isOverall || b.category == category))
      .toList();

  // ---------------------------------------------------------------- writes

  Future<void> addExpense({
    required String category,
    required double amount,
    required String message,
    required DateTime date,
  }) {
    return _db.collection('Expenses').add(
          Expense(id: '', category: category, amount: amount, message: message, date: date).toMap(_uid),
        );
  }

  Future<void> updateExpense(Expense e) =>
      _db.collection('Expenses').doc(e.id).set(e.toMap(_uid));

  Future<void> deleteExpense(String id) => _db.collection('Expenses').doc(id).delete();

  Future<void> saveBudget(Budget b) {
    final col = _db.collection(b.collection);
    return b.id == null ? col.add(b.toMap(_uid)) : col.doc(b.id).set(b.toMap(_uid));
  }

  Future<void> deleteBudget(Budget b) => _db.collection(b.collection).doc(b.id).delete();

  /// Deletes every expense and budget owned by the user.
  Future<void> deleteAllData() async {
    final refs = <DocumentReference>[];
    for (final name in _streams) {
      final snap = await _db.collection(name).where('Id', isEqualTo: _uid).get();
      refs.addAll(snap.docs.map((d) => d.reference));
    }
    // Firestore batches are limited to 500 writes.
    for (var i = 0; i < refs.length; i += 450) {
      final batch = _db.batch();
      for (final r in refs.skip(i).take(450)) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }

  static Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        debugPrint('Google sign-out failed: $e');
      }
    }
    await FirebaseAuth.instance.signOut();
  }
}
