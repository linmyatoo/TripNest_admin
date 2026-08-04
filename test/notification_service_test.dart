import 'package:flutter_test/flutter_test.dart';
import 'package:tripnest/src/core/services/notification_service.dart';

void main() {
  group('AppNotification serialization', () {
    test('survives a toJson/fromJson round trip', () {
      final original = AppNotification(
        id: '1735689600000',
        title: 'Air Quality Alert - Chiang Rai',
        body: 'AQI: 78 (Moderate)',
        createdAt: DateTime(2026, 1, 1, 9, 30),
        isRead: true,
      );

      final restored = AppNotification.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.createdAt, original.createdAt);
      expect(restored.isRead, original.isRead);
    });

    test('defaults isRead to false when the stored record omits it', () {
      final restored = AppNotification.fromJson({
        'id': '1',
        'title': 'Event Created Successfully',
        'body': '"Sunset Beach Yoga" has been published.',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });

      expect(restored.isRead, isFalse);
    });
  });

  group('AppNotification.timeAgo', () {
    AppNotification agedBy(Duration age) => AppNotification(
          id: '1',
          title: 't',
          body: 'b',
          createdAt: DateTime.now().subtract(age),
        );

    test('describes sub-minute ages as "Just now"', () {
      expect(agedBy(const Duration(seconds: 30)).timeAgo, 'Just now');
    });

    test('switches to minutes, then hours, then days', () {
      expect(agedBy(const Duration(minutes: 5)).timeAgo, '5m ago');
      expect(agedBy(const Duration(hours: 3)).timeAgo, '3h ago');
      expect(agedBy(const Duration(days: 2)).timeAgo, '2d ago');
    });

    test('falls back to an absolute date once a week has passed', () {
      final old = AppNotification(
        id: '1',
        title: 't',
        body: 'b',
        createdAt: DateTime(2026, 3, 14),
      );

      expect(old.timeAgo, '14/3/2026');
    });
  });
}
