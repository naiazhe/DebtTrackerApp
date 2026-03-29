import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/user_service.dart';import '../utils/message_helpers.dart';import 'loan_details_screen.dart';

class AddLoanScreen extends StatefulWidget {
  final Borrower? initialBorrower;

  const AddLoanScreen({Key? key, this.initialBorrower}) : super(key: key);

  @override
  State<AddLoanScreen> createState() => AddLoanScreenState();
}

class AddLoanScreenState extends State<AddLoanScreen> {
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
  String _interestApplication = 'one-time'; // 'one-time', 'monthly', 'quarterly', 'yearly', 'custom'
  String _interestType = 'flat';

  double _totalInterest = 0.0;
  double _payoutAmount = 0.0;
  double _totalPayable = 0.0;

  // Error state for input fields
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
  static const Color darkerColor = Color(0xFF00273B);

  @override
  void initState() {
    super.initState();
    _selectedBorrower = widget.initialBorrower;
    
    // Set given date to today
    final today = DateTime.now();
    _givenDate = today;
    _givenDateController.text = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Set due date to 30 days from today 
    final dueDate = today.add(const Duration(days: 30));
    _dueDate = dueDate;
    _dueDateController.text = '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    
    _recalculate();
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

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }

  int _parseInt(String value) {
    return int.tryParse(value.replaceAll(',', '')) ?? 0;
  }

  int _calculateMonthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  int _calculateNumberOfIntervals() {
    if (_givenDate == null || _dueDate == null) return 0;

    switch (_interestApplication) {
      case 'monthly':
        return ((_dueDate!.year - _givenDate!.year) * 12 + (_dueDate!.month - _givenDate!.month)).clamp(0, double.infinity).toInt();
      case 'quarterly':
        return (((_dueDate!.year - _givenDate!.year) * 12 + (_dueDate!.month - _givenDate!.month)) / 3).clamp(0, double.infinity).toInt();
      case 'yearly':
        return (_dueDate!.year - _givenDate!.year).clamp(0, double.infinity).toInt();
      case 'custom':
        final intervalDays = _parseInt(_intervalController.text);
        return intervalDays > 0 ? (_durationDays / intervalDays).floor() : 0;
      default:
        return 1; // One-time
    }
  }

  void _recalculate() {
    final loanAmount = _parseDouble(_loanAmountController.text);
    double totalInterest = 0.0;

    if (_hasInterest) {
      if (_interestType == 'flat') {
        final rate = _parseDouble(_interestRateController.text);
        final numberOfIntervals = _calculateNumberOfIntervals();
        totalInterest = loanAmount * (rate / 100) * numberOfIntervals;
      } else {
        totalInterest = _parseDouble(_fixedInterestController.text);
      }
    }

    final payout = (_collectUpfront && _hasInterest) ? (loanAmount - totalInterest) : loanAmount;
    final totalPayable = loanAmount + totalInterest;

    setState(() {
      _totalInterest = totalInterest;
      _payoutAmount = payout;
      _totalPayable = totalPayable;
      _interestApplicationError = _validateInterestApplication();
      if (_collectUpfront && _totalInterest > loanAmount) {
        _upfrontError = 'Interest cannot exceed loan amount for upfront deduction';
      } else {
        _upfrontError = null;
      }
    });
  }

  Future<void> _pickDate({required bool isGivenDate}) async {
    final initial = isGivenDate ? (_givenDate ?? DateTime.now()) : (_dueDate ?? DateTime.now().add(const Duration(days: 30)));
    final first = DateTime(2000);
    final last = DateTime(2100);

    final selected = await showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: last);
    if (!mounted || selected == null) return;

    setState(() {
      if (isGivenDate) {
        _givenDate = selected;
        _givenDateController.text = '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
        _givenDateError = _validateGivenDate(_givenDateController.text);
      } else {
        _dueDate = selected;
        _dueDateController.text = '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
        _dueDateError = _validateDueDate(_dueDateController.text);
      }
      _interestApplicationError = _validateInterestApplication();
    });

    _recalculate();
  }

  void _selectInterestType(String type) {
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
  }

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
    if (loanAmount > 0 && v > loanAmount) {
      return 'Interest amount must not exceed loan amount';
    }
    return null;
  }

  Future<void> _submit() async {
    // Validate all fields and update error state
    setState(() {
      _loanAmountError = _validateLoanAmount(_loanAmountController.text);
      _givenDateError = _validateGivenDate(_givenDateController.text);
      _dueDateError = _validateDueDate(_dueDateController.text);
      if (_hasInterest && _interestType == 'flat') {
        _interestRateError = _validateInterestRate(_interestRateController.text);
        _interestApplicationError = _validateInterestApplication();
        if (_interestApplication == 'custom') {
          _intervalError = _validateInterval(_intervalController.text);
        } else {
          _intervalError = null; // Clear error when not using custom
        }
      }
      if (_hasInterest && _interestType == 'fixed') {
        _fixedInterestError = _validateFixedInterest(_fixedInterestController.text);
      }
    });

    // Check if there are any errors
    if (_loanAmountError != null || _givenDateError != null || _dueDateError != null || _interestRateError != null || _fixedInterestError != null ||
        (_interestApplication == 'custom' && _intervalError != null) || _interestApplicationError != null) {
      return;
    }

    if (_selectedBorrower == null) {
      showInfoMessage(context, 'Borrower must be selected');
      return;
    }
    if (_collectUpfront && _totalInterest > _parseDouble(_loanAmountController.text)) {
      showErrorMessage(context, 'Interest cannot exceed loan amount for upfront deduction');
      return;
    }
    if (_givenDate == null || _dueDate == null) {
      // already validated but guard.
      return;
    }
    final userId = context.read<UserService>().currentUser?.userId;
    if (userId == null) {
      showErrorMessage(context, 'User not logged in');
      return;
    }

    final loanAmount = _parseDouble(_loanAmountController.text);
    final payoutAmount = _payoutAmount;
    final interestRate = _hasInterest && _interestType == 'flat' ? _parseDouble(_interestRateController.text) : null;
    int? interestInterval;
    String? interestIntervalUnit;
    if (_hasInterest && _interestType == 'flat') {
      switch (_interestApplication) {
        case 'monthly':
          interestInterval = 1;
          interestIntervalUnit = 'months';
          break;
        case 'quarterly':
          interestInterval = 3;
          interestIntervalUnit = 'months';
          break;
        case 'yearly':
          interestInterval = 12;
          interestIntervalUnit = 'months';
          break;
        case 'custom':
          interestInterval = _parseInt(_intervalController.text);
          interestIntervalUnit = 'days';
          break;
        case 'one-time':
        default:
          interestInterval = null;
          interestIntervalUnit = null;
      }
    }
    final fixedInterestAmount = _hasInterest && _interestType == 'fixed' ? _parseDouble(_fixedInterestController.text) : null;

    final loanService = context.read<LoanService>();

    try {
      final createdLoan = await loanService.createLoan(
        userId: userId,
        borrowerId: _selectedBorrower!.borrowerId!,
        loanAmount: loanAmount,
        payoutAmount: payoutAmount,
        givenDate: _givenDate!,
        dueDate: _dueDate!,
        hasInterest: _hasInterest,
        interestType: _hasInterest ? _interestType : 'flat',
        interestRate: interestRate,
        interestIntervalDays: interestInterval,
        interestIntervalUnit: interestIntervalUnit,
        fixedInterestAmount: fixedInterestAmount,
        collectUpfront: _collectUpfront,
        notes: _notesController.text.trim(),
      );

      await loanService.addLoanTransaction(userId: userId, borrowerId: _selectedBorrower!.borrowerId!, loanId: createdLoan.loanId!, amount: createdLoan.loanAmount);
      await loanService.loadAllLoans(userId);

      if (!mounted) return;
      // Navigate to Loan Details screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoanDetailsScreen(
            loan: createdLoan,
            showCreatedSuccess: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showErrorMessage(context, 'Failed to save loan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();

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
            title: const Text('Add Loan', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: normalColor),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            actions: [
              TextButton(
                onPressed: _submit,
                child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
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
                      initialValue: _selectedBorrower,
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
                      items: borrowerService.borrowers
                          .map((b) => DropdownMenuItem(value: b, child: Text('${b.firstName} ${b.lastName}')))
                          .toList(),
                      validator: (value) => value == null ? 'Borrower must be selected' : null,
                      onChanged: (value) {
                        setState(() {
                          _selectedBorrower = value;
                        });
                      },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _pickDate(isGivenDate: true),
                            child: AbsorbPointer(
                              child: Container(
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
                                  controller: _givenDateController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Give On',
                                    labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0070A8)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorText: _givenDateError,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_givenDateError != null)
                            const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _pickDate(isGivenDate: false),
                            child: AbsorbPointer(
                              child: Container(
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
                                  controller: _dueDateController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Due Date',
                                    labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                                    prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF0070A8)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorText: _dueDateError,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_dueDateError != null)
                            const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _buildInputCard(
                  icon: Icons.payments,
                  backgroundColor: const Color(0xFFF2F2F3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Payout Amount', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                      Text('₱ ${_payoutAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _buildInputCard(
                  icon: Icons.account_balance_wallet,
                  backgroundColor: const Color(0xFFF2F2F3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Payable', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                      Text('₱ ${_totalPayable.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
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
                            _recalculate();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_hasInterest) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _interestOptionButton('Flat Rate', 'flat'),
                      const SizedBox(width: 8),
                      _interestOptionButton('Fixed Amount', 'fixed'),
                    ],
                  ),
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
                        ],
                      ),
                      // const SizedBox(height: 8),
                      // const Text('1 = daily, 7 = weekly, 30 = monthly, 90 = 3months, 365 = yearly', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Collect full interest upfront'),
                          Switch(
                            value: _collectUpfront,
                            activeThumbColor: normalColor,
                            onChanged: (value) {
                              setState(() {
                                _collectUpfront = value;
                                _recalculate();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Collect full interest upfront'),
                          Switch(
                            value: _collectUpfront,
                            activeThumbColor: normalColor,
                            onChanged: (value) {
                              setState(() {
                                _collectUpfront = value;
                                _recalculate();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_upfrontError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_upfrontError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 15),
                  _buildInputCard(
                    icon: Icons.auto_graph,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total Interest', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                        Text('₱ ${_totalInterest.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? normalColor : Colors.white,
          foregroundColor: selected ? Colors.white : normalColor,
          elevation: selected ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: selected ? darkColor : const Color.fromRGBO(0, 112, 168, 0.7)),
        ),
        onPressed: () => _selectInterestType(type),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: normalColor),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildInputCardWithError({required IconData icon, required Widget child, required String? error, Color backgroundColor = Colors.white, double minHeight = 60, bool isFlexible = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputCard(
          icon: icon,
          child: child,
          backgroundColor: backgroundColor,
          minHeight: minHeight,
          isFlexible: isFlexible,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  String _getInterestIntervalDisplay(String interestApplication, int? interval) {
    switch (interestApplication) {
      case 'monthly':
        return '1 month';
      case 'quarterly':
        return '3 months';
      case 'yearly':
        return '1 year';
      case 'one-time':
        return 'One-Time';
      case 'custom':
        return interval != null && interval > 0 ? '$interval days' : 'Custom';
      default:
        return 'Unknown';
    }
  }
}
