import 'package:flutter/material.dart';

/// Simple in-memory auth storage
/// For production, consider using flutter_secure_storage or shared_preferences
class AuthStorage {
  static String? _token;
  static Map<String, dynamic>? _user;

  /// Save authentication token and user data
  static Future<void> saveAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    _user = user;
    debugPrint('Auth saved: Token and user data stored');
  }

  /// Get saved token
  static String? getToken() {
    return _token;
  }

  /// Get saved user data
  static Map<String, dynamic>? getUser() {
    return _user;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _token != null && _token!.isNotEmpty;
  }

  /// Clear authentication data (logout)
  static Future<void> clearAuth() async {
    _token = null;
    _user = null;
    debugPrint('Auth cleared: Token and user data removed');
  }

  /// Get authorization header value
  static String? getAuthHeader() {
    if (_token != null) {
      return 'Bearer $_token';
    }
    return null;
  }
}
