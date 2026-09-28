import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // disabled
import 'package:flutter/material.dart';

import 'controllers/finance_controller.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/local_notice_service.dart';
// import 'services/push_service.dart'; // disabled, see push_service.dart
import 'theme/app_theme.dart';
import 'utils/env_config.dart';
import 'widgets/notice_banner.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the key from .env so a plain `flutter run` works without any
  // --dart-define.
  await EnvConfig.load();
  // Asks for the notification permission on Android 13+ and creates the
  // channels. Never throws, so a refusal cannot block startup.
  await LocalNoticeService.instance.init();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const PennyPalApp());
}

class PennyPalApp extends StatelessWidget {
  const PennyPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final c = FinanceController.instance;
        // Only the green and dark themes remain.
        const primary = AppTheme.green;

        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'PennyPal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(primary),
          darkTheme: AppTheme.dark,
          themeMode: c.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => NoticeBanner(
            navKey: appNavigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
