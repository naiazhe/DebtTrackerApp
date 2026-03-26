import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      }
      await loanService.loadAllLoans();
      await transactionService.loadTransactions();
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

    final totalBorrowers = borrowerService.borrowers.length;
    final totalLoans = loanService.loans.length;
    final totalTransactions = transactionService.transactions.length;
    final totalOutstanding = loanService.loans.fold<double>(0, (prev, loan) => prev + loan.remainingBalance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, ${userService.currentUser?.name ?? 'User'}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text('Dashboard Overview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DashboardCard(title: 'Borrowers', value: totalBorrowers.toString(), color: Colors.blue),
              _DashboardCard(title: 'Loans', value: totalLoans.toString(), color: Colors.teal),
              _DashboardCard(title: 'Transactions', value: totalTransactions.toString(), color: Colors.deepPurple),
              _DashboardCard(title: 'Amount Due', value: '\$${totalOutstanding.toStringAsFixed(2)}', color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
          ...transactionService.transactions.take(5).map((tx) => ListTile(
                title: Text('${tx.type.toUpperCase()} - \$${tx.amount.toStringAsFixed(2)}'),
                subtitle: Text('${tx.transactionDate.toLocal()}'),
              )),
          if (transactionService.transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No transactions yet.'),
            ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _DashboardCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 22,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
