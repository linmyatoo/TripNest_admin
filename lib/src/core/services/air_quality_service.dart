import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AirQualityData {
  final int aqi;
  final double pm25;
  final double pm10;
  final String cityName;
  final DateTime updatedAt;

  AirQualityData({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.cityName,
    required this.updatedAt,
  });

  String get aqiLevel {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String get aqiColor {
    if (aqi <= 50) return 'green';
    if (aqi <= 100) return 'yellow';
    if (aqi <= 150) return 'orange';
    if (aqi <= 200) return 'red';
    if (aqi <= 300) return 'purple';
    return 'maroon';
  }
}

class AirQualityService {
  static const String _apiToken = '004eb8cf677c3893baf0b3a7267ba39d3359f777';
  static const String _baseUrl = 'https://api.waqi.info/feed';
  static const String _lastPm25Key = 'last_pm25_value';
  static const String _lastCheckDateKey = 'last_aqi_check_date';
  static const double _changeThreshold = 0.5;

  /// Get air quality data for current location
  static Future<AirQualityData?> getAirQuality(
      {String location = 'here'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$location/?token=$_apiToken'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          final aqiData = data['data'];
          final iaqi = aqiData['iaqi'] ?? {};

          return AirQualityData(
            aqi: aqiData['aqi'] ?? 0,
            pm25: (iaqi['pm25']?['v'] ?? 0).toDouble(),
            pm10: (iaqi['pm10']?['v'] ?? 0).toDouble(),
            cityName: aqiData['city']?['name'] ?? 'Unknown',
            updatedAt: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching air quality: $e');
      return null;
    }
  }

  /// Check and send notification if needed (once daily or on significant change)
  static Future<void> checkAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString(_lastCheckDateKey);
    final lastPm25 = prefs.getDouble(_lastPm25Key);

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final alreadyCheckedToday = lastCheckDate == todayStr;

    // Fetch current air quality
    final aqData = await getAirQuality();
    if (aqData == null) return;

    final currentPm25 = aqData.pm25;
    bool shouldNotify = false;
    String notificationReason = '';

    // Check if we should send notification
    if (!alreadyCheckedToday) {
      // Daily notification
      shouldNotify = true;
      notificationReason = 'Daily air quality update';
    } else if (lastPm25 != null) {
      // Check for significant change
      final change = (currentPm25 - lastPm25).abs();
      if (change >= _changeThreshold) {
        shouldNotify = true;
        final direction = currentPm25 > lastPm25 ? 'increased' : 'decreased';
        notificationReason = 'PM2.5 $direction by ${change.toStringAsFixed(1)}';
      }
    }

    if (shouldNotify) {
      // Send notification
      await NotificationService.addNotification(
        title: 'Air Quality Alert - ${aqData.cityName}',
        body:
            'AQI: ${aqData.aqi} (${aqData.aqiLevel})\nPM2.5: ${aqData.pm25.toStringAsFixed(1)} μg/m³\n$notificationReason',
      );

      // Update stored values
      await prefs.setString(_lastCheckDateKey, todayStr);
      await prefs.setDouble(_lastPm25Key, currentPm25);
    } else {
      // Still update the PM2.5 value for change detection
      await prefs.setDouble(_lastPm25Key, currentPm25);
    }
  }

  /// Force check and notify (for manual refresh)
  static Future<AirQualityData?> forceCheckAndNotify() async {
    final aqData = await getAirQuality();
    if (aqData == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    await prefs.setString(_lastCheckDateKey, todayStr);
    await prefs.setDouble(_lastPm25Key, aqData.pm25);

    return aqData;
  }

  /// Get cached PM2.5 value
  static Future<double?> getCachedPm25() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastPm25Key);
  }
}
