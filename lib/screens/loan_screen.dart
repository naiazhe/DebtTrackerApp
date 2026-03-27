import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_widget.dart';
import 'add_loan_screen.dart';
import 'loan_view_screen.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({Key? key}) : super(key: key);

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  int _selectedTab = 0; // 0 = Active, 1 = Settled
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resetFilters();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchText = '';
      _selectedTab = 0; // Default to Active tab
    });
  }

  Future<void> _loadData() async {
    final userService = context.read<UserService>();
    final borrowerService = context.read<BorrowerService>();
    final loanService = context.read<LoanService>();
    final userId = userService.currentUser?.userId;
    if (userId != null) {
      await borrowerService.loadBorrowers(userId);
    }
    await loanService.loadAllLoans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();
    final loanService = context.watch<LoanService>();
    final borrowers = {for (var b in borrowerService.borrowers) b.borrowerId: b};
    final loans = loanService.loans;

    if (borrowerService.isLoading || loanService.isLoading) {
      return const LoadingWidget(message: 'Loading loans...');
    }

    // Filter by status
    final filteredLoans = loans.where((loan) {
      final isActive = loan.status == 'active';
      final isSettled = loan.status == 'settled';
      if (_selectedTab == 0 && !isActive) return false;
      if (_selectedTab == 1 && !isSettled) return false;
      if (_searchText.isNotEmpty) {
        final borrower = borrowers[loan.borrowerId];
        final name = borrower != null ? ('${borrower.firstName} ${borrower.lastName}').toLowerCase() : '';
        return name.contains(_searchText.toLowerCase());
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        title: const Text('Loans', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0070A8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0070A8)),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddLoanScreen()),
              );
              await _loadData(); // Reload data after adding a loan
              setState(() {}); // Refresh after add
            },
            tooltip: 'Add Loan',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented control
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab('Active', 0),
                    _buildTab('Settled', 1),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Color(0xFF0070A8)),
                    hintText: 'Search Borrower',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Loan list
              Expanded(
                child: filteredLoans.isEmpty
                    ? const Center(child: Text('No loans found.'))
                    : ListView.separated(
                        itemCount: filteredLoans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final loan = filteredLoans[index];
                          final borrower = borrowers[loan.borrowerId];
                          return _buildLoanCard(loan, borrower);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
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
                color: selected ? const Color(0xFF0070A8) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0070A8) : Colors.black54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, Borrower? borrower) {
    final name = borrower != null ? '${borrower.firstName} ${borrower.lastName}' : 'Unknown';
    final initial = borrower != null && borrower.firstName.isNotEmpty ? borrower.firstName[0].toUpperCase() : 'A';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LoanViewScreen(loan: loan),
          ),
        );
        if (!mounted) return;
        await _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Section
                CircleAvatar(
                  backgroundColor: const Color(0xFF00273B),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Borrower Name Section
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Loan and Balance Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Loan: ₱ ${loan.loanAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      'Balance: ₱ ${loan.remainingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Loan Terms Section
            Text(
              _buildInterestDetails(loan),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInterestDetails(Loan loan) {
    if (!loan.hasInterest) {
      return 'Interest: None';
    }

    if (loan.interestType == 'flat') {
      final rate = loan.interestRate ?? 0;
      final interval = loan.interestIntervalDays;
      final unit = loan.interestIntervalUnit;
      String intervalText = '';
      if (interval == null || interval <= 0) {
        intervalText = 'one-time';
      } else if (unit == 'months' && interval == 1) {
        intervalText = 'monthly';
      } else if (unit == 'months' && interval == 3) {
        intervalText = 'quarterly';
      } else if (unit == 'months' && interval == 12) {
        intervalText = 'yearly';
      } else if (unit == 'days') {
        intervalText = 'every $interval days';
      } else {
        intervalText = 'custom';
      }
      return 'Interest: ${rate.toStringAsFixed(2)}% | Applied $intervalText';
    } else {
      final fixed = loan.fixedInterestAmount ?? 0;
      return 'Interest: ₱${fixed.toStringAsFixed(2)}';
    }
  }
}
