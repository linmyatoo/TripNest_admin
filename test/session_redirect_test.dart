import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/auth_storage.dart';
import 'package:tripnest/src/core/services/notification_service.dart'
    show navigatorKey;
import 'package:tripnest/src/core/services/session.dart';

/// Exercises the redirect itself, which the unit tests cannot reach: they run
/// with no navigator attached.
Widget _harness() => MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/app',
      routes: {
        '/app': (_) => const Scaffold(body: Text('DASHBOARD')),
        '/login': (_) => const Scaffold(body: Text('LOGIN')),
      },
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.init();
    Session.resetForTest();
    await AuthStorage.saveAuth(
      token: 'T1',
      user: {'id': 'u1', 'email': 'organizer@example.com'},
    );
  });

  testWidgets('an expired session lands on login with the stack cleared',
      (tester) async {
    await tester.pumpWidget(_harness());
    expect(find.text('DASHBOARD'), findsOneWidget);

    await Session.expire('Bearer T1');
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsNothing);

    // The dashboard must not be reachable by backing out of login.
    expect(navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('a superseded 401 leaves the user where they are',
      (tester) async {
    await tester.pumpWidget(_harness());

    // 401 from a request sent under an older token.
    await Session.expire('Bearer T0');
    await tester.pumpAndSettle();

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(AuthStorage.isAuthenticated(), isTrue);
  });
}
