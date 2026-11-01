import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uiverse/api/api_client.dart';
import 'package:uiverse/state/auth.dart';

import 'account_harness.dart';
import 'state_harness.dart';

void main() {
  const email = 'ana@example.com';

  test('no API: signed out, and sign-in does nothing', () async {
    final (c, _) = await makeContainer();
    expect(c.read(authProvider).signedIn, isFalse);
    await c.read(authProvider.notifier).sendMagicLink(email);
    expect(c.read(authProvider).waiting, isFalse);
  });

  test('challenge is the unpadded base64url SHA-256 of the verifier', () {
    expect(challengeFor('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
    expect(newVerifier(), hasLength(43));
    expect(newVerifier(), isNot(newVerifier()));
  });

  test('magic link: sends only the challenge, then signs in from the return link', () async {
    final rig = AccountRig();
    final (c, prefs) = await accountContainer(rig);
    final n = c.read(authProvider.notifier);

    await n.sendMagicLink(email);
    expect(c.read(authProvider).waiting, isTrue);
    expect(c.read(authProvider).sentTo, email);
    final verifier = rig.secrets.values['uiv.auth.verifier']!;
    expect(rig.backend.links.single.c, challengeFor(verifier));
    expect(rig.backend.links.single.c, isNot(verifier));

    await n.handleLink(rig.returnLink(email));
    final s = c.read(authProvider);
    expect(s.user?.email, email);
    expect(s.waiting, isFalse);
    expect(await n.token(), isNotNull);
    expect(rig.secrets.values.containsKey('uiv.auth.verifier'), isFalse);
    expect(prefs.getString(kAuthUserKey), contains(email));
    expect(prefs.getString(kAuthUserKey), isNot(contains('sess-')));
  });

  test('OAuth opens the browser and signs in from the deep link stream', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    await c.read(authProvider.notifier).startOAuth(OAuthProvider.google);
    expect(rig.opened.single.queryParameters['provider'], 'google');

    rig.links.add(rig.returnLink(email));
    await pumpEventQueue();
    expect(c.read(authProvider).user?.email, email);
  });

  test('no browser means no sign-in in progress', () async {
    final rig = AccountRig()..browserWorks = false;
    final (c, _) = await accountContainer(rig);
    await c.read(authProvider.notifier).startOAuth(OAuthProvider.apple);
    expect(c.read(authProvider).waiting, isFalse);
    expect(c.read(authProvider).failure, AuthFailure.browser);
  });

  test('a link with no sign-in pending is ignored', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    final token = rig.backend.issueToken('attacker@example.com', 'whatever');
    await c.read(authProvider.notifier).handleLink(Uri.parse('uiverse://auth?token=$token'));
    expect(c.read(authProvider).signedIn, isFalse);
    expect(rig.backend.requests, isEmpty);
  });

  test('a token bound to another challenge cannot be redeemed', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    final n = c.read(authProvider.notifier);
    await n.sendMagicLink(email);
    final stolen = rig.backend.issueToken(email, challengeFor('someone-else'));
    await n.handleLink(Uri.parse('uiverse://auth?token=$stolen'));
    expect(c.read(authProvider).signedIn, isFalse);
    expect(c.read(authProvider).failure, AuthFailure.badLink);
  });

  test('cancel forgets the verifier, so a late link does nothing', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    final n = c.read(authProvider.notifier);
    await n.sendMagicLink(email);
    final late = rig.returnLink(email);
    await n.cancel();
    expect(c.read(authProvider).waiting, isFalse);
    await n.handleLink(late);
    expect(c.read(authProvider).signedIn, isFalse);
  });

  test('a link delivered twice exchanges once', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    final n = c.read(authProvider.notifier);
    await n.sendMagicLink(email);
    final link = rig.returnLink(email);
    await Future.wait([n.handleLink(link), n.handleLink(link)]);
    expect(c.read(authProvider).signedIn, isTrue);
    expect(rig.backend.requests.where((r) => r.endsWith('/exchange')), hasLength(1));
  });

  test('offline exchange keeps the verifier so the link can be tapped again', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    final n = c.read(authProvider.notifier);
    await n.sendMagicLink(email);
    final link = rig.returnLink(email);

    rig.backend.forceNext(http.Response('', 503));
    await n.handleLink(link);
    expect(c.read(authProvider).failure, AuthFailure.network);
    expect(c.read(authProvider).waiting, isTrue);

    await n.handleLink(link);
    expect(c.read(authProvider).signedIn, isTrue);
  });

  test('a refused provider return shows the failure', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    final n = c.read(authProvider.notifier);
    await n.startOAuth(OAuthProvider.google);
    await n.handleLink(Uri.parse('uiverse://auth?error=access_denied'));
    expect(c.read(authProvider).failure, AuthFailure.refused);
    expect(c.read(authProvider).waiting, isFalse);
  });

  test('a failed link request says why', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig);
    rig.backend.forceNext(http.Response('{"error":"failed"}', 503));
    await c.read(authProvider.notifier).sendMagicLink(email);
    expect(c.read(authProvider).failure, AuthFailure.network);
    expect(c.read(authProvider).waiting, isFalse);
  });

  test('the account shows on the first frame after a restart', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig, values: {
      kAuthUserKey: jsonEncode(const AccountUser(id: 'u1', email: email).toJson()),
    });
    expect(c.read(authProvider).user?.id, 'u1');
  });

  test('a keychain token with no stored user is dropped (reinstall)', () async {
    final rig = AccountRig();
    rig.secrets.values['uiv.auth.token'] = 'left-behind';
    final (c, _) = await accountContainer(rig);
    expect(c.read(authProvider).signedIn, isFalse);
    await pumpEventQueue();
    expect(rig.secrets.values, isEmpty);
  });

  test('401 marks the session expired and keeps the account', () async {
    final rig = AccountRig();
    final (c, _) = await accountContainer(rig, values: {
      kAuthUserKey: jsonEncode(const AccountUser(id: 'u1', email: email).toJson()),
    });
    c.read(authProvider.notifier).sessionExpired();
    expect(c.read(authProvider).expired, isTrue);
    expect(c.read(authProvider).user?.id, 'u1');
  });
}
