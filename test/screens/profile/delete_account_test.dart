import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uiverse/state/auth.dart';

import '../../flows/flow_harness.dart';
import '../../state/account_harness.dart';

const String _email = 'ana@example.com';

final Finder _typed = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == _email,
);

Future<(AccountRig, FlowApp)> _signedIn(WidgetTester tester) async {
  final rig = AccountRig();
  rig.secrets.values['uiv.auth.token'] = rig.backend.sessionFor(_email);
  final app = await pumpFlowApp(tester, location: '/u/me', overrides: rig.overrides, initial: {
    kAuthUserKey: '{"id":"u1","email":"$_email"}',
  });
  return (rig, app);
}

Future<void> _open(WidgetTester tester) async {
  await tapVisible(tester, find.text('Delete my account'));
}

void main() {
  testWidgets('needs the address typed before it offers to delete', (tester) async {
    final (rig, _) = await _signedIn(tester);
    await _open(tester);
    expect(find.text('Delete permanently'), findsNothing);

    await tester.enterText(_typed, 'someone@else.com');
    await tester.pumpAndSettle();
    expect(find.text('Delete permanently'), findsNothing);

    await tester.enterText(_typed, ' ANA@example.com ');
    await tester.pumpAndSettle();
    expect(find.text('Delete permanently'), findsOneWidget);
    expect(rig.backend.requests, isNot(contains('POST /api/auth/delete-user')));
  });

  testWidgets('deleting removes the account here and on the server', (tester) async {
    final (rig, app) = await _signedIn(tester);
    await _open(tester);
    await tester.enterText(_typed, _email);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Delete permanently'));

    expect(rig.backend.hasAccount(_email), isFalse);
    expect(rig.secrets.values, isEmpty);
    expect(app.prefs.getString(kAuthUserKey), isNull);
    expect(app.router.state.uri.path, '/');
  });

  testWidgets('a stale session is sent to sign in again and deletes nothing', (tester) async {
    final (rig, app) = await _signedIn(tester);
    rig.backend.sessionFresh = false;
    await _open(tester);
    await tester.enterText(_typed, _email);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Delete permanently'));

    expect(find.textContaining('needs a sign-in from the last hour'), findsOneWidget);
    expect(rig.backend.hasAccount(_email), isTrue);
    await tapVisible(tester, find.text('Sign in again'));
    expect(app.router.state.uri.path, '/sign-in');
  });

  testWidgets('a server failure keeps the account and says so', (tester) async {
    final (rig, app) = await _signedIn(tester);
    await _open(tester);
    await tester.enterText(_typed, _email);
    await tester.pumpAndSettle();
    rig.backend.forceNext(http.Response('', 500));
    await tapVisible(tester, find.text('Delete permanently'));

    expect(find.textContaining("couldn't be deleted"), findsOneWidget);
    expect(app.prefs.getString(kAuthUserKey), isNotNull);
    expect(rig.secrets.values, isNotEmpty);
  });
}
