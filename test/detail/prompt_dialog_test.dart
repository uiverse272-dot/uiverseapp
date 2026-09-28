import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/prompt.dart';
import 'package:uiverse/detail/prompt_dialog.dart';
import 'package:uiverse/state/prompt_quota.dart';

import '../support/clipboard_mock.dart';
import 'detail_harness.dart';

void main() {
  final item = bySlug('s001-ledgerly-homepage')!;
  late FakeClipboard clipboard;
  setUp(() => clipboard = FakeClipboard.install());
  tearDown(FakeClipboard.uninstall);

  Future<ProviderContainer> open(WidgetTester tester, {double width = 1200}) async {
    final container = await pumpDetail(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showPromptDialog(context, item),
            child: const Text('open'),
          ),
        ),
      ),
      width: width,
      height: 900,
      scroll: false,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return container;
  }

  String promptText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> copy(WidgetTester tester) async {
    await tester.tap(find.text('Copy prompt'));
    await tester.pump();
    await tester.pump(kPromptCopiedFor);
  }

  testWidgets('shows the header and the default prompt', (tester) async {
    await open(tester);
    expect(find.text('Generate implementation prompt'), findsOneWidget);
    expect(find.text('${item.title} · ${item.source.name}'), findsOneWidget);
    expect(promptText(tester), buildPrompt(item, defaultPromptOptions));
    expect(find.textContaining('3 of 3 left this month'), findsOneWidget);
  });

  testWidgets('options regenerate the prompt and discard edits', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cursor'));
    await tester.pumpAndSettle();
    var opts = defaultPromptOptions.copyWith(tool: ToolId.cursor);
    expect(promptText(tester), buildPrompt(item, opts));

    await tester.enterText(find.byType(TextField), 'my edit');
    await tester.pump();
    expect(promptText(tester), 'my edit');
    expect(find.textContaining('~2 tokens'), findsOneWidget);

    await tester.tap(find.text('HTML + CSS'));
    await tester.pumpAndSettle();
    opts = opts.copyWith(stack: StackId.html);
    expect(promptText(tester), buildPrompt(item, opts));

    await tester.ensureVisible(find.text('Type scale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type scale'));
    await tester.pumpAndSettle();
    opts = opts.copyWith(includeType: false);
    expect(promptText(tester), buildPrompt(item, opts));
    expect(promptText(tester), isNot(buildPrompt(item, opts.copyWith(includeType: true))));
  });

  testWidgets('copy consumes quota; the 4th attempt is locked; reset unlocks', (tester) async {
    final container = await open(tester);

    await tester.tap(find.text('Copy prompt'));
    await tester.pump();
    expect(clipboard.text, buildPrompt(item, defaultPromptOptions));
    expect(find.text('Copied'), findsOneWidget);
    expect(container.read(promptQuotaProvider).used, 1);
    expect(find.textContaining('2 of 3 left this month'), findsOneWidget);
    await tester.pump(kPromptCopiedFor);
    expect(find.text('Copy prompt'), findsOneWidget);

    await copy(tester);
    await copy(tester);
    expect(container.read(promptQuotaProvider).locked, isTrue);
    expect(find.text("You've used your 3 free prompts this month"), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('See Pro'), findsOneWidget);

    // 4th attempt: disabled, nothing copied or counted.
    await tester.tap(find.text('Copy prompt'), warnIfMissed: false);
    await tester.pump();
    expect(clipboard.writes, 3);
    expect(container.read(promptQuotaProvider).used, 3);

    await tester.tap(find.text('Reset counter (demo only)'));
    await tester.pumpAndSettle();
    expect(container.read(promptQuotaProvider).used, 0);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('3 of 3 left this month'), findsOneWidget);
  });

  testWidgets('close button dismisses the dialog', (tester) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Close').last);
    await tester.pumpAndSettle();
    expect(find.text('Generate implementation prompt'), findsNothing);
  });

  testWidgets('is full screen on phones and lays out without overflow', (tester) async {
    await open(tester, width: 390);
    expect(find.text('Generate implementation prompt'), findsOneWidget);
    expect(tester.getSize(find.byType(PromptDialog)).width, 390);
    expect(tester.takeException(), isNull);
  });
}
