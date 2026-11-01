import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../router/routes.dart';
import '../../state/auth.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/box_button.dart';
import '../../widgets/core/ink_box.dart';
import 'delete_account.dart';

/// The account block on the profile page: who is signed in and sign-out, or
/// the offer to sign in. Nothing without a backend.
class AccountPanel extends ConsumerWidget {
  const AccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(apiProvider) == null) return const SizedBox.shrink();
    final AuthState auth = ref.watch(authProvider);
    final AccountUser? user = auth.user;
    void signIn() => context.go(Routes.signIn);
    return Padding(padding: const EdgeInsets.only(top: 32), child: _panel(context, ref, auth, user, signIn));
  }

  Widget _panel(BuildContext context, WidgetRef ref, AuthState auth, AccountUser? user, VoidCallback signIn) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user == null) ...[
                Text(
                  'Saves are kept on this device until you sign in — then they move to your '
                  'account and follow you to every device.',
                  style: UiText.body.copyWith(color: c.text2),
                ),
                const SizedBox(height: 12),
                BoxButton('Sign in', onTap: signIn, accent: true),
              ] else ...[
                Text('Signed in as ${user.email}', style: UiText.mono(14, bold: true, color: c.text)),
                const SizedBox(height: 8),
                Text(
                  auth.expired
                      ? 'Your session ended. Sign in again to keep syncing; nothing here is lost.'
                      : 'Your saves are in your account and on every device you sign in to.',
                  style: UiText.body.copyWith(color: c.text2),
                ),
                const SizedBox(height: 12),
                if (auth.expired) BoxButton('Sign in again', onTap: signIn, accent: true),
                BoxButton('Sign out', onTap: ref.read(authProvider.notifier).signOut),
              ],
            ],
          ),
        ),
        if (user != null) ...[const SizedBox(height: 16), DeleteAccount(email: user.email)],
      ],
    );
  }
}
