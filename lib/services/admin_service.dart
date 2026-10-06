import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/learning_article.dart';

/// Raised when an admin tries an action the app will not allow, such as
/// suspending the account they are signed in with. The message is written to be
/// shown to the user as is.
class AdminActionException implements Exception {
  final String message;
  const AdminActionException(this.message);

  @override
  String toString() => message;
}

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// The signed-in admin's own uid, used to block self-targeting actions.
  static String? get myUid => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<AppUser>> watchUsers() {
    return _db.collection('Users').snapshots().map((snap) {
      final users = snap.docs
          .map((d) => AppUser.fromFirestore(d.data(), d.id))
          .toList();
      users.sort((a, b) => a.fullName.compareTo(b.fullName));
      return users;
    });
  }

  Future<void> setRole(String userId, String role) async {
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      throw AdminActionException('You cannot change your own role');
    }
    await _db.collection('Users').doc(userId).update({
      'Role': role,
      'IsAdmin': role == 'Admin',
    });
  }

  /// Suspends or restores an account without deleting it.
  ///
  /// Refuses to suspend the signed-in admin. Locking yourself out is not
  /// recoverable from the app, so the guard is here as well as in the UI.
  Future<void> setSuspended(
    String userId,
    bool suspended, {
    String reason = 'Suspended by admin',
  }) async {
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      throw AdminActionException(
        suspended
            ? 'You cannot suspend your own account'
            : 'You cannot change your own access',
      );
    }
    await _db.collection('Users').doc(userId).update({
      'IsSuspended': suspended,
      'SuspendedAt': suspended ? FieldValue.serverTimestamp() : null,
      'SuspendedReason': suspended
          ? (reason.trim().isEmpty ? 'Suspended by admin' : reason.trim())
          : '',
    });
  }

  /// Watches one user document, so the detail screen updates the moment an
  /// action lands instead of waiting for a manual reload.
  Stream<AppUser?> watchUser(String userId) {
    return _db.collection('Users').doc(userId).snapshots().map((d) {
      final data = d.data();
      if (!d.exists || data == null) return null;
      return AppUser.fromFirestore(data, d.id);
    });
  }

  /// Wipes everything stored for a user: their transactions, goals, profile,
  /// notifications, AI chats and feedback.
  ///
  /// This does not touch the Firebase Authentication record, and nothing in the
  /// app can. The client SDKs deliberately expose no way to remove somebody
  /// else's sign-in, since otherwise any signed-in user could delete any other
  /// account.
  ///
  /// Kept because a suspended student who asks for their data to be cleared
  /// still needs it, and because [AuthService.deleteCurrentAccount] runs the
  /// same sweep once the sign-in is gone. It is deliberately not wired to any
  /// button: the admin panel has no Delete, since a button that removes the
  /// data but leaves the email taken reads as broken. The one deletion a
  /// student can start themselves lives in the profile screen.
  Future<void> deleteUserData(String userId) async {
    final ref = _db.collection('Users').doc(userId);
    for (final sub in const [
      'Transactions',
      'SavingGoals',
      'Profile',
      'Notifications',
    ]) {
      final snap = await ref.collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
    final chats = await ref.collection('Chats').get();
    for (final chat in chats.docs) {
      final messages = await chat.reference.collection('Messages').get();
      for (final m in messages.docs) {
        await m.reference.delete();
      }
      await chat.reference.delete();
    }
    await ref.delete();

    // Queries and feedback are owned by the user through a UserId field, not a
    // subcollection, so they are removed in batches.
    final snap = await _db
        .collection('Feedbacks')
        .where('UserId', isEqualTo: userId)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<LearningArticle>> watchArticles() {
    return _db.collection('LearningArticles').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => LearningArticle.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<List<LearningArticle>> loadArticles() async {
    try {
      final snap = await _db.collection('LearningArticles').get();
      if (snap.docs.isEmpty) return fallbackArticles;
      final list = snap.docs
          .map((d) => LearningArticle.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    } catch (e) {
      debugPrint('Learning load: $e');
      return fallbackArticles;
    }
  }

  Future<void> saveArticle(LearningArticle article) async {
    final data = article.toMap();
    if (article.id.isEmpty) {
      data['CreatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('LearningArticles').add(data);
    } else {
      await _db
          .collection('LearningArticles')
          .doc(article.id)
          .set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteArticle(String id) async {
    await _db.collection('LearningArticles').doc(id).delete();
  }

  static final List<LearningArticle> fallbackArticles = [
    LearningArticle(
      id: 'local-1',
      title: 'Budgeting Basics',
      summary: 'Learn how to create and stick to a budget that works for you.',
      body:
          'Start with income you can count on, then list needs before wants. '
          'A simple 50/30/20 split (needs / wants / savings) is enough for most students. '
          'Review the numbers every week so small leaks do not eat the month.',
      order: 1,
    ),
    LearningArticle(
      id: 'local-2',
      title: 'Saving for Goals',
      summary: 'Tips and tricks to help you save for the things you want.',
      body:
          'Name the goal, pick a date, and divide the remaining amount by months left. '
          'Move that amount as soon as money comes in, not at the end of the month. '
          'Even a small automatic transfer beats waiting for leftover cash.',
      order: 2,
    ),
    LearningArticle(
      id: 'local-3',
      title: 'Understanding Expenses',
      summary: 'Distinguish between needs and wants to save more.',
      body:
          'Needs keep you housed, fed, healthy, and able to study. '
          'Wants are optional — subscriptions, extra takeout, impulse shopping. '
          'Cut one want this week and send that money to a savings goal.',
      order: 3,
    ),
  ];
}
