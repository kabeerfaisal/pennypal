import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/suspended_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadingUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _BootScreen();
        }

        final user = snap.data;
        if (user == null) {
          _loadingUid = null;
          return const LoginScreen();
        }

        if (_loadingUid != user.uid) {
          _loadingUid = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FinanceController.instance.initForUser();
          });
        }

        return ListenableBuilder(
          listenable: FinanceController.instance,
          builder: (context, _) {
            final c = FinanceController.instance;
            if (!c.ready) return const _BootScreen();
            // A suspended account is blocked before the role is considered, so
            // a suspended admin also cannot get in.
            if (c.isSuspended) {
              return SuspendedScreen(
                name: c.userName,
                reason: c.suspendedReason,
              );
            }
            if (c.isAdmin) return const AdminShell();
            return const DashboardScreen();
          },
        );
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
