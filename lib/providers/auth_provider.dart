import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/service_locator.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = ServiceLocator.authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authRepository.onAuthStateChanged.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> checkCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.signIn(email: email, password: password);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String department,
    required UserRole role,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.signUp(
        name: name,
        email: email,
        password: password,
        studentId: studentId,
        department: department,
        role: role,
      );
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _cleanErrorMessage(String rawError) {
    if (rawError.startsWith('Exception: ')) {
      return rawError.substring(10);
    }
    return rawError;
  }
}
