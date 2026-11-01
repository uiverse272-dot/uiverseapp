import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../router/routes.dart';
import '../../state/auth.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/box_button.dart';
import '../../widgets/section/section.dart';
import '../directory/directory_page.dart';
import '../upload/upload_screen.dart';

/// What to tell someone about [failure].
String authFailureText(AuthFailure failure) => switch (failure) {
      AuthFailure.badLink => 'That sign-in link has expired or was already used. Send yourself a new one.',
      AuthFailure.network => "Couldn't reach Uiverse. Check your connection and try again.",
      AuthFailure.refused => "Sign-in didn't complete. Try again.",
      AuthFailure.browser => "Couldn't open a browser on this device.",
      AuthFailure.device => "This device couldn't store your session securely.",
    };

/// `/sign-in`: email link, Google and Apple. All three leave the app and come
/// back through a `uiverse://auth` link, so the screen mostly waits.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  bool _invalid = false;

  AuthNotifier get _auth => ref.read(authProvider.notifier);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    final email = _email.text.trim();
    final valid = RegExp(r'^\S+@\S+\.\S+$').hasMatch(email);
    setState(() => _invalid = !valid);
    if (valid) _auth.sendMagicLink(email);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if ((prev?.waiting ?? false) && !next.waiting && next.signedIn) context.go(Routes.me);
    });
    final AuthState auth = ref.watch(authProvider);
    return NarrowPage(
      children: [
        const PageHeader(
          title: 'Sign in',
          sub: 'Keep your saves and boards on every device. No password — we email you a link.',
        ),
        const SizedBox(height: 32),
        if (ref.watch(apiProvider) == null)
          const _Note("Accounts aren't switched on for this build yet.")
        else ...[
          if (auth.failure case final AuthFailure failure) ...[
            _Note(authFailureText(failure), error: true),
            const SizedBox(height: 16),
          ],
          if (auth.waiting) _waiting(auth) else _form(),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _waiting(AuthState auth) {
    final c = context.ui;
    final String? sentTo = auth.sentTo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sentTo == null ? 'Waiting for your browser' : 'Check your inbox',
          style: UiText.mono(14, bold: true, color: c.text),
        ),
        const SizedBox(height: 8),
        Text(
          sentTo == null
              ? 'Finish signing in there. It brings you back here.'
              : 'We sent a sign-in link to $sentTo. It works once and expires in 5 minutes.',
          style: UiText.body.copyWith(color: c.text2),
        ),
        const SizedBox(height: 16),
        BoxButton(sentTo == null ? 'Cancel' : 'Use a different email', onTap: _auth.cancel),
      ],
    );
  }

  Widget _form() {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Email', style: UiText.mono(13, bold: true, color: c.text)),
        const SizedBox(height: 10),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.send,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onSubmitted: (_) => _send(),
          style: UiText.mono(14, color: c.text),
          cursorColor: c.text,
          decoration: const InputDecoration(
            hintText: 'you@example.com',
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11.5),
          ),
        ),
        if (_invalid) ...[
          const SizedBox(height: 8),
          const _Note('Enter a valid email address.', error: true),
        ],
        const SizedBox(height: 12),
        BoxButton('Email me a sign-in link', onTap: _send, accent: true, height: 44),
        const SizedBox(height: 8),
        Text(
          'The link signs you in once and works for 5 minutes.',
          style: UiText.small.copyWith(color: c.text3),
        ),
        const SizedBox(height: 16),
        const DividerWithText('or'),
        const SizedBox(height: 8),
        BoxButton('Continue with Google', onTap: () => _auth.startOAuth(OAuthProvider.google)),
        BoxButton('Continue with Apple', onTap: () => _auth.startOAuth(OAuthProvider.apple)),
        const SizedBox(height: 16),
        Text('We use your email only to sign you in.', style: UiText.small.copyWith(color: c.text3)),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: LinkInk('Privacy policy', onTap: () => context.go(Routes.legal('privacy'))),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Semantics(
      liveRegion: error,
      child: Text(text, style: UiText.body.copyWith(color: error ? c.text : c.text2)),
    );
  }
}
