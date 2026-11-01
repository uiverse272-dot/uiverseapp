import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/box_button.dart';
import '../../widgets/core/ink_box.dart';
import '../../widgets/core/ui_chip.dart';
import '../../widgets/forms/form_parts.dart';
import '../../widgets/section/section.dart';
import '../directory/directory_page.dart';

/// Tags a find can carry: slug and label, same list as the web's `FIND_TAGS`.
const List<(String, String)> kFindTags = [
  ('interface', 'Interface'),
  ('motion', 'Motion'),
  ('3d', '3D'),
  ('typography', 'Typography'),
  ('branding', 'Branding'),
  ('illustration', 'Illustration'),
  ('landing-page', 'Landing page'),
  ('mobile', 'Mobile app'),
  ('generative', 'Generative'),
];

const int _maxTags = 4;

/// Messages per server error code.
const Map<String, String> _errors = {
  'title': 'Give the piece a title.',
  'creator': 'Add your name, as it should be credited.',
  'email': 'Add an email address we can reply to.',
  'url': 'Add a link to the work, starting with https://.',
  'imageUrl': 'Add a link to an image, starting with https://.',
  'creatorUrl': 'Your page should be a link starting with https://, or left empty.',
  'confirm': 'Confirm the work is yours to share.',
};

/// `/finds/submit`: a designer sends in their own work for review.
class FindsSubmitScreen extends ConsumerStatefulWidget {
  const FindsSubmitScreen({super.key});

  @override
  ConsumerState<FindsSubmitScreen> createState() => _FindsSubmitScreenState();
}

class _FindsSubmitScreenState extends ConsumerState<FindsSubmitScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _creator = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _creatorUrl = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final Set<String> _tags = {};
  bool _confirm = false;
  bool _sending = false;
  String? _field;
  String? _problem;
  String? _sentTo;

  List<TextEditingController> get _controllers => [_title, _creator, _email, _url, _imageUrl, _creatorUrl, _note];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send(UiverseApi api) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _field = null;
      _problem = null;
    });
    try {
      await api.submitFind(FindSubmission(
        title: _title.text.trim(),
        creator: _creator.text.trim(),
        email: _email.text.trim(),
        url: _url.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        creatorUrl: _creatorUrl.text.trim(),
        tags: _tags.toList(),
        note: _note.text.trim(),
        confirm: _confirm,
      ));
      if (mounted) setState(() => _sentTo = _email.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (_errors.containsKey(e.code)) {
          _field = e.code;
        } else if (e.status == 429) {
          _problem = 'Too many submissions from this network — try again in ${e.minutes ?? 60} minutes.';
        } else {
          _problem = "The submission couldn't be sent just now. Please try again in a few minutes.";
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _another() => setState(() {
        for (final c in _controllers) {
          c.clear();
        }
        _tags.clear();
        _confirm = false;
        _sentTo = null;
      });

  void _toggleTag(String slug) => setState(() {
        if (!_tags.remove(slug) && _tags.length < _maxTags) _tags.add(slug);
      });

  String? _errorFor(String field) => _field == field ? _errors[field] : null;

  @override
  Widget build(BuildContext context) {
    final UiverseApi? api = ref.watch(apiProvider);
    final String? sentTo = _sentTo;
    return NarrowPage(
      children: [
        const PageHeader(
          title: 'Submit your work',
          sub: 'We look at every submission. If yours is picked it appears in Finds with your name '
              'and a link to the original.',
        ),
        const SizedBox(height: 32),
        if (api == null)
          _Unavailable()
        else if (sentTo != null)
          _Received(email: sentTo, onAnother: _another)
        else
          ..._form(api),
        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> _form(UiverseApi api) {
    final c = context.ui;
    return [
      LabeledField(label: 'Title of the piece', controller: _title, error: _errorFor('title')),
      LabeledField(label: 'Your name', controller: _creator, error: _errorFor('creator')),
      LabeledField(
        label: 'Email',
        controller: _email,
        hint: "Only so we can reply; it's never shown.",
        keyboardType: TextInputType.emailAddress,
        error: _errorFor('email'),
      ),
      LabeledField(
        label: 'Link to the work',
        controller: _url,
        hint: 'Where it lives: Dribbble, Behance, X, your site or a live demo.',
        keyboardType: TextInputType.url,
        error: _errorFor('url'),
      ),
      LabeledField(
        label: 'Link to an image',
        controller: _imageUrl,
        hint: 'A direct link to a PNG, JPG or WebP we may show, ideally 1200px wide or more.',
        keyboardType: TextInputType.url,
        error: _errorFor('imageUrl'),
      ),
      LabeledField(
        label: 'Your page',
        controller: _creatorUrl,
        hint: "Portfolio or profile, for the credit. Leave it empty to credit the work's link.",
        keyboardType: TextInputType.url,
        error: _errorFor('creatorUrl'),
      ),
      Text('What is it?', style: UiText.mono(13, bold: true, color: c.text)),
      const SizedBox(height: 6),
      Text('Pick up to four.', style: UiText.small.copyWith(color: c.text3)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: [
          for (final (String slug, String name) in kFindTags)
            UiChip(name, onTap: () => _toggleTag(slug), on: _tags.contains(slug), toggled: _tags.contains(slug)),
        ],
      ),
      const SizedBox(height: 16),
      LabeledField(label: 'Anything else', controller: _note, maxLines: 3),
      ConfirmBox(
        label: 'I made this work, or lead the team that did, and I allow Uiverse to show the image, '
            'credited to me, with a link to the original.',
        value: _confirm,
        onChanged: (v) => setState(() => _confirm = v),
      ),
      if (_errorFor('confirm') case final String error) FormError(error),
      if (_problem case final String problem) ...[const SizedBox(height: 8), FormError(problem)],
      const SizedBox(height: 16),
      BoxButton(_sending ? 'Sending…' : 'Send for review', onTap: () => _send(api), accent: true, height: 44),
    ];
  }
}

class _Unavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
        "Submissions aren't switched on for this build yet.",
        style: UiText.body.copyWith(color: context.ui.text2),
      );
}

class _Received extends StatelessWidget {
  const _Received({required this.email, required this.onAnother});

  final String email;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return InkBox(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Submission received', style: UiText.mono(14, bold: true, color: c.text)),
          const SizedBox(height: 8),
          Text(
            'Thanks. We look at every submission and will write to $email either way.',
            style: UiText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: 12),
          BoxButton('Submit another piece', onTap: onAnother),
        ],
      ),
    );
  }
}
