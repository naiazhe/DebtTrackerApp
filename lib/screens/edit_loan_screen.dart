import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/user_service.dart';
import '../utils/message_helpers.dart';


class EditLoanScreen extends StatefulWidget {
  final Loan loan;

  const EditLoanScreen({Key? key, required this.loan}) : super(key: key);

  @override
  State<EditLoanScreen> createState() => _EditLoanScreenState();
}

class _EditLoanScreenState extends State<EditLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  Borrower? _selectedBorrower;
  final _loanAmountController = TextEditingController();
  final _givenDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _intervalController = TextEditingController();
  final _fixedInterestController = TextEditingController();

  DateTime? _givenDate;
  DateTime? _dueDate;

  bool _hasInterest = false;
  bool _collectUpfront = false;
  String _interestApplication = 'one-time';
  String _interestType = 'flat';

  double _totalInterest = 0.0;
  double _payoutAmount = 0.0;
  double _totalPayable = 0.0;

  String? _loanAmountError;
  String? _givenDateError;
  String? _dueDateError;
  String? _interestRateError;
  String? _intervalError;
  String? _fixedInterestError;
  String? _upfrontError;
  String? _interestApplicationError;

  static const Color lightColor = Color(0xFFE6F1F6);
  static const Color normalColor = Color(0xFF0070A8);
  static const Color darkColor = Color(0xFF00547E);

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _selectedBorrower = null;
    _loanAmountController.text = loan.loanAmount.toStringAsFixed(2);
    _givenDate = loan.givenDate;
    _givenDateController.text = _formatDate(loan.givenDate);
    _dueDate = loan.dueDate;
    _dueDateController.text = _formatDate(loan.dueDate);
    _notesController.text = loan.notes ?? '';

    _hasInterest = loan.hasInterest;
    _interestType = loan.interestType;
    if (_interestType == 'flat') {
      _interestRateController.text = (loan.interestRate ?? 0).toStringAsFixed(2);
      final interval = loan.interestIntervalDays;
      final unit = loan.interestIntervalUnit;
      if (interval == null || interval <= 0) {
        _interestApplication = 'one-time';
      } else if (unit == 'months' && interval == 1) {
        _interestApplication = 'monthly';
      } else if (unit == 'months' && interval == 3) {
        _interestApplication = 'quarterly';
      } else if (unit == 'months' && interval == 12) {
        _interestApplication = 'yearly';
      } else {
        _interestApplication = 'custom';
        _intervalController.text = interval.toString();
      }
    } else {
      _fixedInterestController.text = (loan.fixedInterestAmount ?? 0).toStringAsFixed(2);
      _interestApplication = 'one-time';
    }

    _collectUpfront = loan.collectUpfront;
    _totalInterest = loan.totalInterest;
    _payoutAmount = loan.payoutAmount;
    _totalPayable = loan.totalPayable;

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveBorrower());
  }

  Future<void> _resolveBorrower() async {
    final borrowers = context.read<BorrowerService>().borrowers;
    final match = borrowers.firstWhere(
      (b) => b.borrowerId == widget.loan.borrowerId,
      orElse: () => borrowers.isNotEmpty ? borrowers.first : Borrower(
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
    setState(() {
      _selectedBorrower = match;
    });
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _givenDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _interestRateController.dispose();
    _intervalController.dispose();
    _fixedInterestController.dispose();
    super.dispose();
  }

  int get _durationDays {
    if (_givenDate == null || _dueDate == null) return 0;
    final duration = _dueDate!.difference(_givenDate!).inDays;
    return duration > 0 ? duration : 0;
  }

  double _parseDouble(String value) => double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  int _parseInt(String value) => int.tryParse(value.replaceAll(',', '')) ?? 0;

  int _calculateMonthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  void _recalculate() {
    final loanAmount = _parseDouble(_loanAmountController.text);
    double totalInterest = 0.0;
    double payout = loanAmount;
    double totalPayable = loanAmount;

    if (_hasInterest) {
      if (_interestType == 'flat') {
        final rate = _parseDouble(_interestRateController.text);
        if (_interestApplication == 'one-time') {
          totalInterest = loanAmount * (rate / 100);
        } else {
          int intervalValue;
          String intervalUnit;
          switch (_interestApplication) {
            case 'monthly':
              intervalValue = 1;
              intervalUnit = 'months';
              break;
            case 'quarterly':
              intervalValue = 3;
              intervalUnit = 'months';
              break;
            case 'yearly':
              intervalValue = 12;
              intervalUnit = 'months';
              break;
            case 'custom':
              intervalValue = _parseInt(_intervalController.text);
              intervalUnit = 'days';
              break;
            default:
              intervalValue = 1;
              intervalUnit = 'months';
          }
          if (intervalValue > 0) {
            int numberOfIntervals;
            if (intervalUnit == 'months') {
              final monthsBetween = ((_dueDate!.year - _givenDate!.year) * 12 + (_dueDate!.month - _givenDate!.month)).clamp(0, double.infinity).toInt();
              numberOfIntervals = (monthsBetween / intervalValue).floor();
            } else {
              numberOfIntervals = _durationDays > 0 ? (_durationDays / intervalValue).floor() : 0;
            }
            totalInterest = loanAmount * (rate / 100) * numberOfIntervals;
          }
        }
      } else {
        totalInterest = _parseDouble(_fixedInterestController.text);
      }
      payout = (_collectUpfront) ? (loanAmount - totalInterest) : loanAmount;
      totalPayable = loanAmount + totalInterest;
    } else {
      // If no interest, clear all interest fields and values
      _interestRateController.text = '';
      _intervalController.text = '';
      _fixedInterestController.text = '';
      _interestType = 'flat';
      _interestApplication = 'one-time';
      totalInterest = 0.0;
      payout = loanAmount;
      totalPayable = loanAmount;
    }

    setState(() {
      _totalInterest = totalInterest;
      _payoutAmount = payout;
      _totalPayable = totalPayable;
      _interestApplicationError = _validateInterestApplication();
      if (_collectUpfront && _hasInterest && totalInterest > loanAmount) {
        _upfrontError = 'Interest cannot exceed loan amount for upfront deduction';
      } else {
        _upfrontError = null;
      }
    });
  }

  Future<void> _pickDate({required bool isGivenDate}) async {
    final initial = isGivenDate ? (_givenDate ?? DateTime.now()) : (_dueDate ?? DateTime.now().add(const Duration(days: 30)));
    final selected = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (!mounted || selected == null) return;

    setState(() {
      if (isGivenDate) {
        _givenDate = selected;
        _givenDateController.text = _formatDate(selected);
        _givenDateError = _validateGivenDate(_givenDateController.text);
      } else {
        _dueDate = selected;
        _dueDateController.text = _formatDate(selected);
        _dueDateError = _validateDueDate(_dueDateController.text);
      }
      _interestApplicationError = _validateInterestApplication();
    });

    _recalculate();
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String? _validateLoanAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Loan amount is required';
    final v = _parseDouble(value);
    if (v <= 0) return 'Loan amount must be greater than 0';
    return null;
  }

  String? _validateGivenDate(String? value) => (value == null || value.isEmpty) ? 'Given date is required' : null;

  String? _validateDueDate(String? value) {
    if (value == null || value.isEmpty) return 'Due date is required';
    if (_givenDate != null && _dueDate != null && !_dueDate!.isAfter(_givenDate!)) {
      return 'Due date must be after given date';
    }
    return null;
  }

  String? _validateInterestRate(String? value) {
    if (!_hasInterest || _interestType != 'flat') return null;
    if (value == null || value.trim().isEmpty) return 'Interest rate is required';
    final v = _parseDouble(value);
    if (v <= 0) return 'Interest rate must be > 0';
    if (v > 100) return 'Interest rate seems unreasonable';
    return null;
  }

  String? _validateInterestApplication() {
    if (!_hasInterest || _interestType != 'flat') return null;
    if (_givenDate == null || _dueDate == null) return null;

    final monthsBetween = _calculateMonthsBetween(_givenDate!, _dueDate!);

    switch (_interestApplication) {
      case 'monthly':
        if (monthsBetween < 1) {
          return 'Loan duration must be at least 1 month for monthly interest.';
        }
        break;
      case 'quarterly':
        if (monthsBetween < 3) {
          return 'Loan duration must be at least 3 months for quarterly interest.';
        }
        break;
      case 'yearly':
        if (monthsBetween < 12) {
          return 'Loan duration must be at least 1 year for yearly interest.';
        }
        break;
      default:
        break;
    }

    return null;
  }

  String? _validateInterval(String? value) {
    if (!_hasInterest || _interestType != 'flat') return null;
    if (value == null || value.trim().isEmpty) return 'Interval is required';
    final v = _parseInt(value);
    if (v <= 0) return 'Interval must be > 0';
    if (_durationDays > 0 && v > _durationDays) {
      return 'Interval cannot exceed total duration ($_durationDays days)';
    }
    return null;
  }

  String? _validateFixedInterest(String? value) {
    if (!_hasInterest || _interestType != 'fixed') return null;
    if (value == null || value.trim().isEmpty) return 'Interest amount is required';
    final v = _parseDouble(value);
    if (v < 0) return 'Interest amount must be at least 0';
    final loanAmount = _parseDouble(_loanAmountController.text);
    if (loanAmount > 0 && v > loanAmount) return 'Interest amount must not exceed loan amount';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _loanAmountError = _validateLoanAmount(_loanAmountController.text);
      _givenDateError = _validateGivenDate(_givenDateController.text);
      _dueDateError = _validateDueDate(_dueDateController.text);
      if (_hasInterest && _interestType == 'flat') {
        _interestRateError = _validateInterestRate(_interestRateController.text);
        _interestApplicationError = _validateInterestApplication();
        _intervalError = _interestApplication == 'custom' ? _validateInterval(_intervalController.text) : null;
      }
      if (_hasInterest && _interestType == 'fixed') {
        _fixedInterestError = _validateFixedInterest(_fixedInterestController.text);
      }
    });

    if (_loanAmountError != null || _givenDateError != null || _dueDateError != null || _interestRateError != null || _fixedInterestError != null || (_interestApplication == 'custom' && _intervalError != null) || _interestApplicationError != null) return;

    if (_selectedBorrower == null) {
      showInfoMessage(context, 'Borrower must be selected');
      return;
    }

    final loanAmount = _parseDouble(_loanAmountController.text);
    if (_collectUpfront && _totalInterest > loanAmount) {
      showErrorMessage(context, 'Interest cannot exceed loan amount for upfront deduction');
      return;
    }

    final loanService = context.read<LoanService>();
    int? interestIntervalDays;
    String? interestIntervalUnit;
    if (_interestType == 'flat') {
      switch (_interestApplication) {
        case 'monthly':
          interestIntervalDays = 1;
          interestIntervalUnit = 'months';
          break;
        case 'quarterly':
          interestIntervalDays = 3;
          interestIntervalUnit = 'months';
          break;
        case 'yearly':
          interestIntervalDays = 12;
          interestIntervalUnit = 'months';
          break;
        case 'custom':
          interestIntervalDays = _parseInt(_intervalController.text);
          interestIntervalUnit = 'days';
          break;
        case 'one-time':
        default:
          interestIntervalDays = null;
          interestIntervalUnit = null;
      }
    }

    final updatedLoan = widget.loan.copyWith(
      borrowerId: _selectedBorrower!.borrowerId,
      loanAmount: loanAmount,
      payoutAmount: _payoutAmount,
      givenDate: _givenDate,
      dueDate: _dueDate,
      hasInterest: _hasInterest,
      interestType: _interestType,
      interestRate: _interestType == 'flat' ? _parseDouble(_interestRateController.text) : null,
      interestIntervalDays: interestIntervalDays,
      interestIntervalUnit: interestIntervalUnit,
      fixedInterestAmount: _interestType == 'fixed' ? _parseDouble(_fixedInterestController.text) : null,
      collectUpfront: _collectUpfront,
      totalInterest: _totalInterest,
      totalPayable: _totalPayable,
      notes: _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      await loanService.updateLoan(updatedLoan);
      if (!mounted) return;
      Navigator.of(context).pop(updatedLoan);
    } catch (e) {
      if (mounted) {
        showErrorMessage(context, 'Failed to update loan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();
    final borrowers = borrowerService.borrowers;

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
            title: const Text('Edit Loan', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: normalColor),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
            actions: [
              IconButton(icon: const Icon(Icons.save, color: normalColor), onPressed: _submit),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Borrower'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.white,
                    ),
                    child: DropdownButtonFormField<Borrower>(
                      value: _selectedBorrower,
                      hint: const Text('Select Borrower'),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        // labelText: 'Borrower',
                        labelStyle: const TextStyle(color: Color(0xFF0070A8), fontSize: 14),
                        hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF0070A8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      items: borrowers
                          .map((b) => DropdownMenuItem(value: b, child: Text('${b.firstName} ${b.lastName}')))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedBorrower = value),
                      validator: (value) => value == null ? 'Borrower must be selected' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Loan Details'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _loanAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Loan Amount',
                          labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF0070A8)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _loanAmountError,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _loanAmountError = _validateLoanAmount(value);
                          });
                          _recalculate();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _datePickerCard(icon: Icons.calendar_today, controller: _givenDateController, label: 'Give On', isGivenDate: true, errorText: _givenDateError)),
                    const SizedBox(width: 8),
                    Expanded(child: _datePickerCard(icon: Icons.calendar_month, controller: _dueDateController, label: 'Due Date', isGivenDate: false, errorText: _dueDateError)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildInfoCard(icon: Icons.payments, label: 'Payout Amount', value: '₱ ${_payoutAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 15),
                _buildInfoCard(icon: Icons.account_balance_wallet, label: 'Total Payable', value: '₱ ${_totalPayable.toStringAsFixed(2)}'),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                      prefixIcon: const Icon(Icons.sticky_note_2, color: Color(0xFF0070A8)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Interest Details'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Interest on this loan'),
                      Switch(
                        value: _hasInterest,
                        activeThumbColor: normalColor,
                        onChanged: (value) {
                          setState(() {
                            _hasInterest = value;
                          });
                          _recalculate();
                        },
                      ),
                    ],
                  ),
                ),
                if (_hasInterest) ...[
                  const SizedBox(height: 10),
                  Row(children: [ _interestOptionButton('Flat Rate', 'flat'), const SizedBox(width: 8), _interestOptionButton('Fixed Amount', 'fixed') ]),
                  const SizedBox(height: 15),
                  if (_interestType == 'flat') ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _interestRateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Interest (%)',
                              labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                              prefixIcon: const Icon(Icons.percent, color: Color(0xFF0070A8)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              errorText: _interestRateError,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _interestRateError = _validateInterestRate(value);
                              });
                              _recalculate();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.white,
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _interestApplication,
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Applied Every',
                                labelStyle: const TextStyle(color: Color(0xFF0070A8), fontSize: 14),
                                hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                                prefixIcon: const Icon(Icons.schedule, color: Color(0xFF0070A8)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'one-time', child: Text('One-time')),
                                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly (3 months)')),
                                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                                DropdownMenuItem(value: 'custom', child: Text('Custom (days)')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _interestApplication = value;
                                    _interestApplicationError = _validateInterestApplication();
                                    _recalculate();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        if (_interestApplicationError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              _interestApplicationError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (_interestApplication == 'custom') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _intervalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Applied Every (days)',
                                labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                                prefixIcon: const Icon(Icons.calendar_view_day, color: Color(0xFF0070A8)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                errorText: _intervalError,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _intervalError = _validateInterval(value);
                                });
                                _recalculate();
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text('1 = daily, 7 = weekly, 30 = monthly, 90 = 3months, 365 = yearly', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Collect full interest upfront'), Switch(value: _collectUpfront, activeThumbColor: normalColor, onChanged: (value) { setState(() { _collectUpfront = value; _recalculate(); }); }), ])),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _fixedInterestController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Interest Amount',
                              labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                              prefixIcon: const Icon(Icons.request_quote, color: Color(0xFF0070A8)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              errorText: _fixedInterestError,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _fixedInterestError = _validateFixedInterest(value);
                              });
                              _recalculate();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Collect full interest upfront'), Switch(value: _collectUpfront, activeThumbColor: normalColor, onChanged: (value) { setState(() { _collectUpfront = value; _recalculate(); }); }), ])),
                  ],
                  if (_upfrontError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_upfrontError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  const SizedBox(height: 15),
                  _buildInfoCard(icon: Icons.auto_graph, label: 'Total Interest', value: '₱ ${_totalInterest.toStringAsFixed(2)}'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _interestOptionButton(String label, String type) {
    final selected = _interestType == type;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: selected ? normalColor : Colors.white, foregroundColor: selected ? Colors.white : normalColor, elevation: selected ? 2 : 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: selected ? darkColor : const Color.fromRGBO(0, 112, 168, 0.7))),
        onPressed: () {
          setState(() {
            _interestType = type;
            if (type == 'fixed') {
              _interestRateController.text = '';
              _intervalController.text = '';
            } else {
              _fixedInterestController.text = '';
            }
            _recalculate();
          });
        },
        child: Text(label),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _datePickerCard({required IconData icon, required TextEditingController controller, required String label, required bool isGivenDate, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputCard(icon: icon, child: InkWell(onTap: () => _pickDate(isGivenDate: isGivenDate), child: IgnorePointer(child: TextFormField(controller: controller, style: const TextStyle(color: Colors.black), decoration: InputDecoration(labelText: label, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),),),),),
        if (errorText != null)
          Padding(padding: const EdgeInsets.only(top: 8, left: 4), child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value, String? subValue}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 18, color: normalColor), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)), if (subValue != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subValue, style: const TextStyle(fontSize: 11, color: Colors.black45, fontStyle: FontStyle.italic))),],),),],),
    );
  }

  Widget _buildInputCardWithError({required IconData icon, required Widget child, required String? error, Color backgroundColor = Colors.white, double minHeight = 60, bool isFlexible = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildInputCard(icon: icon, child: child, backgroundColor: backgroundColor, minHeight: minHeight, isFlexible: isFlexible),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 8, left: 4), child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildInputCard({required IconData icon, required Widget child, Color backgroundColor = Colors.white, double minHeight = 60, bool isFlexible = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      constraints: isFlexible ? const BoxConstraints() : BoxConstraints(minHeight: minHeight),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, size: 20, color: normalColor),
        const SizedBox(width: 12),
        Expanded(child: child)
      ]),
    );
  }
}
