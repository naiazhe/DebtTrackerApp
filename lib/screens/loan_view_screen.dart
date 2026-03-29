import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart' as payment_model;
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../utils/message_helpers.dart';

class LoanViewScreen extends StatefulWidget {
  final Loan loan;

  const LoanViewScreen({Key? key, required this.loan}) : super(key: key);

  @override
  State<LoanViewScreen> createState() => _LoanViewScreenState();
}

class _LoanViewScreenState extends State<LoanViewScreen> {
  late Loan _currentLoan;
  Borrower? _borrower;
  List<payment_model.PaymentEntry> _payments = [];
  int _selectedTab = 0;

  static const Color lightColor = Color(0xFFE6F1F6);
  static const Color normalColor = Color(0xFF0070A8);

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
    _loadBorrowerAndPayments();
  }

  Future<void> _loadBorrowerAndPayments() async {
    final borrowerService = context.read<BorrowerService>();
    final paymentService = context.read<PaymentService>();
    final userId = context.read<UserService>().currentUser?.userId;
    if (userId == null) return;

    final borrower = borrowerService.borrowers.firstWhere(
      (b) => b.borrowerId == _currentLoan.borrowerId,
      orElse: () => Borrower(
        userId: 0,
        firstName: 'Unknown',
        lastName: 'Borrower',
        contactNumber: '',
        address: '',
        referenceName: '',
        referenceContact: '',
        referenceRelationship: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await paymentService.loadPayments(_currentLoan.loanId ?? 0, userId);
    final payments = paymentService.payments;

    if (!mounted) return;
    setState(() {
      _borrower = borrower;
      _payments = payments;
    });
  }

  Future<void> _refreshCurrentLoan() async {
    final loanId = _currentLoan.loanId;
    if (loanId == null) return;
    final userId = context.read<UserService>().currentUser?.userId;
    if (userId == null) return;
    final loanService = context.read<LoanService>();
    final refreshed = await loanService.getLoanById(loanId, userId);
    if (!mounted || refreshed == null) return;
    setState(() {
      _currentLoan = refreshed;
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

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan.',
      'Feb.',
      'Mar.',
      'Apr.',
      'May.',
      'Jun.',
      'Jul.',
      'Aug.',
      'Sep.',
      'Oct.',
      'Nov.',
      'Dec.'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2)}';
  }

  List<_PaymentHistoryRow> _buildPaymentRows() {
    final sortedAsc = _payments.toList()
      ..sort((a, b) {
        final dateCompare = a.paymentDate.compareTo(b.paymentDate);
        if (dateCompare != 0) return dateCompare;
        return (a.paymentId ?? 0).compareTo(b.paymentId ?? 0);
      });

    double runningRemaining = _currentLoan.totalPayable;
    final rows = <_PaymentHistoryRow>[];

    for (final payment in sortedAsc) {
      runningRemaining = (runningRemaining - payment.amountPaid).clamp(0.0, double.infinity).toDouble();
      rows.add(_PaymentHistoryRow(payment: payment, remainingBalance: runningRemaining));
    }

    return rows.reversed.toList();
  }

  Future<void> _showCollectPaymentModal() async {
    final loanId = _currentLoan.loanId;
    if (loanId == null) return;

    final amountController = TextEditingController();
    DateTime paidOn = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7FBFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        String? paymentDateError;
        String? amountPaidError;

        DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
        String? _validatePaymentDate(DateTime value) {
          final today = _dateOnly(DateTime.now());
          final givenDate = _dateOnly(_currentLoan.givenDate);
          final pickedDate = _dateOnly(value);

          if (pickedDate.isBefore(givenDate)) {
            return 'Payment date cannot be before loan start date.';
          }
          if (pickedDate.isAfter(today)) {
            return 'Payment date cannot be in the future.';
          }
          return null;
        }

        String? _validateAmountPaid(String amountText) {
          final amount = double.tryParse(amountText);
          if (amountText.isEmpty) {
            return 'Please enter payment amount.';
          }
          if (amount == null || amount <= 0) {
            return 'Payment amount must be greater than 0.';
          }
          if (amount > _currentLoan.remainingBalance) {
            return 'Payment exceeds remaining balance.';
          }
          return null;
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collect Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Paid On'),
                      subtitle: Text(_formatDisplayDate(paidOn)),
                      trailing: const Icon(Icons.calendar_today, size: 18, color: normalColor),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: paidOn,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setModalState(() {
                            paidOn = selected;
                            paymentDateError = _validatePaymentDate(paidOn);
                          });
                        }
                      },
                    ),
                    if (paymentDateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          paymentDateError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: lightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Remaining Balance',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₱ ${_formatCurrency(_currentLoan.remainingBalance)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount Paid',
                        border: const OutlineInputBorder(),
                        errorText: amountPaidError,
                      ),
                      onChanged: (_) {
                        setModalState(() {
                          amountPaidError = _validateAmountPaid(amountController.text.trim());
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: normalColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final amountText = amountController.text.trim();
                          final amount = double.tryParse(amountText);

                          setModalState(() {
                            paymentDateError = _validatePaymentDate(paidOn);
                            amountPaidError = _validateAmountPaid(amountText);
                          });

                          if (paymentDateError != null || amountPaidError != null || amount == null) {
                            return;
                          }

                          final userId = this.context.read<UserService>().currentUser?.userId;
                          if (userId == null) {
                            if (!mounted) return;
                            showErrorMessage(this.context, 'User not logged in');
                            return;
                          }

                          try {
                            await this.context.read<LoanService>().registerPayment(
                                  loan: _currentLoan,
                                  amount: amount,
                                  paidAt: paidOn,
                                  userId: userId,
                                  borrowerId: _currentLoan.borrowerId,
                                );

                            if (!mounted) return;
                            Navigator.of(modalContext).pop();
                            await _refreshCurrentLoan();
                            await _loadBorrowerAndPayments();

                            if (!mounted) return;
                            showSuccessMessage(this.context, 'Payment saved successfully');
                          } catch (e) {
                            if (!mounted) return;
                            showErrorMessage(this.context, 'Failed to save payment: $e');
                          }
                        },
                        child: const Text('Save Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: AppBar(
            title: const Text('Loan View', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: normalColor),
            actions: [
              IconButton(
                tooltip: 'Collect Payment',
                icon: const Icon(Icons.payments_rounded, color: normalColor),
                onPressed: _currentLoan.status == 'settled' ? null : _showCollectPaymentModal,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab('Details', 0),
                    _buildTab('Payments', 1),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _selectedTab == 0 ? _buildDetailsTab() : _buildPaymentsTab(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedTab == 1
          ? SafeArea(
              minimum: const EdgeInsets.all(16),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: normalColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _currentLoan.status == 'settled' ? null : _showCollectPaymentModal,
                  child: const Text('Collect Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? normalColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? normalColor : Colors.black54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
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
          _buildInfoCard(icon: Icons.attach_money, label: 'Loan Amount', value: '₱ ${_formatCurrency(_currentLoan.loanAmount)}'),
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
          _buildInfoCard(icon: Icons.auto_graph, label: 'Total Interest', value: '₱ ${_formatCurrency(_currentLoan.totalInterest)}'),
          const SizedBox(height: 20),
          _buildSectionHeader('Loan Timeline'),
          _buildInfoCard(icon: Icons.calendar_today, label: 'Given Date', value: _formatDate(_currentLoan.givenDate)),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.calendar_month,
            label: 'First Payment Date',
            value: _getFirstPaymentDate() != null ? _formatDate(_getFirstPaymentDate()!) : '—',
            subValue: _getFirstPaymentDate() == null ? '(No payments recorded)' : null,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(icon: Icons.event, label: 'Due Date', value: _formatDate(_currentLoan.dueDate)),
          const SizedBox(height: 20),
          _buildSectionHeader('Summary'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Total Payable', '₱ ${_formatCurrency(_currentLoan.totalPayable)}', isBold: true),
                const Divider(height: 16),
                _buildSummaryRow('Amount Paid', '₱ ${_formatCurrency(_currentLoan.totalPaid)}'),
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
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  child: Text(_currentLoan.notes ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87)),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final rows = _buildPaymentRows();

    if (rows.isEmpty) {
      return const Center(child: Text('No payments recorded yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = rows[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDisplayDate(row.payment.paymentDate), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  Text(
                    '₱ ${_formatCurrency(row.payment.amountPaid)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining Balance:',
                    style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₱ ${_formatCurrency(row.remainingBalance)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value, String? subValue}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
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
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
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

class _PaymentHistoryRow {
  final payment_model.PaymentEntry payment;
  final double remainingBalance;

  const _PaymentHistoryRow({required this.payment, required this.remainingBalance});
}
