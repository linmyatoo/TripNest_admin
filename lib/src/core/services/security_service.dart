import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _keyRememberPassword = 'security_remember_password';
  static const String _keyFaceIdEnabled = 'security_face_id_enabled';
  static const String _keyBiometricEnabled = 'security_biometric_enabled';

  /// Check if Remember Password is enabled
  static Future<bool> isRememberPasswordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberPassword) ?? false;
  }

  /// Set Remember Password setting
  static Future<void> setRememberPassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberPassword, value);
  }

  /// Check if Face ID login is enabled
  static Future<bool> isFaceIdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFaceIdEnabled) ?? false;
  }

  /// Set Face ID enabled
  static Future<void> setFaceIdEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFaceIdEnabled, value);
  }

  /// Check if Biometric (fingerprint) login is enabled
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Set Biometric enabled
  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, value);
  }

  /// Check if Face ID is available on this device
  /// For now, this returns true on iOS devices as a simple check
  /// In production, you would use local_auth package to check biometric availability
  static Future<bool> isFaceIdAvailable() async {
    // Face ID is only available on iOS
    if (Platform.isIOS) {
      // In a real app, you would use local_auth package:
      // final localAuth = LocalAuthentication();
      // final availableBiometrics = await localAuth.getAvailableBiometrics();
      // return availableBiometrics.contains(BiometricType.face);
      return true; // Simplified for demo
    }
    return false;
  }

  /// Check if fingerprint/biometric is available on this device
  static Future<bool> isFingerprintAvailable() async {
    // In a real app, you would use local_auth package:
    // final localAuth = LocalAuthentication();
    // final availableBiometrics = await localAuth.getAvailableBiometrics();
    // return availableBiometrics.contains(BiometricType.fingerprint) ||
    //        availableBiometrics.contains(BiometricType.strong);

    // For demo purposes, return true on both iOS and Android
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Get all security settings
  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'rememberPassword': prefs.getBool(_keyRememberPassword) ?? false,
      'faceIdEnabled': prefs.getBool(_keyFaceIdEnabled) ?? false,
      'biometricEnabled': prefs.getBool(_keyBiometricEnabled) ?? false,
    };
  }

  /// Save all security settings at once
  static Future<void> saveAllSettings({
    required bool rememberPassword,
    required bool faceIdEnabled,
    required bool biometricEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberPassword, rememberPassword);
    await prefs.setBool(_keyFaceIdEnabled, faceIdEnabled);
    await prefs.setBool(_keyBiometricEnabled, biometricEnabled);
  }

  /// Clear all security settings (for logout)
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberPassword);
    await prefs.remove(_keyFaceIdEnabled);
    await prefs.remove(_keyBiometricEnabled);
  }
}
