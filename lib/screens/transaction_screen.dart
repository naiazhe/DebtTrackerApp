import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_record.dart';
import '../services/borrower_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  int _selectedFilter = 0; // 0=all, 1=loan, 2=payment
  DateTime? _lastRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userService = context.read<UserService>();
    final borrowerService = context.read<BorrowerService>();
    final transactionService = context.read<TransactionService>();

    final userId = userService.currentUser?.userId;
    if (userId != null) {
      await borrowerService.loadBorrowers(userId);
      await transactionService.loadTransactions(userId);
    }
    _lastRefreshAt = DateTime.now();
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour24 = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  List<TransactionRecord> _filterTransactions(List<TransactionRecord> all) {
    if (_selectedFilter == 1) {
      return all.where((tx) => tx.type == 'loan').toList();
    }
    if (_selectedFilter == 2) {
      return all.where((tx) => tx.type == 'payment').toList();
    }
    return all;
  }

  List<(DateTime, List<TransactionRecord>)> _groupByDate(List<TransactionRecord> transactions) {
    final grouped = <DateTime, List<TransactionRecord>>{};

    for (final tx in transactions) {
      final local = tx.transactionDate.toLocal();
      final dayKey = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(tx);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return days.map((day) {
      final entries = grouped[day]!..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return (day, entries);
    }).toList();
  }

  Widget _buildFilterTab(String label, int value) {
    final selected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF0070A8) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF0070A8) : Colors.black54,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionRecord tx, String borrowerName) {
    final isPayment = tx.type == 'payment';
    final amountPrefix = isPayment ? '+' : '-';
    final amountColor = isPayment ? Colors.green[700]! : Colors.black87;

    return Container(
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
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();
    final transactionService = context.watch<TransactionService>();

    final now = DateTime.now();
    if (_lastRefreshAt == null || now.difference(_lastRefreshAt!) > const Duration(seconds: 2)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || transactionService.isLoading) return;
        _loadData();
      });
    }

    final borrowerMap = {
      for (final b in borrowerService.borrowers)
        if (b.borrowerId != null) b.borrowerId!: '${b.firstName} ${b.lastName}'.trim(),
    };

    final filtered = _filterTransactions(transactionService.transactions);
    final grouped = _groupByDate(filtered);

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
            title: const Text('Transactions', style: TextStyle(color: Colors.black)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildFilterTab('All', 0),
                    _buildFilterTab('Borrowed', 1),
                    _buildFilterTab('Payments', 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactionService.isLoading && transactionService.transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : grouped.isEmpty
                      ? const Center(child: Text('No transactions yet.'))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: grouped.length,
                            itemBuilder: (context, index) {
                              final group = grouped[index];
                              final date = group.$1;
                              final records = group.$2;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                                    child: Text(
                                      _formatDateHeader(date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0070A8),
                                      ),
                                    ),
                                  ),
                                  ...records.map((tx) {
                                    final borrowerName = borrowerMap[tx.borrowerId] ?? 'Borrower ${tx.borrowerId}';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _buildTransactionCard(tx, borrowerName),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
