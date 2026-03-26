class TransactionRecord {
  final int? transactionId;
  final int userId;
  final int borrowerId;
  final int? loanId;
  final String type;
  final double amount;
  final DateTime transactionDate;
  final DateTime createdAt;

  TransactionRecord({
    this.transactionId,
    required this.userId,
    required this.borrowerId,
    this.loanId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'user_id': userId,
      'borrower_id': borrowerId,
      'loan_id': loanId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      transactionId: map['transaction_id'] as int?,
      userId: map['user_id'] as int,
      borrowerId: map['borrower_id'] as int,
      loanId: map['loan_id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
