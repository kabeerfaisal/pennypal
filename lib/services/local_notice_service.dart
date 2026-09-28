import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows a real system notification on the phone.
///
/// This is what covers the "notifications should come on mobile too" case
/// without FCM: Firebase Cloud Messaging needs the Blaze plan, but a local
/// notification needs nothing but the device. It fires when the app is in the
/// background or closed, which an in-app banner cannot do.
///
/// The in-app notification centre stays the source of truth; this only mirrors
/// it to the system tray.
class LocalNoticeService {
  LocalNoticeService._();
  static final LocalNoticeService instance = LocalNoticeService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Android notification channels, so a student can silence categories
  /// separately if they want to.
  static const _budgetChannel = AndroidNotificationChannel(
    'pennypal_budget',
    'Budget and limit alerts',
    description: 'Warns you before you cross a budget or category cap.',
    importance: Importance.high,
  );

  static const _goalsChannel = AndroidNotificationChannel(
    'pennypal_goals',
    'Savings goal updates',
    description: 'Goal created, milestone reached, goal completed.',
    importance: Importance.defaultImportance,
  );

  static const _infoChannel = AndroidNotificationChannel(
    'pennypal_general',
    'General updates',
    description: 'Transactions, learning and admin messages.',
    importance: Importance.defaultImportance,
  );

  static const _budget = AndroidNotificationDetails(
    'pennypal_budget',
    'Budget and limit alerts',
    channelDescription: 'Warns you before you cross a budget or category cap.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _goals = AndroidNotificationDetails(
    'pennypal_goals',
    'Savings goal updates',
    channelDescription: 'Goal created, milestone reached, goal completed.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _info = AndroidNotificationDetails(
    'pennypal_general',
    'General updates',
    channelDescription: 'Transactions, learning and admin messages.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  bool _ready = false;
  bool _denied = false;

  bool get isReady => _ready;

  /// True when the student refused notifications, so the settings screen can
  /// explain why nothing is arriving instead of silently failing.
  bool get isDenied => _denied;

  /// Must be called once, after `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// Never throws: a device that will not grant the permission must not stop
  /// the app from starting.
  Future<void> init() async {
    if (_ready) return;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_budgetChannel);
      await android?.createNotificationChannel(_goalsChannel);
      await android?.createNotificationChannel(_infoChannel);

      // Android 13+ will not show anything without this. A refusal is recorded
      // rather than retried on the next launch.
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) _denied = true;

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Local notifications unavailable: $e');
      _ready = false;
    }
  }

  /// Mirrors a notice to the system tray. A failure here is never surfaced to
  /// the student as an error, because the in-app banner already fired.
  Future<void> show({
    required String title,
    required String body,
    String channel = 'general',
    int id = 0,
  }) async {
    if (!_ready || _denied) return;
    try {
      final details = switch (channel) {
        'budget' || 'limit' => _budget,
        'goal' => _goals,
        _ => _info,
      };
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
      );
    } catch (e) {
      debugPrint('Local notification show: $e');
    }
  }

  void dispose() {
    try {
      _plugin.cancelAll();
    } catch (_) {
      // Nothing to do; the tray is cleared when the process ends anyway.
    }
  }
}
