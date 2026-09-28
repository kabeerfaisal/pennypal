import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/parse.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;

  /// Base64 JPEG of the receipt, kept inside the document.
  ///
  /// Cloud Storage needs the Blaze billing plan, so the image is downscaled and
  /// embedded here instead. [receiptUrl] is only populated if a project later
  /// moves to Cloud Storage.
  final String receiptData;

  /// Firebase Storage download URL, used only if Storage is ever enabled.
  final String receiptUrl;

  /// How the money moved, listed on the SRS Transactions entity. Also covers
  /// the "source" the SRS asks for on income entries.
  final String paymentMode;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isExpense = true,
    this.receiptData = '',
    this.receiptUrl = '',
    this.paymentMode = '',
  });

  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TransactionModel(
      id: id,
      title: data['Title'] ?? data['title'] ?? '',
      amount: asMoney(data['Amount'] ?? data['amount']),
      category: data['Category'] ?? data['category'] ?? 'Other',
      date: _readDate(data['Date'] ?? data['date']),
      isExpense: data['IsExpense'] ?? data['isExpense'] ?? true,
      receiptData: data['ReceiptData'] ?? data['receiptData'] ?? '',
      receiptUrl: data['ReceiptUrl'] ?? data['receiptUrl'] ?? '',
      paymentMode: data['PaymentMode'] ?? data['paymentMode'] ?? '',
    );
  }

  bool get hasReceipt => receiptData.isNotEmpty || receiptUrl.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'Title': title,
      'Amount': amount,
      'Category': category,
      'Date': Timestamp.fromDate(date),
      'IsExpense': isExpense,
      'ReceiptData': receiptData,
      'ReceiptUrl': receiptUrl,
      'PaymentMode': paymentMode,
    };
  }

  TransactionModel copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    bool? isExpense,
    String? receiptData,
    String? receiptUrl,
    String? paymentMode,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      receiptData: receiptData ?? this.receiptData,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
