import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/api_service.dart';
import 'package:tripnest/src/core/services/auth_storage.dart';
import 'package:tripnest/src/core/services/session.dart';

/// Regression cover for the collection endpoints.
///
/// These used to test a `Map<String, dynamic>` against `is List`, a comparison
/// the analyzer accepts but that can never be true, so every review the
/// backend returned was dropped and the Reviews page rendered as empty.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.init();
    await AuthStorage.saveAuth(
      token: 'test-token',
      user: {'id': 'u1', 'email': 'organizer@example.com'},
    );
    Session.resetForTest();
  });

  // Every case installs its own client; this only makes sure a stray call
  // outside one fails loudly instead of reaching the real backend.
  tearDown(() {
    apiClient = MockClient((_) async => throw StateError('unexpected request'));
  });

  void respondWith(String body, {int status = 200}) {
    apiClient = MockClient((_) async => http.Response(body, status));
  }

  group('getEventReviews', () {
    test('reads a bare JSON array', () async {
      respondWith('[{"rating":5,"comment":"great"},{"rating":4}]');

      final result = await ApiService().getEventReviews('e1');

      expect(result['success'], isTrue);
      expect(result['reviews'], hasLength(2));
      expect(result['reviews'][0]['comment'], 'great');
    });

    test('reads an array wrapped in a "reviews" key', () async {
      respondWith('{"reviews":[{"rating":3}]}');

      final result = await ApiService().getEventReviews('e1');

      expect(result['success'], isTrue);
      expect(result['reviews'], hasLength(1));
      expect(result['reviews'][0]['rating'], 3);
    });

    test('yields an empty list when the body is an unrelated object',
        () async {
      respondWith('{"message":"nothing here"}');

      final result = await ApiService().getEventReviews('e1');

      expect(result['success'], isTrue);
      expect(result['reviews'], isEmpty);
    });

    test('yields an empty list when nginx answers with HTML', () async {
      respondWith('<html><body>502 Bad Gateway</body></html>');

      final result = await ApiService().getEventReviews('e1');

      expect(result['success'], isTrue);
      expect(result['reviews'], isEmpty);
    });

    test('reports failure on a non-200, carrying the server error', () async {
      respondWith('{"error":"Event not found"}', status: 404);

      final result = await ApiService().getEventReviews('e1');

      expect(result['success'], isFalse);
      expect(result['message'], 'Event not found');
    });
  });

  group('getMyEvents', () {
    test('reads a bare JSON array', () async {
      respondWith('[{"title":"Songkran"},{"title":"Loy Krathong"}]');

      final result = await ApiService().getMyEvents();

      expect(result['success'], isTrue);
      expect(result['events'], hasLength(2));
    });

    test('reads an array wrapped in an "events" key', () async {
      respondWith('{"events":[{"title":"Songkran"}]}');

      final result = await ApiService().getMyEvents();

      expect(result['success'], isTrue);
      expect(result['events'], hasLength(1));
    });
  });
}
