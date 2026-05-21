import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String department,
    required UserRole role,
  });

  Future<void> addAdmin({
    required String name,
    required String email,
    required String password,
  });

  Future<List<UserModel>> getAllUsers();
  
  Future<void> updateUser(UserModel updatedUser);
  
  Future<void> updateProfile({
    required String oldEmail,
    required UserModel updatedUser,
    required String currentPassword,
    String? newPassword,
  });
  
  Future<void> deleteUser(String email);

  Future<UserModel?> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get onAuthStateChanged;
}

class MockAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _authStreamController =
      StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  
  // Constants for Local Storage keys
  static const String _usersKey = 'mock_users';
  static const String _currentUserKey = 'mock_current_user';

  MockAuthRepository() {
    _initMockDatabase();
  }

  Future<void> _initMockDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we already initialized seed accounts
    if (!prefs.containsKey(_usersKey)) {
      final seedUsers = [
        UserModel(
          uid: 'student_seed_1',
          name: 'Sumon Ahmed',
          email: 'student@pundra.edu',
          studentId: '0322320105101047',
          department: 'CSE',
          role: UserRole.student,
        ),
        UserModel(
          uid: 'admin_seed_1',
          name: 'Md. Forhan Shahriar Fahim',
          email: 'admin@pundra.edu',
          studentId: '',
          department: 'CSE',
          role: UserRole.admin,
        ),
      ];
      
      final Map<String, dynamic> usersMap = {};
      for (var u in seedUsers) {
        usersMap[u.email] = {
          'user': u.toMap(),
          'password': 'password123', // Static simple password for testing
        };
      }
      await prefs.setString(_usersKey, jsonEncode(usersMap));
    }

    // Check if someone was already signed in
    final currentUserStr = prefs.getString(_currentUserKey);
    if (currentUserStr != null) {
      _currentUser = UserModel.fromMap(jsonDecode(currentUserStr));
      _authStreamController.add(_currentUser);
    } else {
      _authStreamController.add(null);
    }
  }

  @override
  Stream<UserModel?> get onAuthStateChanged => _authStreamController.stream;

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network lag
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = jsonDecode(usersStr);

    if (usersMap.containsKey(email)) {
      final userData = usersMap[email];
      if (userData['password'] == password) {
        final user = UserModel.fromMap(userData['user']);
        _currentUser = user;
        await prefs.setString(_currentUserKey, jsonEncode(user.toMap()));
        _authStreamController.add(_currentUser);
        return _currentUser;
      } else {
        throw Exception('Incorrect password');
      }
    } else {
      throw Exception('User not found. Try student@pundra.edu or register a new one.');
    }
  }

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String department,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = Map<String, dynamic>.from(jsonDecode(usersStr));

    if (usersMap.containsKey(email)) {
      throw Exception('Email already registered');
    }

    final newUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      uid: newUid,
      name: name,
      email: email,
      studentId: role == UserRole.student ? studentId : '',
      department: role == UserRole.student ? department : '',
      role: role,
    );

    usersMap[email] = {
      'user': newUser.toMap(),
      'password': password,
    };

    await prefs.setString(_usersKey, jsonEncode(usersMap));
    _currentUser = newUser;
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toMap()));
    _authStreamController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> addAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = Map<String, dynamic>.from(jsonDecode(usersStr));

    if (usersMap.containsKey(email)) {
      throw Exception('Email already registered');
    }

    final newUid = 'admin_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      uid: newUid,
      name: name,
      email: email,
      studentId: '',
      department: '',
      role: UserRole.admin,
    );

    usersMap[email] = {
      'user': newUser.toMap(),
      'password': password,
    };

    await prefs.setString(_usersKey, jsonEncode(usersMap));
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = jsonDecode(usersStr);

    return usersMap.values.map((userData) {
      return UserModel.fromMap(userData['user']);
    }).toList();
  }

  @override
  Future<void> updateUser(UserModel updatedUser) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = Map<String, dynamic>.from(jsonDecode(usersStr));

    if (!usersMap.containsKey(updatedUser.email)) {
      throw Exception('User not found');
    }

    // Preserve the password when updating user details
    final existingPassword = usersMap[updatedUser.email]['password'];
    usersMap[updatedUser.email] = {
      'user': updatedUser.toMap(),
      'password': existingPassword,
    };

    await prefs.setString(_usersKey, jsonEncode(usersMap));

    // Update current user if the admin is updating their own profile
    if (_currentUser?.email == updatedUser.email) {
      _currentUser = updatedUser;
      await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toMap()));
      _authStreamController.add(_currentUser);
    }
  }

  @override
  Future<void> updateProfile({
    required String oldEmail,
    required UserModel updatedUser,
    required String currentPassword,
    String? newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = Map<String, dynamic>.from(jsonDecode(usersStr));

    if (!usersMap.containsKey(oldEmail)) {
      throw Exception('User not found');
    }

    // Verify current password
    if (usersMap[oldEmail]['password'] != currentPassword) {
      throw Exception('Incorrect current password');
    }

    // Check if changing email and if new email is already taken
    if (oldEmail != updatedUser.email && usersMap.containsKey(updatedUser.email)) {
      throw Exception('Email already in use');
    }

    final passToSave = (newPassword != null && newPassword.isNotEmpty) 
        ? newPassword 
        : currentPassword;

    // If email changed, remove old key
    if (oldEmail != updatedUser.email) {
      usersMap.remove(oldEmail);
    }

    usersMap[updatedUser.email] = {
      'user': updatedUser.toMap(),
      'password': passToSave,
    };

    await prefs.setString(_usersKey, jsonEncode(usersMap));

    // If updating own profile
    if (_currentUser?.email == oldEmail || _currentUser?.email == updatedUser.email) {
      _currentUser = updatedUser;
      await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toMap()));
      _authStreamController.add(_currentUser);
    }
  }

  @override
  Future<void> deleteUser(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap = Map<String, dynamic>.from(jsonDecode(usersStr));

    if (!usersMap.containsKey(email)) {
      throw Exception('User not found');
    }

    if (_currentUser?.email == email) {
      throw Exception('You cannot delete your own active account');
    }

    usersMap.remove(email);
    await prefs.setString(_usersKey, jsonEncode(usersMap));
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    _currentUser = null;
    _authStreamController.add(null);
  }
}
