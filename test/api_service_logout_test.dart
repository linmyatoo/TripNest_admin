import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/api_service.dart';
import 'package:tripnest/src/core/services/auth_storage.dart';
import 'package:tripnest/src/core/services/security_service.dart';

/// Logging out must destroy the local session no matter what the server says.
/// Leaving the token behind means force-quitting the app after "Log out" drops
/// the next person straight back into the previous organizer's account.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ApiService serviceReturning(http.Response response) => ApiService(
        credentialClient: MockClient((_) async => response),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.init();
    await AuthStorage.saveAuth(
      token: 'T1',
      user: {'id': 'u1', 'email': 'organizer@example.com'},
    );
  });

  test('clears the session on a successful logout', () async {
    final result = await serviceReturning(http.Response('{}', 200)).logout();

    expect(result['success'], isTrue);
    expect(AuthStorage.isAuthenticated(), isFalse);
  });

  test('clears the session even when the server rejects the call', () async {
    // An already-expired token makes the logout endpoint itself return 401.
    final result = await serviceReturning(
      http.Response('{"message":"token expired"}', 401),
    ).logout();

    expect(result['success'], isFalse, reason: 'the server call did fail');
    expect(AuthStorage.isAuthenticated(), isFalse,
        reason: 'but the device must still be logged out');
  });

  test('clears the session when nginx answers with HTML instead of JSON',
      () async {
    final result = await serviceReturning(
      http.Response('<html><body>502 Bad Gateway</body></html>', 502),
    ).logout();

    expect(result['success'], isFalse);
    expect(result['message'], contains('502'));
    expect(AuthStorage.isAuthenticated(), isFalse);
  });

  test('clears the session when the request throws', () async {
    final service = ApiService(
      credentialClient: MockClient((_) async => throw const _Offline()),
    );

    final result = await service.logout();

    expect(result['success'], isTrue);
    expect(AuthStorage.isAuthenticated(), isFalse);
  });

  test('succeeds when there is no token to begin with', () async {
    await AuthStorage.clearAuth();

    final result = await serviceReturning(http.Response('{}', 200)).logout();

    expect(result['success'], isTrue);
    expect(AuthStorage.isAuthenticated(), isFalse);
  });

  test('resets the security toggles, which a bare 401 must not', () async {
    await SecurityService.setFaceIdEnabled(true);
    await SecurityService.setRememberPassword(true);

    await serviceReturning(http.Response('{}', 200)).logout();

    expect(await SecurityService.isFaceIdEnabled(), isFalse);
    expect(await SecurityService.isRememberPasswordEnabled(), isFalse);
  });

  test('AuthStorage.clearAuth on its own leaves security toggles alone',
      () async {
    await SecurityService.setFaceIdEnabled(true);

    // This is the path Session.expire takes on a transient 401.
    await AuthStorage.clearAuth();

    expect(AuthStorage.isAuthenticated(), isFalse);
    expect(await SecurityService.isFaceIdEnabled(), isTrue,
        reason: 'a server hiccup should not reset user preferences');
  });
}

class _Offline implements Exception {
  const _Offline();
}
