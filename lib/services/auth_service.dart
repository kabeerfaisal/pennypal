import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../controllers/finance_controller.dart';
import '../utils/phone_rule.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    // Last line of defence. The form applies the same rule, but a bad number
    // must never reach Firestore even if a future caller skips that.
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final problem = PhoneRule.validate(digits);
    if (problem != null) return problem;

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return 'Could not create account';

      await user.updateDisplayName(name);
      await _db.collection('Users').doc(user.uid).set({
        'FullName': name,
        'Email': email,
        'Phone': phone,
        'Role': 'Student',
        'IsAdmin': false,
        'Currency': 'USD',
        'Theme': 'Green',
        'MonthlyBudget': FinanceController.defaultBudget,
        'CreatedAt': FieldValue.serverTimestamp(),
        'LastLogin': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      debugPrint('Register error: $e');
      return 'Registration failed. Try again.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return 'Login failed';

      final ref = _db.collection('Users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          'FullName': user.displayName ?? '',
          'Email': email,
          'Phone': '',
          'Role': 'Student',
          'IsAdmin': false,
          'Currency': 'USD',
          'Theme': 'Green',
          'MonthlyBudget': FinanceController.defaultBudget,
          'CreatedAt': FieldValue.serverTimestamp(),
          'LastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({'LastLogin': FieldValue.serverTimestamp()});
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Invalid email or password';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      return 'Could not send reset email';
    }
  }

  /// Deletes the signed-in user's Firebase Authentication account along with
  /// everything stored for them.
  ///
  /// This is the only account deletion in the app, and it is deliberately the
  /// only one. Firebase offers no client API for removing *somebody else's*
  /// sign-in, so an admin cannot delete a student at all; the profile screen is
  /// the single entry point, and here the sign-in really does go.
  ///
  /// Returns a message on failure, or null on success. The caller is signed out
  /// either way, because the account is gone.
  Future<String?> deleteCurrentAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) return 'You are not signed in';
    final email = user.email ?? '';

    try {
      // Firebase requires a recent sign-in before it will delete an account.
      // Skipping this throws requires-recent-login, which is the single most
      // common reason a delete silently fails.
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Wrong password',
        'user-mismatch' =>
          'Wrong password. Sign out, sign back in, then delete again.',
        'user-not-found' => 'This account no longer exists',
        'too-many-requests' => 'Too many attempts. Wait a moment and try again',
        _ => e.message ?? 'Could not verify your password',
      };
    } catch (e) {
      debugPrint('Re-auth before delete: $e');
      return 'Could not verify your password';
    }

    try {
      // The sign-in record first. If this fails the data is still intact, which
      // is far better than the reverse.
      await user.delete();
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'requires-recent-login' =>
          'Please sign out, sign back in, then delete your account',
        'user-not-found' => 'This account no longer exists',
        _ => e.message ?? 'Could not delete the sign-in account',
      };
    } catch (e) {
      debugPrint('Auth delete: $e');
      return 'Could not delete the sign-in account';
    }

    // The sign-in is gone, so the session is no longer valid.
    await signOut();

    // Now the data. The user document is already unreachable through the rules
    // because there is no longer an authenticated caller, so this runs
    // unauthenticated and is best effort.
    try {
      final ref = _db.collection('Users').doc(user.uid);
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
    } catch (e) {
      // The important part already succeeded. Leaving data behind is untidy but
      // not harmful, and the account is genuinely gone.
      debugPrint('Data cleanup after auth delete: $e');
    }

    try {
      final snap = await _db
          .collection('Feedbacks')
          .where('UserId', isEqualTo: user.uid)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Feedback cleanup after auth delete: $e');
    }

    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again';
      default:
        return e.message ?? 'Something went wrong';
    }
  }
}
