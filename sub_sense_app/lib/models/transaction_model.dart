import 'package:intl/intl.dart';

class TransactionRecord {
  final String date;
  final String rawDescription;
  final String merchant;
  final String category;
  final double amount;
  final String type;

  TransactionRecord({
    required this.date,
    required this.rawDescription,
    required this.merchant,
    required this.category,
    required this.amount,
    this.type = 'debit',
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      date: json['date'] as String? ?? '2026-01-01',
      rawDescription: json['raw_description'] as String? ?? '',
      merchant: json['merchant'] as String? ?? 'General',
      category: json['category'] as String? ?? 'General',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'debit',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'raw_description': rawDescription,
        'merchant': merchant,
        'category': category,
        'amount': amount,
        'type': type,
      };

  DateTime get dateTime {
    return DateTime.tryParse(date) ?? DateTime.now();
  }

  String get formattedDate {
    final dt = dateTime;
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
