import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const _supportEmail = 'codecrafters79@gmail.com';

  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AppData>().user;
    final body = 'Name: ${user?.displayName ?? ''}\n'
        'Email: ${user?.email ?? ''}\n\n'
        '${_message.text.trim()}';
    // Encode each component so "&", "#" or newlines in the message survive.
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent(_subject.text.trim())}&body=${Uri.encodeComponent(body)}',
    );

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!mounted) return;

    if (!launched) {
      showSnack(context, 'No email app found. Please write to $_supportEmail.', error: true);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message ready'),
        content: const Text('Your request is open in your email app. Send it and we\'ll get back to you soon.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    _subject.clear();
    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & contact')),
      body: Form(
        key: _formKey,
        child: PageListView(
          maxWidth: 640,
          bottom: 32,
          children: [
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: scheme.primary, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tell us what went wrong or what you need. Your message opens in your email app, '
                      'addressed to $_supportEmail.',
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _subject,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter a subject' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'How can we help?', alignLabelWithHint: true),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Please describe your issue' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text('Send message'),
            ),
          ],
        ),
      ),
    );
  }
}
