import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transaction_service.dart';
import '../widgets/loading_widget.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionService>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = context.watch<TransactionService>();
    if (transactionService.isLoading) {
      return const LoadingWidget(message: 'Loading transactions...');
    }

    if (transactionService.transactions.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }

    return ListView.builder(
      itemCount: transactionService.transactions.length,
      itemBuilder: (context, index) {
        final tx = transactionService.transactions[index];
        return ListTile(
          title: Text('${tx.type.toUpperCase()} - \$${tx.amount.toStringAsFixed(2)}'),
          subtitle: Text('Borrower ${tx.borrowerId}, Loan ${tx.loanId ?? '-'}'),
          trailing: Text(tx.transactionDate.toLocal().toString().split(' ').first),
        );
      },
    );
  }
}
