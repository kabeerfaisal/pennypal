import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
        'MonthlyBudget': 2000,
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
          'MonthlyBudget': 2000,
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
