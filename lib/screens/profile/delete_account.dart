import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../state/auth.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/box_button.dart';
import '../../widgets/core/ink_box.dart';

/// Permanent account deletion. Typing the address is the confirmation: it can't
/// be done by accident, and after a fresh sign-in it shows which account this is.
class DeleteAccount extends ConsumerStatefulWidget {
  const DeleteAccount({super.key, required this.email});

  final String email;

  @override
  ConsumerState<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends ConsumerState<DeleteAccount> {
  final TextEditingController _typed = TextEditingController();
  bool _open = false;
  bool _deleting = false;
  DeleteResult? _result;

  bool get _matches => _typed.text.trim().toLowerCase() == widget.email.toLowerCase();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_matches || _deleting) return;
    setState(() => _deleting = true);
    final result = await ref.read(authProvider.notifier).deleteAccount();
    if (!mounted) return;
    if (result == DeleteResult.deleted) {
      context.go(Routes.home);
      return;
    }
    setState(() {
      _deleting = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return InkBox(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete account', style: UiText.mono(13, bold: true, color: c.text)),
          const SizedBox(height: 8),
          Text(
            'Deletes your account, your saves, boards and notes from our servers for good. Sign-in '
            'links already sent stop working. Nothing can be recovered afterwards.',
            style: UiText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: 12),
          if (_open) ..._confirm() else BoxButton('Delete my account', onTap: () => setState(() => _open = true)),
        ],
      ),
    );
  }

  List<Widget> _confirm() {
    final c = context.ui;
    return [
      Text('Type your email address to confirm', style: UiText.mono(13, color: c.text)),
      const SizedBox(height: 10),
      TextField(
        controller: _typed,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        onChanged: (_) => setState(() {}),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: UiText.mono(14, color: c.text),
        cursorColor: c.text,
        decoration: InputDecoration(
          hintText: widget.email,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11.5),
        ),
      ),
      if (_result case final DeleteResult result) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            result == DeleteResult.needsFreshSignIn
                ? "For safety, deleting needs a sign-in from the last hour. You'll come back here afterwards."
                : "The account couldn't be deleted just now. Try again in a moment.",
            style: UiText.body.copyWith(color: c.text),
          ),
        ),
      ],
      const SizedBox(height: 12),
      if (_result == DeleteResult.needsFreshSignIn)
        BoxButton('Sign in again', onTap: () => context.go(Routes.signIn), accent: true)
      else if (_matches)
        BoxButton(_deleting ? 'Deleting…' : 'Delete permanently', onTap: _delete, accent: true),
      BoxButton('Cancel', onTap: () => setState(() {
        _open = false;
        _result = null;
        _typed.clear();
      })),
    ];
  }
}
