import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/saving_goal.dart';
import '../models/transaction_model.dart';
import '../services/chat_history_service.dart';
import '../services/notification_service.dart';
// import '../services/push_service.dart'; // disabled, see push_service.dart
import '../utils/parse.dart';
import '../widgets/notice_banner.dart';

export '../models/saving_goal.dart';
export '../models/transaction_model.dart';

class FinanceController extends ChangeNotifier {
  static final FinanceController instance = FinanceController._();
  FinanceController._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<StreamSubscription> _subs = [];

  List<TransactionModel> _transactions = [];
  List<SavingGoal> _savingGoals = [];
  double _monthlyBudget = 2000;
  String _currency = 'USD';
  // Only green and dark remain; the yellow theme was removed. A stored
  // 'Yellow' value now falls back to green.
  bool _isYellowTheme = false;
  bool _isDarkTheme = false;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userRole = 'Student';
  String _studentStatus = 'Undergraduate';
  String _profileAvatar = '🙂';
  bool _alertsEnabled = true;
  bool _isSuspended = false;
  String _suspendedReason = '';
  bool _ready = false;
  Map<String, double> _categoryLimits = {};

  List<TransactionModel> get transactions => _transactions;
  List<SavingGoal> get savingGoals => _savingGoals;
  double get monthlyBudget => _monthlyBudget;
  String get currency => _currency;
  bool get isYellowTheme => _isYellowTheme;
  bool get isDarkTheme => _isDarkTheme;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userRole => _userRole;
  String get studentStatus => _studentStatus;
  String get profileAvatar => _profileAvatar;
  bool get alertsEnabled => _alertsEnabled;
  bool get isSuspended => _isSuspended;
  String get suspendedReason => _suspendedReason;
  bool get isAdmin => UserRole.isAdmin(_userRole);
  bool get ready => _ready;
  Map<String, double> get categoryLimits => Map.unmodifiable(_categoryLimits);

  String get currencySymbol {
    switch (_currency) {
      case 'PKR':
        return 'Rs';
      case 'INR':
        return '₹';
      case 'EURO':
        return '€';
      default:
        return '\$';
    }
  }

  List<TransactionModel> get _thisMonth {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
  }

  double get totalExpenses =>
      _thisMonth.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);

  double get totalIncome =>
      _thisMonth.where((t) => !t.isExpense).fold(0, (s, t) => s + t.amount);

  Map<String, double> categorySpendThisMonth() {
    final map = <String, double>{};
    for (final t in _thisMonth.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  double spentInCategoryThisMonth(String category) {
    return categorySpendThisMonth()[category] ?? 0;
  }

  String? categoryLimitBlock(
    String category,
    double extraAmount, {
    String? exceptId,
  }) {
    final limit = _categoryLimits[category];
    if (limit == null || limit <= 0) return null;
    var spent = spentInCategoryThisMonth(category);
    if (exceptId != null) {
      for (final t in _thisMonth) {
        if (t.id == exceptId && t.isExpense && t.category == category) {
          spent -= t.amount;
        }
      }
    }
    if (spent + extraAmount > limit + 0.009) {
      return 'Limit reached for $category ($currencySymbol${limit.toStringAsFixed(0)}). '
          'Spent $currencySymbol${spent.toStringAsFixed(0)}. '
          'Raise this category limit in Budget to add more.';
    }
    return null;
  }

  String financeSnapshot() {
    final cats = categorySpendThisMonth().entries
        .map((e) => '${e.key}: $currencySymbol${e.value.toStringAsFixed(0)}')
        .join(', ');
    final goals = _savingGoals
        .map(
          (g) =>
              '${g.title} ${g.savedAmount.toStringAsFixed(0)}/${g.targetAmount.toStringAsFixed(0)}',
        )
        .join('; ');
    return 'Currency $currency. Monthly budget $currencySymbol${_monthlyBudget.toStringAsFixed(0)}. '
        'This month spent $currencySymbol${totalExpenses.toStringAsFixed(0)}, '
        'income $currencySymbol${totalIncome.toStringAsFixed(0)}, '
        'remaining $currencySymbol${(_monthlyBudget - totalExpenses).clamp(0, _monthlyBudget).toStringAsFixed(0)}. '
        'Category spend: ${cats.isEmpty ? 'none yet' : cats}. '
        'Goals: ${goals.isEmpty ? 'none' : goals}.';
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('Users').doc(uid);
  }

  String? _boundUid;
  bool _claimAdmin = false;

  Future<void> initForUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (_boundUid == user.uid && _ready) return;

    _cancelSubs();
    _boundUid = user.uid;
    _claimAdmin = false;
    ChatHistoryService.instance.bindTo(user.uid);

    final ref = _db.collection('Users').doc(user.uid);
    try {
      final snap = await ref.get();
      if (snap.exists) {
        _applyUser(snap.data()!);
      }
    } catch (e) {
      debugPrint('User load error: $e');
    }

    _subs.add(
      ref.snapshots().listen((doc) {
        if (!doc.exists || doc.data() == null) return;
        _applyUser(doc.data()!);
        notifyListeners();
      }, onError: (e) => debugPrint('User listen: $e')),
    );

    _subs.add(
      ref.collection('Transactions').snapshots().listen((s) {
        _transactions =
            s.docs
                .map((d) => TransactionModel.fromFirestore(d.data(), d.id))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }, onError: (e) => debugPrint('Tx listen: $e')),
    );

    _subs.add(
      ref.collection('SavingGoals').snapshots().listen((s) {
        _savingGoals = s.docs
            .map((d) => SavingGoal.fromFirestore(d.data(), d.id))
            .toList();
        notifyListeners();
      }, onError: (e) => debugPrint('Goals listen: $e')),
    );

    _ready = true;
    notifyListeners();
    // PushService.instance.init(); // disabled, see push_service.dart
    NotificationService.instance.bind();
    await _loadProfile(user.uid);

    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? {};
      _claimAdmin =
          claims['admin'] == true ||
          '${claims['role']}'.toLowerCase() == 'admin' ||
          '${claims['Role']}'.toLowerCase() == 'admin';
      if (_claimAdmin && !UserRole.isAdmin(_userRole)) {
        _userRole = 'Admin';
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Reads the SRS `UserProfiles` document. Failures are ignored so a missing
  /// or blocked profile never blocks sign in.
  Future<void> _loadProfile(String uid) async {
    try {
      final doc = await _db
          .collection('Users')
          .doc(uid)
          .collection('Profile')
          .doc('me')
          .get();
      final d = doc.data();
      if (d == null) return;
      _studentStatus = d['StudentStatus'] ?? _studentStatus;
      _profileAvatar = d['ProfileImage'] ?? _profileAvatar;
      _alertsEnabled = d['NotificationPreference'] != false;
      notifyListeners();
    } catch (e) {
      debugPrint('Profile load: $e');
    }
  }

  /// Persists the profile fields edited on the settings screen.
  Future<void> saveProfile({
    required String studentStatus,
    required String avatarEmoji,
    required bool alertsEnabled,
  }) async {
    _studentStatus = studentStatus;
    _profileAvatar = avatarEmoji;
    _alertsEnabled = alertsEnabled;
    notifyListeners();
    final ref = _userDoc;
    if (ref == null) return;
    try {
      await ref.collection('Profile').doc('me').set({
        'UserId': ref.id,
        'StudentStatus': studentStatus,
        'CurrencyPreference': _currency,
        'NotificationPreference': alertsEnabled,
        'ProfileImage': avatarEmoji,
        'UpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Profile save: $e');
    }
  }

  void _applyUser(Map<String, dynamic> data) {
    _currency = data['Currency'] ?? data['currency'] ?? 'USD';
    final theme = data['Theme'] ?? data['theme'];
    _isYellowTheme = theme == 'Yellow';
    _isDarkTheme = theme == 'Dark';
    _isSuspended = data['IsSuspended'] == true;
    _suspendedReason = data['SuspendedReason'] ?? '';
    _userName = data['FullName'] ?? data['fullName'] ?? '';
    _userEmail = data['Email'] ?? data['email'] ?? '';
    _userPhone = data['Phone'] ?? data['phone'] ?? '';
    _userRole = UserRole.fromData(data);
    if (_claimAdmin) _userRole = 'Admin';
    _monthlyBudget = asMoney(
      data['MonthlyBudget'] ?? data['monthlyBudget'],
      2000,
    );
    _categoryLimits = {};
    final rawLimits = data['CategoryLimits'] ?? data['categoryLimits'];
    if (rawLimits is Map) {
      rawLimits.forEach((k, v) {
        _categoryLimits['$k'] = asMoney(v);
      });
    }
  }

  Future<String?> addTransaction(TransactionModel tx) async {
    final ref = _userDoc;
    if (ref == null) return 'Not signed in';
    if (tx.isExpense) {
      final block = categoryLimitBlock(tx.category, tx.amount);
      if (block != null) return block;
    }
    await ref.collection('Transactions').add(tx.toMap());

    NotificationService.notify(
      tx.isExpense ? 'Expense added' : 'Income added',
      '${tx.title} — $currencySymbol${tx.amount.toStringAsFixed(2)}',
      kind: tx.isExpense ? NotifyKind.transaction : NotifyKind.budget,
      showBanner: false,
      level: NoticeLevel.success,
    );
    await _maybeWarnSpending(tx.category);
    await _maybeWarnBudget(tx);
    return null;
  }

  Future<String?> updateTransaction(TransactionModel tx) async {
    final ref = _userDoc;
    if (ref == null) return 'Not signed in';
    if (tx.isExpense) {
      final block = categoryLimitBlock(tx.category, tx.amount, exceptId: tx.id);
      if (block != null) return block;
    }
    await ref.collection('Transactions').doc(tx.id).update(tx.toMap());
    NotificationService.notify(
      'Transaction updated',
      '${tx.title} — $currencySymbol${tx.amount.toStringAsFixed(2)}',
      kind: NotifyKind.transaction,
      showBanner: false,
    );
    if (tx.isExpense) await _maybeWarnBudget(tx);
    return null;
  }

  Future<void> deleteTransaction(String id) async {
    final ref = _userDoc;
    if (ref == null) return;
    // The receipt is embedded in the document, so removing the document is
    // enough. There is no separate file to clean up.
    await ref.collection('Transactions').doc(id).delete();
  }

  Future<void> addSavingGoal(SavingGoal goal) async {
    final ref = _userDoc;
    if (ref == null) return;
    await ref.collection('SavingGoals').add(goal.toMap());
    NotificationService.notify(
      'Savings goal created',
      '${goal.title} — target $currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
      kind: NotifyKind.goal,
      showBanner: false,
      level: NoticeLevel.success,
    );
  }

  Future<void> updateSavingGoal(SavingGoal goal) async {
    final ref = _userDoc;
    if (ref == null) return;
    await ref.collection('SavingGoals').doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteSavingGoal(String id) async {
    final ref = _userDoc;
    if (ref == null) return;
    await ref.collection('SavingGoals').doc(id).delete();
  }

  /// Goals split into active and archived, newest archive first.
  List<SavingGoal> get activeGoals =>
      _savingGoals.where((g) => !g.archived).toList();

  List<SavingGoal> get archivedGoals {
    final list = _savingGoals.where((g) => g.archived).toList();
    list.sort((a, b) {
      final at = a.archivedAt;
      final bt = b.archivedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return list;
  }

  /// Moves a goal between the active list and the archive.
  Future<void> setGoalArchived(SavingGoal goal, bool archived) async {
    final ref = _userDoc;
    if (ref == null) return;
    await ref.collection('SavingGoals').doc(goal.id).update({
      'Archived': archived,
      'ArchivedAt': archived ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> addToGoal(SavingGoal goal, double amount) async {
    if (amount <= 0) return;
    final next = goal.copyWith(savedAmount: goal.savedAmount + amount);
    await updateSavingGoal(next);
    if (next.progress >= 1 && goal.progress < 1) {
      NotificationService.notify(
        'Goal complete',
        '${goal.title} is fully funded. Well done.',
        kind: NotifyKind.goal,
        level: NoticeLevel.success,
      );
    } else if (next.progress >= 0.75 && goal.progress < 0.75) {
      NotificationService.notify(
        'Savings milestone',
        '${goal.title} is 75% funded. Keep it going.',
        kind: NotifyKind.goal,
        level: NoticeLevel.success,
      );
    } else if (next.progress >= 0.5 && goal.progress < 0.5) {
      NotificationService.notify(
        'Savings milestone',
        '${goal.title} is halfway there.',
        kind: NotifyKind.goal,
        level: NoticeLevel.success,
      );
    }
  }

  Future<void> setCategoryLimit(String category, double limit) async {
    _categoryLimits[category] = limit;
    notifyListeners();
    await _userDoc?.update({'CategoryLimits': _categoryLimits});
  }

  Future<void> _maybeWarnSpending(String category) async {
    final limit = _categoryLimits[category];
    if (limit == null || limit <= 0) return;
    final spent = spentInCategoryThisMonth(category);
    final ratio = spent / limit;
    if (ratio >= 1) {
      NotificationService.notify(
        'Spending limit hit',
        '$category is at its monthly limit. New expenses are blocked until you raise it.',
        kind: NotifyKind.limit,
        level: NoticeLevel.warning,
      );
    } else if (ratio >= 0.8) {
      NotificationService.notify(
        'Spending warning',
        '$category is at ${(ratio * 100).toInt()}% of its limit.',
        kind: NotifyKind.limit,
        level: NoticeLevel.warning,
      );
    }
  }

  /// Warns once when the month's spending passes the overall budget. The
  /// banner still shows, but the entry is also stored in the notification
  /// centre so it is not lost if the student is not looking at the screen.
  Future<void> _maybeWarnBudget(TransactionModel tx) async {
    if (!tx.isExpense || _monthlyBudget <= 0) return;
    final spent = totalExpenses;
    final ratio = spent / _monthlyBudget;

    if (ratio >= 1) {
      NotificationService.notify(
        'Monthly budget exceeded',
        'You have spent $currencySymbol${spent.toStringAsFixed(0)} of '
            '$currencySymbol${_monthlyBudget.toStringAsFixed(0)}. '
            'Review your spending in Budget.',
        kind: NotifyKind.budget,
        level: NoticeLevel.warning,
      );
    } else if (ratio >= 0.9) {
      NotificationService.notify(
        'Budget almost used up',
        '${(ratio * 100).toInt()}% of this month\'s budget is spent.',
        kind: NotifyKind.budget,
        level: NoticeLevel.warning,
      );
    }
  }

  Future<void> setCurrency(String val) async {
    _currency = val;
    notifyListeners();
    await _userDoc?.update({'Currency': val});
  }

  Future<void> setTheme(String theme) async {
    _isYellowTheme = theme == 'Yellow';
    _isDarkTheme = theme == 'Dark';
    notifyListeners();
    await _userDoc?.update({'Theme': theme});
  }

  Future<void> setBudget(double budget) async {
    _monthlyBudget = budget;
    notifyListeners();
    await _userDoc?.update({'MonthlyBudget': budget});
  }

  /// Removes the monthly budget entirely, as the SRS asks for delete as well
  /// as update. Defaults back to the starting value so the UI stays sane.
  Future<void> clearBudget() async {
    _monthlyBudget = 2000;
    notifyListeners();
    await _userDoc?.update({'MonthlyBudget': 2000});
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    _userName = name;
    _userPhone = phone;
    notifyListeners();
    await _userDoc?.update({'FullName': name, 'Phone': phone});
    final user = _auth.currentUser;
    if (user != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
  }

  void clearData() {
    _cancelSubs();
    NotificationService.instance.reset();
    // So a second student signing in on the same device never sees the first
    // one's AI conversation.
    ChatHistoryService.instance.reset();
    _transactions = [];
    _savingGoals = [];
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _userRole = 'Student';
    _studentStatus = 'Undergraduate';
    _profileAvatar = '🙂';
    _alertsEnabled = true;
    _isSuspended = false;
    _suspendedReason = '';
    _currency = 'USD';
    _isYellowTheme = false;
    _isDarkTheme = false;
    _monthlyBudget = 2000;
    _categoryLimits = {};
    _ready = false;
    _boundUid = null;
    _claimAdmin = false;
    notifyListeners();
  }

  void _cancelSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
