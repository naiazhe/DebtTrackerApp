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
import 'screens/login_screen.dart';

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7FBFC),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();

    if (userService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userService.currentUser == null) {
      return const LoginScreen();
    }

    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(onNavigateToTab: _onItemTapped),
      const BorrowerScreen(),
      const LoanScreen(),
      const TransactionScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            // slight shadow on top of the bar
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          height: 70, // increased height for better touch target
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF0070A8),
            unselectedItemColor: Colors.black,
            selectedIconTheme: const IconThemeData(color: Color(0xFF0070A8), size: 28),
            unselectedIconTheme: const IconThemeData(color: Colors.black, size: 26),
            iconSize: 26,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Borrower'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Loan'),
              BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Transaction'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
