// Local stand-in for the backend, for trying accounts on an emulator before
// web ships docs/api-v1.md. In-memory; restarting it forgets everything.
//
//   dart run tool/fake_server.dart
//   flutter run --dart-define=UIVERSE_API_URL=http://10.0.2.2:8787
//
// Sign in with any email. The sign-in link prints here; open it on the device:
//   adb shell am start -a android.intent.action.VIEW -d "<link>"
// `/api/mobile/start` prints one too, after showing a button in the browser.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../test/api/fake_backend.dart';

const int _port = 8787;
const String _email = 'demo@example.com';

Future<void> main() async {
  final backend = FakeBackend();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
  stdout.writeln('Fake Uiverse API on http://localhost:$_port');

  await for (final HttpRequest req in server) {
    if (req.uri.path == '/api/mobile/start') {
      final link = _returnLink(backend, _email, req.uri.queryParameters['c'] ?? '');
      req.response
        ..headers.contentType = ContentType.html
        ..write('<!doctype html><meta name=viewport content="width=device-width">'
            '<p>Fake ${req.uri.queryParameters['provider']} sign-in</p><a href="$link">Open Uiverse</a>');
      await req.response.close();
      continue;
    }

    final request = http.Request(req.method, req.uri);
    req.headers.forEach((name, values) => request.headers[name] = values.join(','));
    request.body = await utf8.decodeStream(req);
    final http.Response response = await backend.handle(request);
    stdout.writeln('${req.method} ${req.uri.path} ${response.statusCode}');

    if (req.uri.path == '/api/mobile/magic-link' && response.statusCode == 200) {
      final sent = backend.links.last;
      stdout.writeln('Sign-in link for ${sent.email}:\n  ${_returnLink(backend, sent.email, sent.c)}');
    }
    req.response
      ..statusCode = response.statusCode
      ..headers.contentType = ContentType.json
      ..write(response.body);
    await req.response.close();
  }
}

String _returnLink(FakeBackend backend, String email, String challenge) =>
    'uiverse://auth?token=${backend.issueToken(email, challenge)}';
