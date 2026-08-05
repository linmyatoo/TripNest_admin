import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_storage.dart';
import 'notification_service.dart' show navigatorKey;

/// Shared HTTP client that reacts to an expired or revoked session.
///
/// Every authenticated call in the app goes through [apiClient]. When the
/// backend answers 401 the stored credentials are dropped and the user is sent
/// back to the login screen, instead of being stranded on a dashboard where
/// every panel fails with a Retry button that can never succeed.
///
/// Mutable so tests can substitute a client backed by `MockClient`; production
/// code should never reassign it.
http.Client apiClient = SessionAwareClient();

/// A [http.Client] that expires the local session whenever the backend
/// answers 401.
class SessionAwareClient extends http.BaseClient {
  SessionAwareClient({
    http.Client? inner,
    Future<void> Function(String?)? onUnauthorized,
  })  : _inner = inner ?? http.Client(),
        _onUnauthorized =
            onUnauthorized ?? ((token) => Session.expire(token));

  final http.Client _inner;
  final Future<void> Function(String?) _onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Captured before the round trip: by the time the response lands the
    // stored token may already have been replaced, and this 401 would then
    // belong to a session that no longer exists.
    final sentWith = request.headers['Authorization'];

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      // Deliberately not awaited: the caller still needs its response, and the
      // redirect is fire-and-forget.
      unawaited(_onUnauthorized(sentWith));
    }
    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class Session {
  /// Guards against a burst of parallel 401s (the dashboard fires several
  /// requests at once) each pushing its own login route.
  static bool _expiring = false;

  @visibleForTesting
  static void resetForTest() => _expiring = false;

  /// Drop local credentials and return to the login screen.
  ///
  /// [forToken] is the `Authorization` header the failing request was sent
  /// with. If it no longer matches what is stored, the 401 belongs to a
  /// superseded session — a request that was still in flight when the user
  /// logged out and back in — and acting on it would evict a perfectly valid
  /// token.
  static Future<void> expire([String? forToken]) async {
    if (_expiring) return;

    if (forToken != null && forToken != AuthStorage.getAuthHeader()) {
      debugPrint('Ignoring 401 from a superseded session');
      return;
    }

    _expiring = true;

    try {
      await AuthStorage.clearAuth();

      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        // Nothing attached yet (startup, or a hot restart). Credentials are
        // gone, so the next launch lands on onboarding.
        debugPrint('Session expired before a navigator was available');
        return;
      }

      debugPrint('Session expired: redirecting to login');
      // Not awaited: this future only completes when the login route is
      // popped, which would pin the guard below for the entire time the user
      // is looking at the login screen.
      unawaited(navigator.pushNamedAndRemoveUntil('/login', (_) => false));
    } catch (e, stack) {
      // Nothing can handle this — the call is fire-and-forget — so swallow it
      // rather than let it escape as an unhandled async error.
      debugPrint('Session.expire failed: $e\n$stack');
    } finally {
      _expiring = false;
    }
  }
}
