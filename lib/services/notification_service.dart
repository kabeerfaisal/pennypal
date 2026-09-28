import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../widgets/notice_banner.dart';
import 'local_notice_service.dart';

/// What a notification is about. Drives the icon and the colour in the list.
enum NotifyKind { transaction, budget, goal, limit, admin, feedback, system }

/// One entry in the notification centre.
///
/// FCM is unavailable on this project (Firebase Cloud Messaging needs the Blaze
/// plan), so notifications are generated in the app and stored in Firestore.
/// That means they survive a restart and appear on every device the student
/// signs in on, which is more than a push notification would have given.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotifyKind kind;
  final DateTime at;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.at,
    this.read = false,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> d) {
    final raw = d['CreatedAt'];
    DateTime at;
    if (raw is Timestamp) {
      at = raw.toDate();
    } else if (raw is DateTime) {
      at = raw;
    } else {
      at = DateTime.now();
    }
    return AppNotification(
      id: id,
      title: '${d['Title'] ?? ''}',
      body: '${d['Body'] ?? ''}',
      kind: NotifyKind.values.firstWhere(
        (k) => k.name == d['Kind'],
        orElse: () => NotifyKind.system,
      ),
      at: at,
      read: d['Read'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'Title': title,
    'Body': body,
    'Kind': kind.name,
    'Read': read,
    'CreatedAt': FieldValue.serverTimestamp(),
  };

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    kind: kind,
    at: at,
    read: read ?? this.read,
  );
}

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  List<AppNotification> _items = [];
  bool _bound = false;

  /// Newest first.
  List<AppNotification> get items => _items;

  int get unreadCount => _items.where((n) => !n.read).length;

  /// Where notifications for the signed-in user are stored, or null when there
  /// is nobody signed in.
  ///
  /// Wrapped because `FirebaseAuth.instance` throws when Firebase failed to
  /// initialise, and main.dart deliberately keeps the app running in that case.
  /// Without this guard every notification would crash the app.
  CollectionReference<Map<String, dynamic>>? get _col {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      return FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Notifications');
    } catch (e) {
      debugPrint('Notifications collection unavailable: $e');
      return null;
    }
  }

  /// Subscribes to the stored notifications for the signed-in user.
  void bind() {
    if (_bound) return;
    final col = _col;
    if (col == null) return;
    _bound = true;

    col
        .orderBy('CreatedAt', descending: true)
        .limit(60)
        .snapshots()
        .listen(
          (snap) {
            _items = snap.docs
                .map((d) => AppNotification.fromFirestore(d.id, d.data()))
                .toList();
            notifyListeners();
          },
          onError: (e) {
            // A blocked or missing collection must not take the app down; the
            // in-memory list still works for the current session.
            debugPrint('Notifications listen: $e');
            notifyListeners();
          },
        );
  }

  /// Records a notification, raises the top banner, and mirrors it to the
  /// phone's system tray.
  ///
  /// Call this from wherever something happens. When Firestore is unavailable
  /// the entry is kept in memory only, so the UI never loses it mid-session.
  static void notify(
    String title,
    String body, {
    NotifyKind kind = NotifyKind.system,
    bool showBanner = true,
    bool showSystem = true,
    NoticeLevel level = NoticeLevel.info,
  }) {
    final s = instance;
    final entry = AppNotification(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      kind: kind,
      at: DateTime.now(),
    );
    s._items = [entry, ...s._items];

    final col = s._col;
    if (col == null) {
      s.notifyListeners();
    } else {
      // Fire and forget: a failed write must not break the action that caused
      // the notification, so the error is logged rather than thrown.
      _fireAndForget(col.add(entry.toMap()), 'Notification write');
    }

    if (showBanner) NoticeBanner.show(title, body, level: level);

    // Only the things worth interrupting someone for reach the system tray.
    // A routine "expense added" is noise on the lock screen.
    if (showSystem && _isWorthInterrupting(kind)) {
      _fireAndForget(
        LocalNoticeService.instance.show(
          title: title,
          body: body,
          channel: _channelFor(kind),
        ),
        'Local notification',
      );
    }
  }

  /// Budget and goal news is what a student wants to know about even when the
  /// app is closed. Routine transaction confirmations stay in-app.
  static bool _isWorthInterrupting(NotifyKind kind) =>
      kind == NotifyKind.budget ||
      kind == NotifyKind.limit ||
      kind == NotifyKind.goal ||
      kind == NotifyKind.admin;

  static String _channelFor(NotifyKind kind) => switch (kind) {
    NotifyKind.budget || NotifyKind.limit => 'budget',
    NotifyKind.goal => 'goal',
    _ => 'general',
  };

  /// Runs [work] without waiting for it, logging rather than throwing.
  static void _fireAndForget(Future<Object?> work, String label) {
    unawaited(() async {
      try {
        await work;
      } catch (e) {
        debugPrint('$label: $e');
      }
    }());
  }

  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].read) return;
    _items = [..._items]..[i] = _items[i].copyWith(read: true);
    notifyListeners();
    try {
      await _col?.doc(id).update({'Read': true});
    } catch (e) {
      debugPrint('Notification read: $e');
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    _items = _items.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    try {
      final col = _col;
      if (col == null) return;
      // A collection has no bulk update, so each document is written.
      final snap = await col.where('Read', isEqualTo: false).get();
      for (final d in snap.docs) {
        await d.reference.update({'Read': true});
      }
    } catch (e) {
      debugPrint('Notifications read all: $e');
    }
  }

  Future<void> remove(String id) async {
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners();
    try {
      await _col?.doc(id).delete();
    } catch (e) {
      debugPrint('Notification delete: $e');
    }
  }

  Future<void> clearAll() async {
    _items = [];
    notifyListeners();
    try {
      final col = _col;
      if (col == null) return;
      final snap = await col.get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      debugPrint('Notifications clear: $e');
    }
  }

  void reset() {
    _items = [];
    _bound = false;
    notifyListeners();
  }
}
