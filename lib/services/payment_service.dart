import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';

class PaymentService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<PaymentEntry> payments = [];
  bool isLoading = false;

  Future<void> loadPayments(int loanId, int userId) async {
    isLoading = true;
    notifyListeners();

    payments = await _db.getPaymentsByLoanForUser(loanId, userId);

    isLoading = false;
    notifyListeners();
  }
}
