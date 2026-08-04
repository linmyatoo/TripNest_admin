import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'security_service.dart';

/// Persistent auth storage using SharedPreferences
class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static String? _token;
  static Map<String, dynamic>? _user;
  static SharedPreferences? _prefs;

  /// Initialize storage - call this at app startup
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
    final userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
    debugPrint(
        'Auth initialized: ${isAuthenticated() ? 'User logged in' : 'No saved session'}');
  }

  /// Save authentication token and user data
  static Future<void> saveAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    _user = user;
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userKey, jsonEncode(user));
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

  /// Clear authentication data (logout).
  ///
  /// Also drops the per-user security preferences, so that "remember password"
  /// or Face ID enabled by one account does not carry into the next one on a
  /// shared device.
  static Future<void> clearAuth() async {
    _token = null;
    _user = null;
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
    await SecurityService.clearAllSettings();
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
