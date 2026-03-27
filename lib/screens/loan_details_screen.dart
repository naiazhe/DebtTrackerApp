import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart' as payment_model;
import '../services/borrower_service.dart';
import '../services/payment_service.dart';
import 'edit_loan_screen.dart';

class LoanDetailsScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailsScreen({Key? key, required this.loan}) : super(key: key);

  @override
  State<LoanDetailsScreen> createState() => LoanDetailsScreenState();
}

class LoanDetailsScreenState extends State<LoanDetailsScreen> {
  late Loan _currentLoan;
  Borrower? _borrower;
  List<payment_model.PaymentEntry> _payments = [];

  static const Color lightColor = Color(0xFFE6F1F6);
  static const Color normalColor = Color(0xFF0070A8);
  static const Color darkColor = Color(0xFF00547E);
  static const Color darkerColor = Color(0xFF00273B);

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
    _loadBorrowerAndPayments();
  }

  Future<void> _loadBorrowerAndPayments() async {
    final borrowerService = context.read<BorrowerService>();
    final paymentService = context.read<PaymentService>();

    final borrower = borrowerService.borrowers.firstWhere(
      (b) => b.borrowerId == _currentLoan.borrowerId,
      orElse: () => Borrower(
        userId: 0,
        firstName: 'Unknown',
        lastName: 'Borrower',
        contactNumber: '',
        address: '',
        referenceContact: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await paymentService.loadPayments(_currentLoan.loanId ?? 0);
    final payments = paymentService.payments;

    if (!mounted) return;
    setState(() {
      _borrower = borrower;
      _payments = payments;
    });
  }

  DateTime? _getFirstPaymentDate() {
    if (_payments.isEmpty) return null;
    final sorted = _payments.toList()..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
    return sorted.first.paymentDate;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        title: const Text('Loan Details', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: normalColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: normalColor),
            onPressed: () async {
              final updatedLoan = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditLoanScreen(loan: _currentLoan),
                ),
              );
              if (updatedLoan != null && updatedLoan is Loan) {
                setState(() {
                  _currentLoan = updatedLoan;
                });
                await _loadBorrowerAndPayments();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Borrower Details'),
              _buildInfoCard(
                icon: Icons.person,
                label: 'Borrower',
                value: _borrower != null ? '${_borrower!.firstName} ${_borrower!.lastName}' : 'Loading...',
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Loan Amount'),
              _buildInfoCard(
                icon: Icons.attach_money,
                label: 'Loan Amount',
                value: '₱ ${_formatCurrency(_currentLoan.loanAmount)}',
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.payments,
                label: 'Payout Amount',
                value: '₱ ${_formatCurrency(_currentLoan.payoutAmount)}',
                subValue: _currentLoan.collectUpfront && _currentLoan.hasInterest ? '(Loan - Upfront Interest)' : null,
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Interest Details'),
              _buildInfoCard(
                icon: Icons.info_outline,
                label: 'Interest Type',
                value: !_currentLoan.hasInterest ? 'None' : _currentLoan.interestType == 'flat' ? 'Flat Rate' : 'Fixed Amount',
              ),
              const SizedBox(height: 8),
              if (_currentLoan.interestType == 'flat' && _currentLoan.hasInterest)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildInfoCard(
                    icon: Icons.calendar_view_day,
                    label: 'Interest Interval',
                    value: _getInterestIntervalDisplay(_currentLoan.interestIntervalDays, _currentLoan.interestIntervalUnit),
                  ),
                ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.auto_graph,
                label: 'Total Interest',
                value: '₱ ${_formatCurrency(_currentLoan.totalInterest)}',
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Loan Timeline'),
              _buildInfoCard(
                icon: Icons.calendar_today,
                label: 'Given Date',
                value: _formatDate(_currentLoan.givenDate),
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.calendar_month,
                label: 'First Payment Date',
                value: _getFirstPaymentDate() != null ? _formatDate(_getFirstPaymentDate()!) : '—',
                subValue: _getFirstPaymentDate() == null ? '(No payments recorded)' : null,
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.event,
                label: 'Due Date',
                value: _formatDate(_currentLoan.dueDate),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Summary'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(
                      'Total Payable',
                      '₱ ${_formatCurrency(_currentLoan.totalPayable)}',
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Amount Paid',
                      '₱ ${_formatCurrency(_currentLoan.totalPaid)}',
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Remaining Balance',
                      '₱ ${_formatCurrency(_currentLoan.remainingBalance)}',
                      textColor: _currentLoan.remainingBalance > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_currentLoan.notes != null && _currentLoan.notes!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Notes'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Text(
                        _currentLoan.notes ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentLoan.status == 'active' ? lightColor : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentLoan.status == 'active' ? normalColor : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentLoan.status == 'active' ? Icons.info : Icons.check_circle,
                      color: _currentLoan.status == 'active' ? normalColor : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${_currentLoan.status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _currentLoan.status == 'active' ? normalColor : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: normalColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                if (subValue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subValue,
                      style: const TextStyle(fontSize: 11, color: Colors.black45, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getInterestIntervalDisplay(int? interval, String? unit) {
    if (interval == null || interval <= 0) {
      return 'One-Time';
    } else if (unit == 'months' && interval == 1) {
      return '1 month';
    } else if (unit == 'months' && interval == 3) {
      return '3 months';
    } else if (unit == 'months' && interval == 12) {
      return '1 year';
    } else if (unit == 'days') {
      return '$interval days';
    } else {
      return 'Custom';
    }
  }
}
