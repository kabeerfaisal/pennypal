// DISABLED: push notifications are not used in this build.
//
// The Firebase Cloud Messaging + local notifications stack below is kept
// intact so it can be switched back on later. To re-enable:
//   1. Uncomment this whole file.
//   2. pubspec.yaml: uncomment firebase_messaging + flutter_local_notifications,
//      then run `flutter pub get`.
//   3. main.dart: uncomment the firebase_messaging import and the
//      onBackgroundMessage registration.
//   4. finance_controller.dart: uncomment the push_service import and
//      PushService.instance.init(), then switch NoticeService.show calls
//      back to PushService.instance.show.
//   5. Rebuild fully: a new plugin needs a native rebuild, hot reload is not
//      enough.
//
// In-app notices (goal milestones, spending warnings) now go through
// lib/services/notice_service.dart, which needs no permission or plugin.
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
//
// class PushService {
//   PushService._();
//   static final PushService instance = PushService._();
//
//   final _messaging = FirebaseMessaging.instance;
//   final _local = FlutterLocalNotificationsPlugin();
//   bool _ready = false;
//
//   Future<void> init() async {
//     if (_ready) return;
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     await _local.initialize(
//       const InitializationSettings(android: android, iOS: DarwinInitializationSettings()),
//     );
//
//     await _messaging.requestPermission(alert: true, badge: true, sound: true);
//
//     const channel = AndroidNotificationChannel(
//       'pennypal_alerts',
//       'PennyPal alerts',
//       description: 'Spending and savings reminders',
//       importance: Importance.high,
//     );
//     await _local
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//     FirebaseMessaging.onMessage.listen((msg) {
//       final n = msg.notification;
//       if (n != null) {
//         show(n.title ?? 'PennyPal', n.body ?? '');
//       }
//     });
//
//     _ready = true;
//     await saveToken();
//   }
//
//   Future<void> saveToken() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;
//       final token = await _messaging.getToken();
//       if (token == null) return;
//       await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
//         'FcmToken': token,
//       });
//     } catch (e) {
//       debugPrint('FCM token: $e');
//     }
//   }
//
//   Future<void> show(String title, String body) async {
//     const details = NotificationDetails(
//       android: AndroidNotificationDetails(
//         'pennypal_alerts',
//         'PennyPal alerts',
//         importance: Importance.high,
//         priority: Priority.high,
//       ),
//       iOS: DarwinNotificationDetails(),
//     );
//     await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     try {
//       await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(user.uid)
//           .collection('Notifications')
//           .add({
//         'Title': title,
//         'Body': body,
//         'CreatedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       debugPrint('Save notification: $e');
//     }
//   }
// }
