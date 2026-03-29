import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../services/borrower_service.dart';
import '../services/loan_service.dart';
import '../services/user_service.dart';
import '../screens/borrower_detail_screen.dart';
import '../screens/add_borrower_screen.dart';

class BorrowerScreen extends StatefulWidget {
  const BorrowerScreen({Key? key}) : super(key: key);

  @override
  State<BorrowerScreen> createState() => _BorrowerScreenState();
}

class _BorrowerScreenState extends State<BorrowerScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    final userService = context.read<UserService>();
    final borrowerService = context.read<BorrowerService>();
    final loanService = context.read<LoanService>();
    final userId = userService.currentUser?.userId;
    if (userId != null) {
      await borrowerService.loadBorrowers(userId);
      await loanService.loadAllLoans(userId);
    }
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
    final borrowers = List<Borrower>.from(borrowerService.borrowers)
      ..sort((a, b) => _fullName(a).toLowerCase().compareTo(_fullName(b).toLowerCase()));

    final filteredBorrowers = borrowers.where((borrower) {
      if (_searchText.trim().isEmpty) {
        return true;
      }
      return _fullName(borrower).toLowerCase().contains(_searchText.toLowerCase().trim());
    }).toList();

    final groupedBorrowers = _groupBorrowersByInitial(filteredBorrowers);

    final isLoading = borrowerService.isLoading || loanService.isLoading;

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
            title: const Text('Borrowers', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Color(0xFF0070A8)),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0070A8)),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddBorrowerScreen()),
                  );
                  if (mounted) {
                    await _loadData();
                  }
                },
                tooltip: 'Add Borrower',
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Container(
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: groupedBorrowers.isEmpty
                ? (isLoading ? const SizedBox.shrink() : const Center(child: Text('No borrowers found.')))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      itemCount: groupedBorrowers.length,
                      itemBuilder: (context, index) {
                        final entry = groupedBorrowers[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 0, right: 0),
                              child: Text(
                                entry.$1,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00273B),
                                ),
                              ),
                            ),
                            ...entry.$2.map((borrower) {
                              final borrowerLoans = loanService.loans.where((loan) => loan.borrowerId == borrower.borrowerId).toList();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildBorrowerCard(borrower, borrowerLoans),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fullName(Borrower borrower) {
    return '${borrower.firstName} ${borrower.lastName}'.trim();
  }

  List<(String, List<Borrower>)> _groupBorrowersByInitial(List<Borrower> borrowers) {
    final Map<String, List<Borrower>> groups = {};

    for (final borrower in borrowers) {
      final name = _fullName(borrower);
      final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      final header = RegExp(r'^[A-Z]$').hasMatch(firstChar) ? firstChar : '#';
      groups.putIfAbsent(header, () => []);
      groups[header]!.add(borrower);
    }

    final keys = groups.keys.toList()..sort();
    return keys.map((key) => (key, groups[key]!)).toList();
  }

  Widget _buildBorrowerCard(Borrower borrower, List<Loan> borrowerLoans) {
    final name = _fullName(borrower);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    final status = _loanStatus(borrowerLoans);
    final totalDebt = borrowerLoans.fold<double>(0, (sum, loan) => sum + loan.remainingBalance);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BorrowerDetailScreen(borrower: borrower),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0070A8),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Debt: ₱ ${totalDebt.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loan Status: $status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _loanStatus(List<Loan> loans) {
    if (loans.isEmpty) return 'No Loans';
    final hasActive = loans.any((loan) => loan.status == 'active' && loan.remainingBalance > 0);
    if (hasActive) return 'Active';
    return 'Settled';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF0E7A37);
      case 'Settled':
        return const Color(0xFF0070A8);
      default:
        return Colors.black54;
    }
  }
}
