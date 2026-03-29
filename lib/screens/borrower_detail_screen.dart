import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../services/loan_service.dart';
import '../services/user_service.dart';
import 'edit_borrower_screen.dart';
import 'loan_view_screen.dart';
import '../utils/message_helpers.dart';

class BorrowerDetailScreen extends StatefulWidget {
  final Borrower borrower;

  const BorrowerDetailScreen({Key? key, required this.borrower}) : super(key: key);

  @override
  State<BorrowerDetailScreen> createState() => _BorrowerDetailScreenState();
}

class _BorrowerDetailScreenState extends State<BorrowerDetailScreen> {
  late Borrower _borrower;

  @override
  void initState() {
    super.initState();
    _borrower = widget.borrower;
  }

  Future<void> _openEditScreen() async {
    final updatedBorrower = await Navigator.of(context).push<Borrower>(
      MaterialPageRoute(
        builder: (_) => EditBorrowerScreen(borrower: _borrower),
      ),
    );

    if (!mounted || updatedBorrower == null) return;
    setState(() {
      _borrower = updatedBorrower;
    });
    showSuccessMessage(context, 'Borrower updated successfully');
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0070A8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanTile(Loan loan) {
    final isSettled = loan.status == 'settled';
    final paidAmount = loan.loanAmount - loan.remainingBalance;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LoanViewScreen(loan: loan)),
        );
        if (!mounted) return;
        final userId = context.read<UserService>().currentUser?.userId;
        if (userId != null) {
          await context.read<LoanService>().loadAllLoans(userId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan #${loan.loanId ?? '-'}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                Text(
                  isSettled ? 'Settled' : 'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSettled ? Colors.green[700] : const Color(0xFF0070A8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Loan Amount: ₱ ${loan.loanAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            Text(
              isSettled
                  ? 'Paid Amount: ₱ ${paidAmount.toStringAsFixed(2)}'
                  : 'Balance: ₱ ${loan.remainingBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            Text(
              'Due Date: ${_formatDate(loan.dueDate)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanService = context.watch<LoanService>();
    final borrowerLoans = loanService.loans
        .where((loan) => loan.borrowerId == _borrower.borrowerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
            title: const Text('Borrower Details', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Color(0xFF0070A8)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF0070A8)),
                onPressed: _openEditScreen,
                tooltip: 'Edit Borrower',
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF0070A8),
                      child: Text(
                        _borrower.firstName.isNotEmpty ? _borrower.firstName[0].toUpperCase() : 'B',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_borrower.firstName} ${_borrower.lastName}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${_borrower.status[0].toUpperCase()}${_borrower.status.substring(1)}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoTile(icon: Icons.phone, label: 'Contact Number', value: _borrower.contactNumber),
              _buildInfoTile(icon: Icons.location_on, label: 'Address', value: _borrower.address),
              _buildInfoTile(icon: Icons.phone_forwarded, label: 'Reference Contact', value: _borrower.referenceContact),
              _buildInfoTile(icon: Icons.calendar_today, label: 'Created At', value: _formatDate(_borrower.createdAt)),
              _buildInfoTile(icon: Icons.update, label: 'Updated At', value: _formatDate(_borrower.updatedAt)),
              const SizedBox(height: 8),
              const Text(
                'Loans',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00273B),
                ),
              ),
              const SizedBox(height: 10),
              borrowerLoans.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Text(
                        'This borrower has no loans yet.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    )
                  : Column(
                      children: borrowerLoans.map(_buildLoanTile).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
