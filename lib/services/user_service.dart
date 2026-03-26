import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class UserService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  AppUser? currentUser;
  bool isLoading = false;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    final users = await _db.getUsers();
    if (users.isEmpty) {
      final created = AppUser(
        name: 'Default User',
        email: 'user@example.com',
        password: 'password',
        createdAt: DateTime.now(),
      );
      await _db.createUser(created);
      currentUser = (await _db.getUsers()).first;
    } else {
      currentUser = users.first;
    }

    isLoading = false;
    notifyListeners();
  }
}
