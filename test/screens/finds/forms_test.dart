import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uiverse/screens/finds/finds_submit_screen.dart';
import 'package:uiverse/widgets/forms/form_parts.dart';

import '../../flows/flow_harness.dart';
import '../../state/account_harness.dart';

Finder _field(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(LabeledField)),
      matching: find.byType(TextField),
    );

Future<void> _type(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), value);
}

Future<void> _fillFind(WidgetTester tester) async {
  await _type(tester, 'Title of the piece', 'Tidal');
  await _type(tester, 'Your name', 'Ana');
  await _type(tester, 'Email', 'ana@example.com');
  await _type(tester, 'Link to the work', 'https://example.com/a');
  await _type(tester, 'Link to an image', 'https://example.com/a.png');
}

Future<void> _pressSend(WidgetTester tester, String label) async {
  await tester.pump();
  await tapVisible(tester, find.text(label));
}

void main() {
  group('Finds', () {
    testWidgets('without a backend the form is not offered', (tester) async {
      await pumpFlowApp(tester, location: '/finds/submit');
      expect(find.textContaining("aren't switched on"), findsOneWidget);
      expect(find.text('Send for review'), findsNothing);
    });

    testWidgets('sends the form and thanks the sender', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/finds/submit', overrides: rig.overrides);
      await _fillFind(tester);
      await tapVisible(tester, find.text('Motion'));
      await tapVisible(tester, find.byType(ConfirmBox));
      await _pressSend(tester, 'Send for review');

      expect(find.text('Submission received'), findsOneWidget);
      expect(find.textContaining('ana@example.com'), findsOneWidget);
      final sent = rig.backend.forms.single;
      expect(sent['tags'], ['motion']);
      expect(sent['confirm'], true);
    });

    testWidgets('shows a server field error beside its field', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/finds/submit', overrides: rig.overrides);
      await _pressSend(tester, 'Send for review');
      expect(find.text('Give the piece a title.'), findsOneWidget);
      expect(rig.backend.forms, isEmpty);
    });

    testWidgets('requires the confirmation', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/finds/submit', overrides: rig.overrides);
      await _fillFind(tester);
      await _pressSend(tester, 'Send for review');
      expect(find.text('Confirm the work is yours to share.'), findsOneWidget);
    });

    testWidgets('a fifth tag is not taken', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/finds/submit', overrides: rig.overrides);
      await _fillFind(tester);
      for (final (_, String name) in kFindTags.take(5)) {
        await tapVisible(tester, find.text(name));
      }
      await tapVisible(tester, find.byType(ConfirmBox));
      await _pressSend(tester, 'Send for review');
      expect(rig.backend.forms.single['tags'], hasLength(4));
    });

    testWidgets('rate limit says how long, and what was typed stays', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/finds/submit', overrides: rig.overrides);
      await _fillFind(tester);
      rig.backend.forceNext(http.Response('{"error":"rate","minutes":42}', 429));
      await _pressSend(tester, 'Send for review');
      expect(find.textContaining('try again in 42 minutes'), findsOneWidget);
      expect(find.text('Tidal'), findsOneWidget);
    });
  });

  group('Takedown', () {
    testWidgets('without a backend the page is text only', (tester) async {
      await pumpFlowApp(tester, location: '/legal/takedown');
      expect(find.text('Send removal request'), findsNothing);
    });

    testWidgets('sends the request and reports what is held', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/legal/takedown', overrides: rig.overrides);
      await _type(tester, 'Domain to remove', 'example.com');
      await _type(tester, 'Your name', 'Ana');
      await _type(tester, 'Email', 'ana@example.com');
      await tapVisible(tester, find.text('Authorized to act for them'));
      await tapVisible(tester, find.byType(ConfirmBox));
      await _pressSend(tester, 'Send removal request');

      expect(find.text('Request received'), findsOneWidget);
      expect(find.textContaining('We hold 3 captures from example.com'), findsOneWidget);
      expect(find.text('TD-20261101-ABC123'), findsOneWidget);
      expect(rig.backend.forms.single['role'], 'agent');
    });

    testWidgets('a bad domain is shown beside the field', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/legal/takedown', overrides: rig.overrides);
      await _pressSend(tester, 'Send removal request');
      expect(find.text("Enter the site's domain, like example.com."), findsOneWidget);
    });

    testWidgets('offline says it failed and lets you retry', (tester) async {
      final rig = AccountRig();
      await pumpFlowApp(tester, location: '/legal/takedown', overrides: rig.overrides);
      await _type(tester, 'Domain to remove', 'example.com');
      rig.backend.forceNext(http.Response('', 502));
      await _pressSend(tester, 'Send removal request');
      expect(find.textContaining("couldn't be sent"), findsOneWidget);
      expect(find.text('Send removal request'), findsOneWidget);
    });
  });
}
