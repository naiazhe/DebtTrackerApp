import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/user_service.dart';
import 'services/borrower_service.dart';
import 'services/loan_service.dart';
import 'services/payment_service.dart';
import 'services/transaction_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/borrower_screen.dart';
import 'screens/loan_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const DebtTrackerApp());
}

class DebtTrackerApp extends StatelessWidget {
  const DebtTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => BorrowerService()),
        ChangeNotifierProvider(create: (_) => LoanService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Debt Tracker App',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    BorrowerScreen(),
    LoanScreen(),
    TransactionScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0070A8),
        unselectedItemColor: const Color(0xFF0070A8),
        selectedIconTheme: const IconThemeData(color: Color(0xFF0070A8)),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF0070A8)),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Borrower'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Loan'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transaction'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
