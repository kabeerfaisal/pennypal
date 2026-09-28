import 'package:flutter/material.dart';

import '../screens/auth_gate.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../controllers/finance_controller.dart';

Future<void> openHomeForSession(BuildContext context) async {
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
    (route) => false,
  );
}

Future<void> logoutAndGoToLogin(BuildContext context) async {
  await AuthService().signOut();
  FinanceController.instance.clearData();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
