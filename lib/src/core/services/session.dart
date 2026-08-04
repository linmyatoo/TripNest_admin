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
final http.Client apiClient = _SessionAwareClient();

class _SessionAwareClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) {
      // Do not await: the caller still needs its response, and the redirect
      // is fire-and-forget.
      Session.expire();
    }
    return response;
  }
}

class Session {
  /// Guards against a burst of parallel 401s (the dashboard fires several
  /// requests at once) each pushing its own login route.
  static bool _expiring = false;

  /// Drop local credentials and return to the login screen.
  static Future<void> expire() async {
    if (_expiring) return;
    _expiring = true;

    try {
      await AuthStorage.clearAuth();
      debugPrint('Session expired: redirecting to login');
      await navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
      );
    } finally {
      _expiring = false;
    }
  }
}
