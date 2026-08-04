import 'package:shared_preferences/shared_preferences.dart';

/// User-facing notification preferences.
///
/// Distinct from `NotificationService`, which delivers notifications. The two
/// used to share a name, which meant no file could import both.
class NotificationSettingsService {
  static const String _keyNotifications = 'notif_notifications';
  static const String _keySound = 'notif_sound';
  static const String _keyVibrate = 'notif_vibrate';
  static const String _keySpecialOffers = 'notif_special_offers';
  static const String _keyPayments = 'notif_payments';
  static const String _keyCashback = 'notif_cashback';
  static const String _keyAppUpdates = 'notif_app_updates';

  /// Get all notification settings
  static Future<Map<String, bool>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'notifications': prefs.getBool(_keyNotifications) ?? true,
      'sound': prefs.getBool(_keySound) ?? true,
      'vibrate': prefs.getBool(_keyVibrate) ?? true,
      'specialOffers': prefs.getBool(_keySpecialOffers) ?? true,
      'payments': prefs.getBool(_keyPayments) ?? true,
      'cashback': prefs.getBool(_keyCashback) ?? true,
      'appUpdates': prefs.getBool(_keyAppUpdates) ?? true,
    };
  }

  /// Save all notification settings
  static Future<void> saveAllSettings({
    required bool notifications,
    required bool sound,
    required bool vibrate,
    required bool specialOffers,
    required bool payments,
    required bool cashback,
    required bool appUpdates,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, notifications);
    await prefs.setBool(_keySound, sound);
    await prefs.setBool(_keyVibrate, vibrate);
    await prefs.setBool(_keySpecialOffers, specialOffers);
    await prefs.setBool(_keyPayments, payments);
    await prefs.setBool(_keyCashback, cashback);
    await prefs.setBool(_keyAppUpdates, appUpdates);
  }

  /// Get a single setting
  static Future<bool> getSetting(String key, {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Set a single setting
  static Future<void> setSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }
}
