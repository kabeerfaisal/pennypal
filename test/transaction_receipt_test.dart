import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/controllers/finance_controller.dart';
import 'package:penny_pal/services/receipt_service.dart';

TransactionModel parse(Map<String, dynamic> data) =>
    TransactionModel.fromFirestore(data, 'doc1');

void main() {
  group('TransactionModel receipt field', () {
    test('reads base64 receipt from Firestore', () {
      final tx = parse({
        'Title': 'Lunch',
        'Amount': 240,
        'Category': 'Food',
        'IsExpense': true,
        'Date': Timestamp.fromDate(DateTime(2026, 3, 4)),
        'ReceiptData': '/9j/4AAQSkZJRg==',
      });

      expect(tx.receiptData, '/9j/4AAQSkZJRg==');
      expect(tx.hasReceipt, isTrue);
    });

    test('defaults to no receipt when the field is absent', () {
      final tx = parse({
        'Title': 'Coffee',
        'Amount': 3,
        'Category': 'Food',
        'IsExpense': true,
      });

      expect(tx.receiptData, isEmpty);
      expect(tx.hasReceipt, isFalse);
    });

    test('tolerates a null receipt on documents saved before the feature', () {
      final tx = parse({
        'Title': 'Bus',
        'Amount': 5,
        'Category': 'Transport',
        'IsExpense': true,
        'ReceiptData': null,
      });

      expect(tx.hasReceipt, isFalse);
    });

    test('round trips the receipt through toMap without loss', () {
      final original = TransactionModel(
        id: '',
        title: 'Books',
        amount: 40,
        category: 'Education',
        date: DateTime(2026, 3, 4),
        isExpense: true,
        receiptData: 'aGVsbG8=',
      );

      final back = parse(original.toMap());
      expect(back.receiptData, original.receiptData);
    });

    test(
      'an encoded receipt stays inside the Firestore 1 MiB document cap',
      () {
        final tx = TransactionModel(
          id: '',
          title: 'Groceries',
          amount: 60,
          category: 'Food',
          date: DateTime(2026, 3, 4),
          receiptData: 'x' * ReceiptService.maxEncodedChars,
        );

        // A base64 string decodes to 3/4 of its length, so the raw image is
        // comfortably under the limit even with the other fields added.
        expect(
          ReceiptService.decode(tx.receiptData)!.length,
          lessThan(1024 * 1024),
        );
      },
    );

    test('copyWith clears the receipt and keeps the rest', () {
      final tx = TransactionModel(
        id: 'abc',
        title: 'Lunch',
        amount: 240,
        category: 'Food',
        date: DateTime(2026, 3, 4),
        isExpense: true,
        receiptData: 'aGVsbG8=',
      );

      final cleared = tx.copyWith(receiptData: '');
      expect(cleared.hasReceipt, isFalse);
      expect(cleared.title, tx.title);
      expect(cleared.amount, tx.amount);
      expect(cleared.date, tx.date);
      expect(cleared.id, 'abc');
    });
  });

  group('ReceiptService.decode', () {
    test('decodes valid base64', () {
      expect(ReceiptService.decode('aGVsbG8='), isNotNull);
    });

    test('returns null for empty or corrupt data instead of throwing', () {
      expect(ReceiptService.decode(''), isNull);
      expect(ReceiptService.decode('not base64 !!!'), isNull);
    });
  });

  group('ReceiptService.readableSize', () {
    test('formats bytes, KB and MB', () {
      expect(ReceiptService.readableSize(512), '512 B');
      expect(ReceiptService.readableSize(84 * 1024), '84 KB');
      expect(ReceiptService.readableSize(2 * 1024 * 1024), '2.0 MB');
    });
  });
}
