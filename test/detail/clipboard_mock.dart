import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures `Clipboard.setData` calls on the platform channel.
class FakeClipboard {
  FakeClipboard._();

  String? text;
  int writes = 0;

  static FakeClipboard install() {
    final fake = FakeClipboard._();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<Object?, Object?>;
        fake
          ..text = args['text'] as String?
          ..writes += 1;
      }
      if (call.method == 'Clipboard.getData') return <String, Object?>{'text': fake.text};
      return null;
    });
    return fake;
  }

  static void uninstall() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}
