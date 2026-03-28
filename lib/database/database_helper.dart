import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/transaction_record.dart';
import '../models/user.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      await _ensureSchema(_database!);
      return _database!;
    }
    _database = await _initDatabase();
    await _ensureSchema(_database!);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'debt_tracker.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE borrowers (
        borrower_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        address TEXT NOT NULL,
        reference_contact TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE loans (
        loan_id INTEGER PRIMARY KEY AUTOINCREMENT,
        borrower_id INTEGER NOT NULL,
        loan_amount REAL NOT NULL,
        payout_amount REAL NOT NULL,
        given_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        has_interest INTEGER NOT NULL,
        interest_type TEXT NOT NULL,
        interest_rate REAL,
        interest_interval INTEGER, -- Updated column for interval types
        interest_interval_unit TEXT,
        fixed_interest_amount REAL,
        collect_upfront INTEGER NOT NULL,
        total_interest REAL NOT NULL,
        total_payable REAL NOT NULL,
        total_paid REAL NOT NULL,
        remaining_balance REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(borrower_id) REFERENCES borrowers(borrower_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        amount_paid REAL NOT NULL,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        borrower_id INTEGER NOT NULL,
        loan_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY(borrower_id) REFERENCES borrowers(borrower_id) ON DELETE CASCADE,
        FOREIGN KEY(loan_id) REFERENCES loans(loan_id) ON DELETE SET NULL
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE loans ADD COLUMN interest_interval_unit TEXT');
    }
  }

  Future<void> _ensureSchema(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(loans)');
    final hasInterestIntervalUnit = columns.any((c) => c['name'] == 'interest_interval_unit');

    if (!hasInterestIntervalUnit) {
      await db.execute('ALTER TABLE loans ADD COLUMN interest_interval_unit TEXT');
    }
  }

  // User CRUD
  Future<int> createUser(AppUser user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<AppUser>> getUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  Future<AppUser?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'user_id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return AppUser.fromMap(maps.first);
    return null;
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Borrower CRUD
  Future<int> createBorrower(Borrower borrower) async {
    final db = await database;
    return await db.insert('borrowers', borrower.toMap());
  }

  Future<List<Borrower>> getBorrowersByUser(int userId) async {
    final db = await database;
    final maps = await db.query('borrowers', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return maps.map((m) => Borrower.fromMap(m)).toList();
  }

  Future<Borrower?> getBorrowerById(int id) async {
    final db = await database;
    final maps = await db.query('borrowers', where: 'borrower_id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Borrower.fromMap(maps.first);
    return null;
  }

  Future<List<Borrower>> getAllBorrowers() async {
    final db = await database;
    final maps = await db.query('borrowers', orderBy: 'created_at DESC');
    return maps.map((m) => Borrower.fromMap(m)).toList();
  }

  Future<int> updateBorrower(Borrower borrower) async {
    final db = await database;
    return await db.update('borrowers', borrower.toMap(), where: 'borrower_id = ?', whereArgs: [borrower.borrowerId]);
  }

  Future<int> deleteBorrower(int borrowerId) async {
    final db = await database;
    return await db.delete('borrowers', where: 'borrower_id = ?', whereArgs: [borrowerId]);
  }

  // Loan CRUD
  Future<int> createLoan(Loan loan) async {
    final db = await database;
    return await db.insert('loans', loan.toMap());
  }

  Future<List<Loan>> getLoansByBorrower(int borrowerId) async {
    final db = await database;
    final maps = await db.query('loans', where: 'borrower_id = ?', whereArgs: [borrowerId], orderBy: 'created_at DESC');
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<Loan?> getLoanById(int id) async {
    final db = await database;
    final maps = await db.query('loans', where: 'loan_id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Loan.fromMap(maps.first);
    return null;
  }

  Future<List<Loan>> getAllLoans() async {
    final db = await database;
    final maps = await db.query('loans', orderBy: 'created_at DESC');
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<int> updateLoan(Loan loan) async {
    final db = await database;
    return await db.update('loans', loan.toMap(), where: 'loan_id = ?', whereArgs: [loan.loanId]);
  }

  Future<int> deleteLoan(int loanId) async {
    final db = await database;
    return await db.delete('loans', where: 'loan_id = ?', whereArgs: [loanId]);
  }

  // Payment CRUD
  Future<int> createPayment(PaymentEntry payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<PaymentEntry>> getPaymentsByLoan(int loanId) async {
    final db = await database;
    final maps = await db.query('payments', where: 'loan_id = ?', whereArgs: [loanId], orderBy: 'payment_date DESC');
    return maps.map((m) => PaymentEntry.fromMap(m)).toList();
  }

  // Transaction CRUD
  Future<int> createTransaction(TransactionRecord transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionRecord>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'transaction_date DESC');
    return maps.map((m) => TransactionRecord.fromMap(m)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
