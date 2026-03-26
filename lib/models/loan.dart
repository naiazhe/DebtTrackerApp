class Loan {
  final int? loanId;
  final int borrowerId;
  final double loanAmount;
  final double payoutAmount;
  final DateTime givenDate;
  final DateTime dueDate;
  final bool hasInterest;
  final String interestType;
  final double? interestRate;
  final int? interestIntervalDays;
  final double? fixedInterestAmount;
  final bool collectUpfront;
  final double totalInterest;
  final double totalPayable;
  final double totalPaid;
  final double remainingBalance;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    this.loanId,
    required this.borrowerId,
    required this.loanAmount,
    required this.payoutAmount,
    required this.givenDate,
    required this.dueDate,
    required this.hasInterest,
    required this.interestType,
    this.interestRate,
    this.interestIntervalDays,
    this.fixedInterestAmount,
    this.collectUpfront = false,
    required this.totalInterest,
    required this.totalPayable,
    required this.totalPaid,
    required this.remainingBalance,
    this.status = 'active',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static double calculateTotalInterest({
    required double loanAmount,
    required bool hasInterest,
    required String interestType,
    double? interestRate,
    int? interestIntervalDays,
    double? fixedInterestAmount,
  }) {
    if (!hasInterest) return 0.0;
    if (interestType == 'flat') {
      final rate = interestRate ?? 0;
      return loanAmount * (rate / 100);
    } else {
      return fixedInterestAmount ?? 0;
    }
  }

  static double calculateTotalPayable({
    required double payoutAmount,
    required double totalInterest,
  }) {
    return payoutAmount + totalInterest;
  }

  static double calculateRemainingBalance({
    required double totalPayable,
    required double totalPaid,
  }) {
    final remaining = totalPayable - totalPaid;
    return remaining < 0 ? 0 : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'borrower_id': borrowerId,
      'loan_amount': loanAmount,
      'payout_amount': payoutAmount,
      'given_date': givenDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'has_interest': hasInterest ? 1 : 0,
      'interest_type': interestType,
      'interest_rate': interestRate,
      'interest_interval_days': interestIntervalDays,
      'fixed_interest_amount': fixedInterestAmount,
      'collect_upfront': collectUpfront ? 1 : 0,
      'total_interest': totalInterest,
      'total_payable': totalPayable,
      'total_paid': totalPaid,
      'remaining_balance': remainingBalance,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      loanId: map['loan_id'] as int?,
      borrowerId: map['borrower_id'] as int,
      loanAmount: (map['loan_amount'] as num).toDouble(),
      payoutAmount: (map['payout_amount'] as num).toDouble(),
      givenDate: DateTime.parse(map['given_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      hasInterest: (map['has_interest'] as int) == 1,
      interestType: map['interest_type'] as String,
      interestRate: map['interest_rate'] != null ? (map['interest_rate'] as num).toDouble() : null,
      interestIntervalDays: map['interest_interval_days'] as int?,
      fixedInterestAmount: map['fixed_interest_amount'] != null ? (map['fixed_interest_amount'] as num).toDouble() : null,
      collectUpfront: (map['collect_upfront'] as int) == 1,
      totalInterest: (map['total_interest'] as num).toDouble(),
      totalPayable: (map['total_payable'] as num).toDouble(),
      totalPaid: (map['total_paid'] as num).toDouble(),
      remainingBalance: (map['remaining_balance'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Loan copyWith({
    int? loanId,
    int? borrowerId,
    double? loanAmount,
    double? payoutAmount,
    DateTime? givenDate,
    DateTime? dueDate,
    bool? hasInterest,
    String? interestType,
    double? interestRate,
    int? interestIntervalDays,
    double? fixedInterestAmount,
    bool? collectUpfront,
    double? totalInterest,
    double? totalPayable,
    double? totalPaid,
    double? remainingBalance,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      loanId: loanId ?? this.loanId,
      borrowerId: borrowerId ?? this.borrowerId,
      loanAmount: loanAmount ?? this.loanAmount,
      payoutAmount: payoutAmount ?? this.payoutAmount,
      givenDate: givenDate ?? this.givenDate,
      dueDate: dueDate ?? this.dueDate,
      hasInterest: hasInterest ?? this.hasInterest,
      interestType: interestType ?? this.interestType,
      interestRate: interestRate ?? this.interestRate,
      interestIntervalDays: interestIntervalDays ?? this.interestIntervalDays,
      fixedInterestAmount: fixedInterestAmount ?? this.fixedInterestAmount,
      collectUpfront: collectUpfront ?? this.collectUpfront,
      totalInterest: totalInterest ?? this.totalInterest,
      totalPayable: totalPayable ?? this.totalPayable,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

