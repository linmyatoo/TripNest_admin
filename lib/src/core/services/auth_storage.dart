import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent auth storage using SharedPreferences
class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static String? _token;
  static Map<String, dynamic>? _user;
  static SharedPreferences? _prefs;

  /// Initialize storage - call this at app startup.
  ///
  /// Runs before `runApp`, so it must not throw: a corrupted `auth_user`
  /// record would otherwise mean a black screen with no recovery short of
  /// reinstalling. A record that cannot be read is discarded instead.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);

    final userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      try {
        final decoded = jsonDecode(userJson);
        _user = decoded is Map<String, dynamic> ? decoded : null;
      } catch (e) {
        debugPrint('Discarding unreadable saved user record: $e');
        _user = null;
        await _prefs?.remove(_userKey);
      }
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

  /// Clear authentication data.
  ///
  /// Called both on deliberate logout and on a 401, so it does only what is
  /// safe in either case. Resetting the user's security toggles belongs to
  /// deliberate logout alone — see [ApiService.logout] — because those
  /// preferences hold no credentials and should survive a transient 401.
  static Future<void> clearAuth() async {
    _token = null;
    _user = null;
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
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
