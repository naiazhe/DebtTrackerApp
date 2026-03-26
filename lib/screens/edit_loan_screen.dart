import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';

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
      final interval = loan.interestInterval;
      if (interval == null) {
        _interestApplication = 'one-time';
      } else if (interval == 30) {
        _interestApplication = 'monthly';
      } else if (interval == 90) {
        _interestApplication = 'quarterly';
      } else if (interval == 365) {
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
          int intervalDays;
          switch (_interestApplication) {
            case 'monthly':
              intervalDays = 30;
              break;
            case 'quarterly':
              intervalDays = 90;
              break;
            case 'yearly':
              intervalDays = 365;
              break;
            case 'custom':
              intervalDays = _parseInt(_intervalController.text);
              break;
            default:
              intervalDays = 30;
          }
          if (intervalDays > 0 && _durationDays > 0) {
            final numberOfIntervals = _durationDays / intervalDays;
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
    if (selected == null) return;

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
      _recalculate();
    });
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
        _intervalError = _interestApplication == 'custom' ? _validateInterval(_intervalController.text) : null;
      }
      if (_hasInterest && _interestType == 'fixed') {
        _fixedInterestError = _validateFixedInterest(_fixedInterestController.text);
      }
    });

    if (_loanAmountError != null || _givenDateError != null || _dueDateError != null || _interestRateError != null || _fixedInterestError != null || (_interestApplication == 'custom' && _intervalError != null)) return;

    if (_selectedBorrower == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrower must be selected')));
      return;
    }

    final loanAmount = _parseDouble(_loanAmountController.text);
    if (_collectUpfront && _totalInterest > loanAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interest cannot exceed loan amount for upfront deduction')));
      return;
    }

    final loanService = context.read<LoanService>();
    final updatedLoan = widget.loan.copyWith(
      borrowerId: _selectedBorrower!.borrowerId,
      loanAmount: loanAmount,
      payoutAmount: _payoutAmount,
      givenDate: _givenDate,
      dueDate: _dueDate,
      hasInterest: _hasInterest,
      interestType: _interestType,
      interestRate: _interestType == 'flat' ? _parseDouble(_interestRateController.text) : null,
      interestInterval: _interestType == 'flat' && _interestApplication != 'one-time' ? _parseInt(_intervalController.text) : null,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update loan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();
    final borrowers = borrowerService.borrowers;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        title: const Text('Edit Loan', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: normalColor),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: normalColor), onPressed: _submit),
        ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonFormField<Borrower>(
                    value: _selectedBorrower,
                    hint: const Text('Select Borrower'),
                    decoration: const InputDecoration(border: InputBorder.none),
                    items: borrowers
                        .map((b) => DropdownMenuItem(value: b, child: Text('${b.firstName} ${b.lastName}')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBorrower = value),
                    validator: (value) => value == null ? 'Borrower must be selected' : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Loan Details'),
                _buildInputCardWithError(
                  icon: Icons.attach_money,
                  error: _loanAmountError,
                  child: TextFormField(
                    controller: _loanAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Loan Amount', floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10), errorText: null),
                    onChanged: (value) {
                      setState(() {
                        _loanAmountError = _validateLoanAmount(value);
                      });
                      _recalculate();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _datePickerCard(icon: Icons.calendar_today, controller: _givenDateController, label: 'Give On', isGivenDate: true, errorText: _givenDateError)),
                    const SizedBox(width: 8),
                    Expanded(child: _datePickerCard(icon: Icons.calendar_month, controller: _dueDateController, label: 'Due Date', isGivenDate: false, errorText: _dueDateError)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoCard(icon: Icons.payments, label: 'Payout Amount', value: '₱ ${_payoutAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildInfoCard(icon: Icons.account_balance_wallet, label: 'Total Payable', value: '₱ ${_totalPayable.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildInputCard(icon: Icons.sticky_note_2, isFlexible: true, child: TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none), maxLines: 3)),
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
                  const SizedBox(height: 12),
                  if (_interestType == 'flat') ...[
                    _buildInputCardWithError(icon: Icons.percent, error: _interestRateError, child: TextFormField(controller: _interestRateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], decoration: const InputDecoration(labelText: 'Interest (%)', floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10), errorText: null), onChanged: (value) { setState(() { _interestRateError = _validateInterestRate(value); }); _recalculate(); },)),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: DropdownButtonFormField<String>(value: _interestApplication, decoration: const InputDecoration(labelText: 'Applied Every', border: InputBorder.none), items: const [DropdownMenuItem(value: 'one-time', child: Text('One-time')), DropdownMenuItem(value: 'monthly', child: Text('Monthly')), DropdownMenuItem(value: 'quarterly', child: Text('Quarterly (3 months)')), DropdownMenuItem(value: 'yearly', child: Text('Yearly')), DropdownMenuItem(value: 'custom', child: Text('Custom (days)'))], onChanged: (value) { if (value != null) { setState(() { _interestApplication = value; _recalculate(); }); } },)),
                    const SizedBox(height: 8),
                    if (_interestApplication == 'custom') ...[
                      _buildInputCardWithError(icon: Icons.calendar_view_day, error: _intervalError, child: TextFormField(controller: _intervalController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Applied Every (days)', floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10), errorText: null), onChanged: (value) { setState(() { _intervalError = _validateInterval(value); }); _recalculate(); },)),
                      const SizedBox(height: 8),
                      const Text('1 = daily, 7 = weekly, 30 = monthly, 90 = 3months, 365 = yearly', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Collect full interest upfront'), Switch(value: _collectUpfront, activeThumbColor: normalColor, onChanged: (value) { setState(() { _collectUpfront = value; _recalculate(); }); }), ])),
                  ] else ...[
                    _buildInputCardWithError(icon: Icons.request_quote, error: _fixedInterestError, child: TextFormField(controller: _fixedInterestController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], decoration: const InputDecoration(labelText: 'Interest Amount', floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10), errorText: null), onChanged: (value) { setState(() { _fixedInterestError = _validateFixedInterest(value); }); _recalculate(); })),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Collect full interest upfront'), Switch(value: _collectUpfront, activeThumbColor: normalColor, onChanged: (value) { setState(() { _collectUpfront = value; _recalculate(); }); }), ])),
                  ],
                  if (_upfrontError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_upfrontError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  const SizedBox(height: 12),
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
        _buildInputCard(icon: icon, child: InkWell(onTap: () => _pickDate(isGivenDate: isGivenDate), child: IgnorePointer(child: TextFormField(controller: controller, decoration: InputDecoration(labelText: label, floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),),),),),
        if (errorText != null)
          Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500))),
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
      if (error != null) Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildInputCard({required IconData icon, required Widget child, Color backgroundColor = Colors.white, double minHeight = 60, bool isFlexible = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))]),
      constraints: isFlexible ? const BoxConstraints() : BoxConstraints(minHeight: minHeight),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Icon(icon, size: 18, color: normalColor), const SizedBox(width: 8), Expanded(child: child)]),
    );
  }
}
