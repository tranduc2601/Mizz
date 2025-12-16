import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user_model.dart';

/// Authentication Service
/// Manages user authentication state
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Simulated user database (in real app, use backend/database)
  final Map<String, Map<String, String>> _users = {};

  AuthService() {
    _loadUsers();
    _loadCurrentUser();
  }

  /// Load users from shared preferences
  Future<void> _loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      if (usersJson != null) {
        final Map<String, dynamic> decoded = json.decode(usersJson);
        _users.clear();
        decoded.forEach((key, value) {
          _users[key] = Map<String, String>.from(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  /// Save users to shared preferences
  Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = json.encode(_users);
      await prefs.setString('users', usersJson);
    } catch (e) {
      debugPrint('Error saving users: $e');
    }
  }

  /// Load current user from shared preferences
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('currentUser');
      if (userJson != null) {
        final Map<String, dynamic> decoded = json.decode(userJson);
        _currentUser = UserModel(
          id: decoded['id'],
          email: decoded['email'],
          name: decoded['name'],
          avatarUrl: decoded['avatarUrl'],
          createdAt: DateTime.parse(decoded['createdAt']),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  /// Save current user to shared preferences
  Future<void> _saveCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        final userMap = {
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'name': _currentUser!.name,
          'avatarUrl': _currentUser!.avatarUrl,
          'createdAt': _currentUser!.createdAt.toIso8601String(),
        };
        await prefs.setString('currentUser', json.encode(userMap));
      } else {
        await prefs.remove('currentUser');
      }
    } catch (e) {
      debugPrint('Error saving current user: $e');
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure users are loaded from storage
      await _loadUsers();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if user exists
      if (!_users.containsKey(email)) {
        _error = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verify password
      if (_users[email]!['password'] != password) {
        _error = 'Incorrect password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create user session
      _currentUser = UserModel(
        id: _users[email]!['id']!,
        email: email,
        name: _users[email]!['name']!,
        avatarUrl: _users[email]!['avatarUrl'],
        createdAt: DateTime.now(),
      );

      await _saveCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if user already exists
      if (_users.containsKey(email)) {
        _error = 'Email already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      _users[email] = {
        'id': userId,
        'password': password,
        'name': name,
        'avatarUrl': '',
      };

      await _saveUsers();

      // Auto login after registration
      _currentUser = UserModel(
        id: userId,
        email: email,
        name: name,
        avatarUrl: null,
        createdAt: DateTime.now(),
      );

      await _saveCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    await _saveCurrentUser();
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      final oldEmail = _currentUser!.email;
      final newEmail = email ?? oldEmail;

      // Check if email is being changed to an existing email
      if (email != null && email != oldEmail && _users.containsKey(email)) {
        _error = 'Email already in use by another account';
        notifyListeners();
        return false;
      }

      // If email changed, update the users map key
      if (email != null && email != oldEmail) {
        // Copy user data to new email key
        _users[email] = Map<String, String>.from(_users[oldEmail]!);
        // Remove old email key
        _users.remove(oldEmail);
      }

      _currentUser = _currentUser!.copyWith(
        name: name,
        email: newEmail,
        avatarUrl: avatarUrl,
      );

      // Update in database
      if (_users.containsKey(newEmail)) {
        if (name != null) {
          _users[newEmail]!['name'] = name;
        }
        if (avatarUrl != null) {
          _users[newEmail]!['avatarUrl'] = avatarUrl;
        }
        await _saveUsers();
      }

      await _saveCurrentUser();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
