import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_widget.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({Key? key}) : super(key: key);

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  Borrower? _selectedBorrower;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userService = context.read<UserService>();
      final borrowerService = context.read<BorrowerService>();
      final loanService = context.read<LoanService>();
      final userId = userService.currentUser?.userId;
      if (userId != null) {
        await borrowerService.loadBorrowers(userId);
      }
      await loanService.loadAllLoans();
    });
  }

  Future<void> _refreshLoans() async {
    final loanService = context.read<LoanService>();
    if (_selectedBorrower != null) {
      await loanService.loadLoans(_selectedBorrower!.borrowerId!);
    } else {
      await loanService.loadAllLoans();
    }
  }

  Future<void> _showLoanForm(BuildContext context) async {
    if (_selectedBorrower == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a borrower first.')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final loanAmountController = TextEditingController();
    final payoutAmountController = TextEditingController();
    final givenDateController = TextEditingController();
    final dueDateController = TextEditingController();
    final interestRateController = TextEditingController();
    final fixedInterestController = TextEditingController();

    bool hasInterest = false;
    String interestType = 'flat';

    DateTime? givenDate;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateInside) {
          return AlertDialog(
            title: const Text('Add Loan'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: loanAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Loan Amount'), validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Enter valid amount' : null),
                    TextFormField(controller: payoutAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Payout Amount'), validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Enter valid amount' : null),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: givenDateController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Given Date'),
                          onTap: () async {
                            final selected = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (selected != null) {
                              setStateInside(() {
                                givenDate = selected;
                                givenDateController.text = selected.toIso8601String().split('T').first;
                              });
                            }
                          },
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: dueDateController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Due Date'),
                          onTap: () async {
                            final selected = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (selected != null) {
                              setStateInside(() {
                                dueDate = selected;
                                dueDateController.text = selected.toIso8601String().split('T').first;
                              });
                            }
                          },
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Has Interest'),
                      value: hasInterest,
                      onChanged: (value) => setStateInside(() => hasInterest = value),
                    ),
                    if (hasInterest) ...[
                      DropdownButtonFormField<String>(
                        value: interestType,
                        items: const [DropdownMenuItem(value: 'flat', child: Text('Flat')), DropdownMenuItem(value: 'fixed', child: Text('Fixed'))],
                        onChanged: (v) => setStateInside(() => interestType = v ?? 'flat'),
                        decoration: const InputDecoration(labelText: 'Interest Type'),
                      ),
                      if (interestType == 'flat')
                        TextFormField(controller: interestRateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interest Rate (%)'))
                      else
                        TextFormField(controller: fixedInterestController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fixed Interest Amount')),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final userId = context.read<UserService>().currentUser?.userId;
                  if (userId == null) return;

                  final loanService = context.read<LoanService>();
                  final navigator = Navigator.of(ctx);

                  final double loanAmount = double.parse(loanAmountController.text);
                  final double payoutAmount = double.parse(payoutAmountController.text);
                  final double? interestRate = hasInterest && interestType == 'flat' ? double.tryParse(interestRateController.text) : null;
                  final double? fixedInterest = hasInterest && interestType == 'fixed' ? double.tryParse(fixedInterestController.text) : null;

                  if (dueDate == null || givenDate == null) return;
                  if (dueDate!.isBefore(givenDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Due date must be after given date')));
                    return;
                  }

                  final createdLoan = await loanService.createLoan(
                        borrowerId: _selectedBorrower!.borrowerId!,
                        loanAmount: loanAmount,
                        payoutAmount: payoutAmount,
                        givenDate: givenDate!,
                        dueDate: dueDate!,
                        hasInterest: hasInterest,
                        interestType: interestType,
                        interestRate: interestRate,
                        interestIntervalDays: hasInterest && interestType == 'flat' ? 30 : null,
                        fixedInterestAmount: fixedInterest,
                        collectUpfront: false,
                        notes: '',
                      );

                  await loanService.addLoanTransaction(userId: userId, borrowerId: _selectedBorrower!.borrowerId!, loanId: createdLoan.loanId!, amount: createdLoan.totalPayable);
                  await _refreshLoans();

                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();
    final loanService = context.watch<LoanService>();

    final loans = _selectedBorrower != null ? loanService.loans.where((loan) => loan.borrowerId == _selectedBorrower!.borrowerId).toList() : loanService.loans;

    if (borrowerService.isLoading || loanService.isLoading) {
      return const LoadingWidget(message: 'Loading loans...');
    }

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                DropdownButtonFormField<Borrower>(
                  initialValue: _selectedBorrower,
                  hint: const Text('Select Borrower'),
                  items: borrowerService.borrowers
                      .map((b) => DropdownMenuItem(value: b, child: Text('${b.firstName} ${b.lastName}')))
                      .toList(),
                  onChanged: (value) async {
                    setState(() {
                      _selectedBorrower = value;
                    });
                    if (value != null) {
                      final loanService = context.read<LoanService>();
                      await loanService.loadLoans(value.borrowerId!);
                    }
                  },
                ),
                Expanded(
                  child: loans.isEmpty
                      ? const Center(child: Text('No loans yet. Please add a loan.'))
                      : ListView.builder(
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            return Card(
                              child: ListTile(
                                title: Text('Loan: \$${loan.loanAmount.toStringAsFixed(2)}'),
                                subtitle: Text('Remaining: \$${loan.remainingBalance.toStringAsFixed(2)} | Status: ${loan.status}'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showLoanForm(context),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
