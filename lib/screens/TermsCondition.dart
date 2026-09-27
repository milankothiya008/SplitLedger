import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  static const _sections = [
    (
      '1. Usage',
      'SmartSpend is designed for personal budgeting and expense tracking only. Commercial use without permission is prohibited.',
    ),
    (
      '2. Privacy',
      'We value your privacy. All data collected is securely stored and will not be shared with third parties without your consent.',
    ),
    (
      '3. Account security',
      'You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account.',
    ),
    (
      '4. Limitation of liability',
      'We are not liable for any financial losses or damages resulting from the use of this app.',
    ),
    (
      '5. Changes to terms',
      'We reserve the right to modify these terms at any time. Updated terms will be posted within the app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = TextStyle(color: scheme.onSurfaceVariant, height: 1.5, fontSize: 15);
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: PageListView(
        maxWidth: 720,
        bottom: 32,
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome to SmartSpend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  'Please read these terms carefully before using the app. By accessing or using SmartSpend, you agree to be bound by them.',
                  style: body,
                ),
                for (final s in _sections) ...[
                  const SizedBox(height: 20),
                  Text(s.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(s.$2, style: body),
                ],
                const SizedBox(height: 24),
                Text('Thank you for using SmartSpend!',
                    style: TextStyle(fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
