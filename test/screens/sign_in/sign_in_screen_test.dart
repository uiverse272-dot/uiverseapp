import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/state/auth.dart';

import '../../flows/flow_harness.dart';
import '../../state/account_harness.dart';

final Finder _emailField = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'you@example.com',
);

void main() {
  const email = 'ana@example.com';

  testWidgets('without a backend the screen says accounts are off', (tester) async {
    await pumpFlowApp(tester, location: '/sign-in');
    expect(find.textContaining("Accounts aren't switched on"), findsOneWidget);
    expect(find.text('Email me a sign-in link'), findsNothing);
  });

  testWidgets('profile offers no account panel without a backend', (tester) async {
    await pumpFlowApp(tester, location: '/u/me');
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('email link: send, wait, come back signed in on the profile page', (tester) async {
    final rig = AccountRig();
    final app = await pumpFlowApp(tester, location: '/u/me', overrides: rig.overrides);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, '/sign-in');

    await tester.enterText(_emailField, email);
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(rig.backend.links.single.email, email);

    await tester.runAsync(() async {
      rig.links.add(rig.returnLink(email));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, '/u/me');
    expect(find.text('Signed in as $email'), findsOneWidget);
  });

  testWidgets('a bad address is caught before any request', (tester) async {
    final rig = AccountRig();
    await pumpFlowApp(tester, location: '/sign-in', overrides: rig.overrides);
    await tester.enterText(_emailField, 'nope');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(rig.backend.requests, isEmpty);
  });

  testWidgets('Google waits on the browser and Cancel returns to the form', (tester) async {
    final rig = AccountRig();
    await pumpFlowApp(tester, location: '/sign-in', overrides: rig.overrides);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your browser'), findsOneWidget);
    expect(rig.opened.single.path, '/api/mobile/start');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Email me a sign-in link'), findsOneWidget);
  });

  testWidgets('a failed sign-in explains itself', (tester) async {
    final rig = AccountRig()..browserWorks = false;
    await pumpFlowApp(tester, location: '/sign-in', overrides: rig.overrides);
    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't open a browser on this device."), findsOneWidget);
  });

  testWidgets('sign-out ends the session here and on the server', (tester) async {
    final rig = AccountRig();
    final app = await pumpFlowApp(tester, location: '/u/me', overrides: rig.overrides, initial: {
      kAuthUserKey: '{"id":"u1","email":"$email"}',
    });
    rig.secrets.values['uiv.auth.token'] = rig.backend.sessionFor(email);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(rig.secrets.values, isEmpty);
    expect(app.prefs.getString(kAuthUserKey), isNull);
    expect(rig.backend.requests, contains('POST /api/auth/sign-out'));
  });
}
