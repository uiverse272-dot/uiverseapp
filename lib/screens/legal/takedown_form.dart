import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/box_button.dart';
import '../../widgets/core/ink_box.dart';
import '../../widgets/core/ui_chip.dart';
import '../../widgets/forms/form_parts.dart';

/// Messages per server error code.
const Map<String, String> _errors = {
  'domain': "Enter the site's domain, like example.com.",
  'name': 'Add your name.',
  'email': 'Add an email address we can reply to.',
  'confirm': "Confirm you're the owner or authorized to act for them.",
};

/// The removal request under `/legal/takedown`. Nothing without a backend.
class TakedownForm extends ConsumerStatefulWidget {
  const TakedownForm({super.key});

  @override
  ConsumerState<TakedownForm> createState() => _TakedownFormState();
}

class _TakedownFormState extends ConsumerState<TakedownForm> {
  final TextEditingController _domain = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _details = TextEditingController();
  bool _agent = false;
  bool _confirm = false;
  bool _sending = false;
  String? _field;
  String? _problem;
  ({String ref, int held, String domain, String email})? _sent;

  @override
  void dispose() {
    _domain.dispose();
    _name.dispose();
    _email.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _send(UiverseApi api) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _field = null;
      _problem = null;
    });
    final String domain = _domain.text.trim();
    final String email = _email.text.trim();
    try {
      final result = await api.requestTakedown(TakedownRequest(
        domain: domain,
        name: _name.text.trim(),
        email: email,
        agent: _agent,
        details: _details.text.trim(),
        confirm: _confirm,
      ));
      if (mounted) setState(() => _sent = (ref: result.ref, held: result.held, domain: domain, email: email));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (_errors.containsKey(e.code)) {
          _field = e.code;
        } else if (e.status == 429) {
          _problem = 'Too many requests from this network — try again in ${e.minutes ?? 60} minutes.';
        } else {
          _problem = "The request couldn't be sent just now. Please try again in a few minutes.";
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _another() => setState(() {
        _domain.clear();
        _name.clear();
        _email.clear();
        _details.clear();
        _agent = false;
        _confirm = false;
        _sent = null;
      });

  String? _errorFor(String field) => _field == field ? _errors[field] : null;

  @override
  Widget build(BuildContext context) {
    final UiverseApi? api = ref.watch(apiProvider);
    if (api == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 672),
      child: _sent == null ? _form(api) : _received(),
    );
  }

  Widget _form(UiverseApi api) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Domain to remove',
          controller: _domain,
          hint: 'Covers the domain and its subdomains.',
          keyboardType: TextInputType.url,
          error: _errorFor('domain'),
        ),
        LabeledField(label: 'Your name', controller: _name, error: _errorFor('name')),
        LabeledField(
          label: 'Email',
          controller: _email,
          hint: 'An address at the domain itself is the quickest to verify.',
          keyboardType: TextInputType.emailAddress,
          error: _errorFor('email'),
        ),
        Text('You are', style: UiText.mono(13, bold: true, color: c.text)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            UiChip('The owner or operator', onTap: () => setState(() => _agent = false), on: !_agent, selected: !_agent),
            UiChip('Authorized to act for them', onTap: () => setState(() => _agent = true), on: _agent, selected: _agent),
          ],
        ),
        const SizedBox(height: 16),
        LabeledField(label: 'Anything else', controller: _details, maxLines: 3),
        ConfirmBox(
          label: "I own or operate this site, or I'm authorized to act for whoever does, and the "
              'details above are accurate.',
          value: _confirm,
          onChanged: (v) => setState(() => _confirm = v),
        ),
        if (_errorFor('confirm') case final String error) FormError(error),
        if (_problem case final String problem) ...[const SizedBox(height: 8), FormError(problem)],
        const SizedBox(height: 16),
        BoxButton(_sending ? 'Sending…' : 'Send removal request', onTap: () => _send(api), accent: true, height: 44),
      ],
    );
  }

  Widget _received() {
    final c = context.ui;
    final sent = _sent!;
    return InkBox(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Request received', style: UiText.mono(14, bold: true, color: c.text)),
          const SizedBox(height: 4),
          Text(sent.ref, style: UiText.small.copyWith(color: c.text3)),
          const SizedBox(height: 8),
          Text(
            sent.held == 0
                ? "Nothing from ${sent.domain} is in the index right now. We'll still block it, so it's never captured."
                : 'We hold ${sent.held} ${sent.held == 1 ? 'capture' : 'captures'} from ${sent.domain}. Everything '
                    'from the domain will be removed, and it won\'t be captured again.',
            style: UiText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll confirm at ${sent.email} within 5 working days. Quote the reference if you write to us.",
            style: UiText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: 12),
          BoxButton('Send another request', onTap: _another),
        ],
      ),
    );
  }
}
