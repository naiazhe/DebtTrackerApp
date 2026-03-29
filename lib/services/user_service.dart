import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class UserService extends ChangeNotifier {
  static const String _userIdKey = 'saved_user_id';

  final DatabaseHelper _db = DatabaseHelper.instance;

  AppUser? currentUser;
  bool isLoading = false;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    isLoading = true;
    notifyListeners();

    // Try to load saved user session
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt(_userIdKey);

      if (savedUserId != null) {
        // Load user from database
        currentUser = await _db.getUserById(savedUserId);
      }
    } catch (e) {
      // If anything goes wrong, just proceed without a saved session
      currentUser = null;
    }

    _initialized = true;
    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveUserSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user.userId != null) {
        await prefs.setInt(_userIdKey, user.userId!);
      }
    } catch (e) {
      // If saving fails, don't break the login flow
    }
  }

  Future<String?> login({required String username, required String password}) async {
    final normalizedUsername = username.trim().toLowerCase();

    if (normalizedUsername.isEmpty || password.isEmpty) {
      return 'Please enter your username and password.';
    }

    isLoading = true;
    notifyListeners();

    final users = await _db.getUsers();
    final matchedByUsername = users.where((u) {
      return u.name.trim().toLowerCase() == normalizedUsername;
    }).cast<AppUser?>().firstWhere((u) => u != null, orElse: () => null);

    isLoading = false;

    if (matchedByUsername == null) {
      notifyListeners();
      return 'Invalid username.';
    }

    if (matchedByUsername.password != password) {
      notifyListeners();
      return 'Invalid password.';
    }

    currentUser = matchedByUsername;
    await _saveUserSession(currentUser!);
    notifyListeners();
    return null;
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedUsername.isEmpty || normalizedEmail.isEmpty || password.isEmpty) {
      return 'Please complete all required fields.';
    }

    if (password.length < 2) {
      return 'Password must be at least 2 characters.';
    }

    isLoading = true;
    notifyListeners();

    final users = await _db.getUsers();
    final hasSameUsername = users.any((u) => u.name.trim().toLowerCase() == normalizedUsername.toLowerCase());
    if (hasSameUsername) {
      isLoading = false;
      notifyListeners();
      return 'Username is already taken.';
    }

    final hasSameEmail = users.any((u) => u.email.trim().toLowerCase() == normalizedEmail);
    if (hasSameEmail) {
      isLoading = false;
      notifyListeners();
      return 'Email is already registered.';
    }

    final newUser = AppUser(
      name: normalizedUsername,
      email: normalizedEmail,
      password: password,
      createdAt: DateTime.now(),
    );

    final createdId = await _db.createUser(newUser);
    currentUser = await _db.getUserById(createdId);
    await _saveUserSession(currentUser!);

    isLoading = false;
    notifyListeners();
    return null;
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentUser == null) {
      return 'No active user session.';
    }

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      return 'Please complete all fields.';
    }

    if (currentPassword != currentUser!.password) {
      return 'Current password is incorrect.';
    }

    if (newPassword.length < 8) {
      return 'New password must be at least 8 characters.';
    }

    if (newPassword != confirmPassword) {
      return 'New password and confirmation do not match.';
    }

    if (newPassword == currentPassword) {
      return 'New password must be different from current password.';
    }

    isLoading = true;
    notifyListeners();

    await _db.updateUserPassword(currentUser!.userId!, newPassword);

    currentUser = AppUser(
      userId: currentUser!.userId,
      name: currentUser!.name,
      email: currentUser!.email,
      password: newPassword,
      createdAt: currentUser!.createdAt,
    );

    isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (e) {
      // If clearing fails, at least clear the in-memory user
    }
    notifyListeners();
  }
}
