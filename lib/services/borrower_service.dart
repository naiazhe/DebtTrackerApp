import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/borrower.dart';

class BorrowerService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Borrower> borrowers = [];
  bool isLoading = false;

  Future<void> loadBorrowers(int userId) async {
    isLoading = true;
    notifyListeners();

    borrowers = await _db.getBorrowersByUser(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<int> addBorrower(Borrower borrower) async {
    return await _db.createBorrower(borrower);
  }

  Future<void> updateBorrower(Borrower borrower) async {
    await _db.updateBorrower(borrower);
  }

  Future<void> deleteBorrower(int borrowerId) async {
    await _db.deleteBorrower(borrowerId);
  }
}
