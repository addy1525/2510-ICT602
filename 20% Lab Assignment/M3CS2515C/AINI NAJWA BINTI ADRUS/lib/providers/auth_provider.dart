import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final userService = UserService();
    final user = await userService.login(username, password);

    _isLoading = false;

    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  bool isAdmin() => _currentUser?.role == 'admin';
  bool isLecturer() => _currentUser?.role == 'lecturer';
  bool isStudent() => _currentUser?.role == 'student';
}
