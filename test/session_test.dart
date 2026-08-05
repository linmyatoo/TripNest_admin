import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/auth_storage.dart';
import 'package:tripnest/src/core/services/session.dart';

/// Records which `Authorization` headers triggered an expiry, so tests can
/// assert both how many times it fired and which session it belonged to.
class _ExpiryRecorder {
  final List<String?> calls = [];

  Future<void> call(String? token) async {
    calls.add(token);
  }
}

Future<void> _signIn(String token) => AuthStorage.saveAuth(
      token: token,
      user: {'id': 'u1', 'email': 'organizer@example.com'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.init();
    Session.resetForTest();
  });

  group('SessionAwareClient', () {
    test('passes a successful response through without expiring', () async {
      final recorder = _ExpiryRecorder();
      final client = SessionAwareClient(
        inner: MockClient((_) async => http.Response('{"ok":true}', 200)),
        onUnauthorized: recorder.call,
      );

      final response = await client.get(Uri.parse('https://example.test/x'));

      expect(response.statusCode, 200);
      expect(recorder.calls, isEmpty);
    });

    test('returns the 401 body to the caller as well as expiring', () async {
      final recorder = _ExpiryRecorder();
      final client = SessionAwareClient(
        inner: MockClient((_) async => http.Response('{"error":"nope"}', 401)),
        onUnauthorized: recorder.call,
      );

      final response = await client.get(Uri.parse('https://example.test/x'));

      // The caller still needs its response — expiry is fire-and-forget.
      expect(response.statusCode, 401);
      expect(response.body, '{"error":"nope"}');
    });

    test('reports the Authorization header the failing request carried',
        () async {
      final recorder = _ExpiryRecorder();
      final client = SessionAwareClient(
        inner: MockClient((_) async => http.Response('{}', 401)),
        onUnauthorized: recorder.call,
      );

      await client.get(
        Uri.parse('https://example.test/x'),
        headers: {'Authorization': 'Bearer T1'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(recorder.calls, ['Bearer T1']);
    });

    test('closing the client closes the inner client', () {
      final inner = _CloseSpy();
      SessionAwareClient(inner: inner, onUnauthorized: (_) async {}).close();

      expect(inner.closed, isTrue);
    });
  });

  group('Session.expire', () {
    test('clears stored credentials', () async {
      await _signIn('T1');
      expect(AuthStorage.isAuthenticated(), isTrue);

      await Session.expire('Bearer T1');

      expect(AuthStorage.isAuthenticated(), isFalse);
      expect(AuthStorage.getToken(), isNull);
    });

    test('ignores a 401 belonging to a superseded session', () async {
      // The user was logged out and signed back in while a request from the
      // previous session was still in flight.
      await _signIn('T2');

      await Session.expire('Bearer T1');

      // The newer token must survive.
      expect(AuthStorage.isAuthenticated(), isTrue);
      expect(AuthStorage.getToken(), 'T2');
    });

    test('acts on a 401 that matches the current token', () async {
      await _signIn('T2');

      await Session.expire('Bearer T2');

      expect(AuthStorage.isAuthenticated(), isFalse);
    });

    test('a burst of concurrent 401s clears the session once, not repeatedly',
        () async {
      await _signIn('T1');

      await Future.wait([
        Session.expire('Bearer T1'),
        Session.expire('Bearer T1'),
        Session.expire('Bearer T1'),
      ]);

      expect(AuthStorage.isAuthenticated(), isFalse);
    });

    test('does not stay latched after it runs', () async {
      await _signIn('T1');
      await Session.expire('Bearer T1');

      // A later session must still be expirable — if the guard latched, this
      // second call would silently do nothing.
      await _signIn('T2');
      await Session.expire('Bearer T2');

      expect(AuthStorage.isAuthenticated(), isFalse);
    });

    test('survives being called with no navigator attached', () async {
      await _signIn('T1');

      // navigatorKey has no state in a plain unit test; this must not throw.
      await expectLater(Session.expire('Bearer T1'), completes);
      expect(AuthStorage.isAuthenticated(), isFalse);
    });
  });
}

class _CloseSpy extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(const Stream.empty(), 200);

  @override
  void close() => closed = true;
}
