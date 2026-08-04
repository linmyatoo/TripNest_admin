import 'package:flutter_test/flutter_test.dart';
import 'package:tripnest/src/core/services/air_quality_service.dart';

AirQualityData _data(int aqi) => AirQualityData(
      aqi: aqi,
      pm25: 0,
      pm10: 0,
      cityName: 'Chiang Rai',
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('AirQualityData.aqiLevel', () {
    test('maps each band, including its boundary value', () {
      expect(_data(0).aqiLevel, 'Good');
      expect(_data(50).aqiLevel, 'Good');
      expect(_data(51).aqiLevel, 'Moderate');
      expect(_data(100).aqiLevel, 'Moderate');
      expect(_data(101).aqiLevel, 'Unhealthy for Sensitive Groups');
      expect(_data(150).aqiLevel, 'Unhealthy for Sensitive Groups');
      expect(_data(151).aqiLevel, 'Unhealthy');
      expect(_data(200).aqiLevel, 'Unhealthy');
      expect(_data(201).aqiLevel, 'Very Unhealthy');
      expect(_data(300).aqiLevel, 'Very Unhealthy');
      expect(_data(301).aqiLevel, 'Hazardous');
    });
  });

  group('AirQualityData.aqiColor', () {
    test('stays in step with aqiLevel across every boundary', () {
      expect(_data(50).aqiColor, 'green');
      expect(_data(51).aqiColor, 'yellow');
      expect(_data(100).aqiColor, 'yellow');
      expect(_data(101).aqiColor, 'orange');
      expect(_data(150).aqiColor, 'orange');
      expect(_data(151).aqiColor, 'red');
      expect(_data(200).aqiColor, 'red');
      expect(_data(201).aqiColor, 'purple');
      expect(_data(300).aqiColor, 'purple');
      expect(_data(301).aqiColor, 'maroon');
    });
  });
}
