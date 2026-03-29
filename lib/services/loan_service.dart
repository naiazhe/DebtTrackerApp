import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/transaction_record.dart';

class LoanService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Loan> loans = [];
  bool isLoading = false;

  Future<void> loadLoans(int borrowerId) async {
    isLoading = true;
    notifyListeners();

    loans = await _db.getLoansByBorrower(borrowerId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllLoans(int userId) async {
    isLoading = true;
    notifyListeners();

    loans = await _db.getAllLoansByUser(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<Loan?> getLoanById(int loanId, int userId) async {
    return await _db.getLoanByIdForUser(loanId, userId);
  }

  Future<Loan> createLoan({
    required int userId,
    required int borrowerId,
    required double loanAmount,
    required double payoutAmount,
    required DateTime givenDate,
    required DateTime dueDate,
    required bool hasInterest,
    required String interestType,
    double? interestRate,
    int? interestIntervalDays,
    String? interestIntervalUnit,
    double? fixedInterestAmount,
    bool collectUpfront = false,
    String status = 'active',
    String? notes,
  }) async {
    if (loanAmount <= 0) throw Exception('Loan amount must be greater than 0');
    if (payoutAmount <= 0) throw Exception('Payout amount must be greater than 0');
    if (dueDate.isBefore(givenDate)) throw Exception('Due date must not be before given date');

    final borrowerOwnedByUser = await _db.isBorrowerOwnedByUser(borrowerId, userId);
    if (!borrowerOwnedByUser) {
      throw Exception('Unauthorized borrower access');
    }

    final totalInterest = Loan(
      borrowerId: borrowerId,
      loanAmount: loanAmount,
      payoutAmount: payoutAmount,
      givenDate: givenDate,
      dueDate: dueDate,
      hasInterest: hasInterest,
      interestType: interestType,
      interestRate: interestType == 'flat' ? interestRate : null,
      interestIntervalDays: interestType == 'flat' ? interestIntervalDays : null,
      interestIntervalUnit: interestType == 'flat' ? interestIntervalUnit : null,
      fixedInterestAmount: interestType == 'fixed' ? fixedInterestAmount : null,
      collectUpfront: collectUpfront,
      totalInterest: 0.0, // Placeholder
      totalPayable: 0.0, // Placeholder
      totalPaid: 0,
      remainingBalance: 0.0, // Placeholder
      status: status,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).calculateTotalInterest();

    final totalPayable = payoutAmount + totalInterest;

    final loan = Loan(
      borrowerId: borrowerId,
      loanAmount: loanAmount,
      payoutAmount: payoutAmount,
      givenDate: givenDate,
      dueDate: dueDate,
      hasInterest: hasInterest,
      interestType: interestType,
      interestRate: interestType == 'flat' ? interestRate : null,
      interestIntervalDays: interestType == 'flat' ? interestIntervalDays : null,
      interestIntervalUnit: interestType == 'flat' ? interestIntervalUnit : null,
      fixedInterestAmount: interestType == 'fixed' ? fixedInterestAmount : null,
      collectUpfront: collectUpfront,
      totalInterest: totalInterest,
      totalPayable: totalPayable,
      totalPaid: 0,
      remainingBalance: totalPayable,
      status: status,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final loanId = await _db.createLoan(loan);
    final createdLoan = loan.copyWith(loanId: loanId);

    return createdLoan;
  }

  Future<int> addLoanTransaction({required int userId, required int borrowerId, required int loanId, required double amount}) async {
    final transaction = TransactionRecord(
      userId: userId,
      borrowerId: borrowerId,
      loanId: loanId,
      type: 'loan',
      amount: amount,
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return await _db.createTransaction(transaction);
  }

  Future<void> updateLoan(Loan loan, int userId) async {
    if (loan.loanId == null) throw Exception('Loan ID is required for update');
    final updatedCount = await _db.updateLoanForUser(loan, userId);
    if (updatedCount == 0) throw Exception('Loan not found or unauthorized access');
    await loadAllLoans(userId);
  }

  Future<void> registerPayment({
    required Loan loan,
    required double amount,
    required DateTime paidAt,
    required int userId,
    required int borrowerId,
  }) async {
    if (amount <= 0) throw Exception('Payment amount must be greater than 0');

    final newTotalPaid = loan.totalPaid + amount;
    final remainingBalance = Loan.calculateRemainingBalance(totalPayable: loan.totalPayable, totalPaid: newTotalPaid);
    final status = remainingBalance <= 0 ? 'settled' : loan.status;

    final updatedLoan = Loan(
      loanId: loan.loanId,
      borrowerId: loan.borrowerId,
      loanAmount: loan.loanAmount,
      payoutAmount: loan.payoutAmount,
      givenDate: loan.givenDate,
      dueDate: loan.dueDate,
      hasInterest: loan.hasInterest,
      interestType: loan.interestType,
      interestRate: loan.interestRate,
      interestIntervalDays: loan.interestIntervalDays,
      interestIntervalUnit: loan.interestIntervalUnit,
      fixedInterestAmount: loan.fixedInterestAmount,
      collectUpfront: loan.collectUpfront,
      totalInterest: loan.totalInterest,
      totalPayable: loan.totalPayable,
      totalPaid: newTotalPaid,
      remainingBalance: remainingBalance,
      status: status,
      notes: loan.notes,
      createdAt: loan.createdAt,
      updatedAt: DateTime.now(),
    );

    final updatedCount = await _db.updateLoanForUser(updatedLoan, userId);
    if (updatedCount == 0) throw Exception('Loan not found or unauthorized access');

    final payment = PaymentEntry(
      loanId: loan.loanId!,
      amountPaid: amount,
      paymentDate: paidAt,
      createdAt: DateTime.now(),
    );
    await _db.createPayment(payment);

    final transaction = TransactionRecord(
      userId: userId,
      borrowerId: borrowerId,
      loanId: loan.loanId,
      type: 'payment',
      amount: amount,
      transactionDate: paidAt,
      createdAt: DateTime.now(),
    );
    await _db.createTransaction(transaction);

    await loadAllLoans(userId);
  }
}
