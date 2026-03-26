class PaymentEntry {
  final int? paymentId;
  final int loanId;
  final double amountPaid;
  final DateTime paymentDate;
  final DateTime createdAt;

  PaymentEntry({
    this.paymentId,
    required this.loanId,
    required this.amountPaid,
    required this.paymentDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'loan_id': loanId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentEntry.fromMap(Map<String, dynamic> map) {
    return PaymentEntry(
      paymentId: map['payment_id'] as int?,
      loanId: map['loan_id'] as int,
      amountPaid: (map['amount_paid'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
