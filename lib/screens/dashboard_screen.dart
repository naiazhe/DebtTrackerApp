import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../models/transaction_record.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_widget.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _normalBlue = Color(0xFF0070A8);
  static const Color _pageLight = Color(0xFFF7FBFC);

  String _formatCurrency(double value) {
    return '₱${value.toStringAsFixed(2)}';
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour24 = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00273B),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0070A8)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveLoanCard({required String borrowerName, required Loan loan}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0070A8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borrowerName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(
                  'Due: ${loan.dueDate.year}-${loan.dueDate.month.toString().padLeft(2, '0')}-${loan.dueDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(loan.remainingBalance),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionRecord tx, String borrowerName) {
    final isPayment = tx.type == 'payment';
    final amountPrefix = isPayment ? '+' : '-';
    final amountColor = isPayment ? Colors.green[700]! : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0070A8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPayment ? Icons.north_east : Icons.south_west,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borrowerName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(tx.transactionDate),
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix₱${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userService = context.read<UserService>();
      final borrowerService = context.read<BorrowerService>();
      final loanService = context.read<LoanService>();
      final transactionService = context.read<TransactionService>();

      await userService.initialize();
      final userId = userService.currentUser?.userId;
      if (userId != null) {
        await borrowerService.loadBorrowers(userId);
        await loanService.loadAllLoans(userId);
        await transactionService.loadTransactions(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final borrowerService = context.watch<BorrowerService>();
    final loanService = context.watch<LoanService>();
    final transactionService = context.watch<TransactionService>();

    if (userService.isLoading || borrowerService.isLoading || loanService.isLoading || transactionService.isLoading) {
      return const LoadingWidget(message: 'Loading dashboard...');
    }

    final loans = loanService.loans;
    final transactions = transactionService.transactions;
    final borrowerMap = {
      for (final b in borrowerService.borrowers)
        if (b.borrowerId != null) b.borrowerId!: '${b.firstName} ${b.lastName}'.trim(),
    };

    final totalMoneyLent = loans.fold<double>(0, (prev, loan) => prev + loan.loanAmount);
    final totalInterestEarned = loans.fold<double>(0, (prev, loan) => prev + loan.totalInterest);
    final totalPaymentsCollected = loans.fold<double>(0, (prev, loan) => prev + loan.totalPaid);
    final pendingCollections = loans.fold<double>(0, (prev, loan) => prev + loan.remainingBalance);
    final totalCollectionTarget = totalPaymentsCollected + pendingCollections;
    final collectionProgress = totalCollectionTarget > 0 ? (totalPaymentsCollected / totalCollectionTarget).clamp(0.0, 1.0) : 0.0;

    final activeLoans = loans
        .where((loan) => loan.status == 'active' && loan.remainingBalance > 0)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final settledLoans = loans.where((loan) => loan.status == 'settled' || loan.remainingBalance <= 0).toList();

    final activePreview = activeLoans.take(3).toList();
    final recentTransactions = transactions.take(3).toList();

    return Scaffold(
      backgroundColor: _pageLight,
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
            title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Color(0xFF0070A8)),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            children: [
              Expanded(
                    child: _PrimaryMetricCard(
                      amount: _formatCurrency(totalMoneyLent),
                      label: 'Total Money Lent',
                    ),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryMetricCard(
                  amount: _formatCurrency(totalInterestEarned),
                  label: 'Total Interest Earned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loans Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF00273B)),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: collectionProgress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(_normalBlue),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paid',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(totalPaymentsCollected),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'To Be Collected',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(pendingCollections),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loans Statistic',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF00273B)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: _LoansStatCard(
                        amount: activeLoans.length.toString(),
                        label: 'Active Loans',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LoansStatCard(
                        amount: settledLoans.length.toString(),
                        label: 'Settled Loans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(
            title: 'Active Loans',
            onSeeAll: () {
              widget.onNavigateToTab?.call(2);
            },
          ),
          if (activePreview.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: const Text('No active loans.'),
            )
          else
            ...activePreview.map((loan) {
              final borrowerName = borrowerMap[loan.borrowerId] ?? 'Borrower ${loan.borrowerId}';
              return _buildActiveLoanCard(borrowerName: borrowerName, loan: loan);
            }),
          const SizedBox(height: 8),
          _buildSectionHeader(
            title: 'Recent Transactions',
            onSeeAll: () {
              widget.onNavigateToTab?.call(3);
            },
          ),
          if (recentTransactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: const Text('No transactions yet.'),
            ),
          ...recentTransactions.map((tx) {
            final borrowerName = borrowerMap[tx.borrowerId] ?? 'Borrower ${tx.borrowerId}';
            return _buildTransactionCard(tx, borrowerName);
          }),
          const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryMetricCard extends StatelessWidget {
  final String amount;
  final String label;

  const _PrimaryMetricCard({required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1F6),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            amount,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoansStatCard extends StatelessWidget {
  final String amount;
  final String label;

  const _LoansStatCard({required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F1F6), // lighter blue for secondary stats // For Loans Statistic card
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            amount,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
