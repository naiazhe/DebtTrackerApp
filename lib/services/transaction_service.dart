import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction_record.dart';

class TransactionService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<TransactionRecord> transactions = [];
  bool isLoading = false;

  Future<void> loadTransactions() async {
    isLoading = true;
    notifyListeners();

    transactions = await _db.getTransactions();

    isLoading = false;
    notifyListeners();
  }
}
