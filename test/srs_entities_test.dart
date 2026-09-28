import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/models/transaction_model.dart';
import 'package:penny_pal/models/user_profile.dart';

TransactionModel parseTx(Map<String, dynamic> d) =>
    TransactionModel.fromFirestore(d, 't1');

void main() {
  group('TransactionModel paymentMode (SRS Transactions entity)', () {
    test('round trips the payment mode / income source', () {
      final tx = parseTx({
        'Title': 'Bus pass',
        'Amount': 25,
        'Category': 'Transport',
        'IsExpense': true,
        'PaymentMode': 'Cash',
      });
      expect(tx.paymentMode, 'Cash');
      expect(parseTx(tx.toMap()).paymentMode, 'Cash');
    });

    test('stores an income source the same way', () {
      final tx = parseTx({
        'Title': 'Scholarship',
        'Amount': 500,
        'Category': 'Gift',
        'IsExpense': false,
        'PaymentMode': 'Scholarship',
      });
      expect(tx.paymentMode, 'Scholarship');
    });

    test('defaults to empty for documents saved before the field existed', () {
      final tx = parseTx({
        'Title': 'Lunch',
        'Amount': 10,
        'Category': 'Food',
        'IsExpense': true,
      });
      expect(tx.paymentMode, isEmpty);
      expect(tx.toMap()['PaymentMode'], isEmpty);
    });

    test('tolerates a null value', () {
      final tx = parseTx({
        'Title': 'Lunch',
        'Amount': 10,
        'Category': 'Food',
        'IsExpense': true,
        'PaymentMode': null,
      });
      expect(tx.paymentMode, isEmpty);
    });

    test('copyWith can clear the payment mode', () {
      final tx = parseTx({
        'Title': 'Lunch',
        'Amount': 10,
        'Category': 'Food',
        'IsExpense': true,
        'PaymentMode': 'Card',
      });
      expect(tx.copyWith(paymentMode: '').paymentMode, isEmpty);
    });
  });

  group('UserProfile (SRS UserProfiles entity)', () {
    test('defaults match the specification', () {
      const p = UserProfile(userId: 'u1');
      expect(p.studentStatus, 'Undergraduate');
      expect(p.currency, 'USD');
      expect(p.notificationsEnabled, isTrue);
      expect(p.avatarEmoji, isNotEmpty);
    });

    test('reads every attribute back from Firestore', () {
      final p = UserProfile.fromFirestore({
        'StudentStatus': 'Postgraduate',
        'CurrencyPreference': 'PKR',
        'NotificationPreference': false,
        'ProfileImage': '🎓',
      }, 'u1');

      expect(p.studentStatus, 'Postgraduate');
      expect(p.currency, 'PKR');
      expect(p.notificationsEnabled, isFalse);
      expect(p.avatarEmoji, '🎓');
    });

    test('toMap uses the SRS attribute names', () {
      final map = const UserProfile(userId: 'u1').toMap();
      expect(map['UserId'], 'u1');
      expect(map.containsKey('StudentStatus'), isTrue);
      expect(map.containsKey('CurrencyPreference'), isTrue);
      expect(map.containsKey('NotificationPreference'), isTrue);
      expect(map.containsKey('ProfileImage'), isTrue);
      expect(map['UpdatedAt'], isA<FieldValue>());
    });

    test('a profile round trips without losing data', () {
      const original = UserProfile(
        userId: 'u1',
        studentStatus: 'Working',
        currency: 'INR',
        notificationsEnabled: false,
        avatarEmoji: '🚀',
      );
      final back = UserProfile.fromFirestore(original.toMap(), 'u1');
      expect(back.studentStatus, 'Working');
      expect(back.currency, 'INR');
      expect(back.notificationsEnabled, isFalse);
      expect(back.avatarEmoji, '🚀');
    });

    test('copyWith changes one field and keeps the rest', () {
      const p = UserProfile(
        userId: 'u1',
        studentStatus: 'Undergraduate',
        currency: 'USD',
        notificationsEnabled: true,
        avatarEmoji: '🙂',
      );
      final changed = p.copyWith(studentStatus: 'School student');
      expect(changed.studentStatus, 'School student');
      expect(changed.currency, 'USD');
      expect(changed.avatarEmoji, '🙂');
    });

    test('option lists are non-empty and have no duplicates', () {
      expect(UserProfile.statusOptions, isNotEmpty);
      expect(UserProfile.avatarOptions, isNotEmpty);
      expect(
        UserProfile.statusOptions.toSet().length,
        UserProfile.statusOptions.length,
      );
      expect(
        UserProfile.avatarOptions.toSet().length,
        UserProfile.avatarOptions.length,
      );
    });
  });
}
