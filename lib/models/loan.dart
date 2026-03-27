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
  final String? interestIntervalUnit;
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
    this.interestIntervalUnit,
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

  double calculateTotalInterest() {
    if (!hasInterest) return 0.0;

    if (interestType == 'flat') {
      final rate = interestRate ?? 0;
      int intervals;
      final intervalValue = interestIntervalDays;
      final intervalUnit = interestIntervalUnit;

      if (intervalValue == null || intervalValue <= 0) {
        intervals = 1; // One-time
      } else if (intervalUnit == 'months') {
        final monthsBetween = ((dueDate.year - givenDate.year) * 12 + (dueDate.month - givenDate.month)).clamp(0, double.infinity).toInt();
        intervals = (monthsBetween / intervalValue).floor();
      } else {
        final durationDays = dueDate.difference(givenDate).inDays;
        intervals = durationDays > 0 ? (durationDays / intervalValue).floor() : 0;
      }

      return loanAmount * (rate / 100) * intervals;
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
      'interest_interval': interestIntervalDays,
      'interest_interval_unit': interestIntervalUnit,
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
    final rawInterval = map['interest_interval'] as int?;
    final rawUnit = map['interest_interval_unit'] as String?;

    // Backward compatibility for older rows that stored monthly/quarterly/yearly as 30/90/365 days.
    final normalized = _normalizeInterval(rawInterval, rawUnit);

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
      interestIntervalDays: normalized.value,
      interestIntervalUnit: normalized.unit,
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
    String? interestIntervalUnit,
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
      interestIntervalUnit: interestIntervalUnit ?? this.interestIntervalUnit,
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

  static ({int? value, String? unit}) _normalizeInterval(int? interval, String? unit) {
    if (interval == null || interval <= 0) {
      return (value: null, unit: null);
    }

    if (unit == 'months' || unit == 'days') {
      return (value: interval, unit: unit);
    }

    // Legacy fallback: previous implementation stored preset month options as day constants.
    if (interval == 30) return (value: 1, unit: 'months');
    if (interval == 90) return (value: 3, unit: 'months');
    if (interval == 365) return (value: 12, unit: 'months');

    return (value: interval, unit: 'days');
  }
}

