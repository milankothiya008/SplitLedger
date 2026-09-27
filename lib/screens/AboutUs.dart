import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = TextStyle(color: scheme.onSurfaceVariant, height: 1.5, fontSize: 15);
    const features = [
      (Icons.bolt_rounded, 'Fast expense tracking with 29 categories'),
      (Icons.savings_outlined, 'Overall and category budgets with live tracking'),
      (Icons.pie_chart_outline_rounded, 'Category breakdowns and spending trends'),
      (Icons.dark_mode_outlined, 'Light and dark themes'),
      (Icons.lock_outline_rounded, 'Secure Google sign-in'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('About SmartSpend')),
      body: PageListView(
        maxWidth: 640,
        bottom: 32,
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/images/logo.jpg', width: 80, height: 80),
                ),
                const SizedBox(height: 14),
                const Text('SmartSpend', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Your personal finance buddy', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Text(
                  'SmartSpend helps you track expenses, manage budgets and understand your spending habits, effortlessly.',
                  textAlign: TextAlign.center,
                  style: body,
                ),
              ],
            ),
          ),
          const SectionHeader('Why SmartSpend?'),
          AppCard(
            child: Column(
              children: [
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(f.$1, color: scheme.primary, size: 22),
                      const SizedBox(width: 14),
                      Expanded(child: Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ]),
                  ),
              ],
            ),
          ),
          const SectionHeader('Our mission'),
          AppCard(
            child: Text(
              'To empower individuals to make smarter financial decisions with simple, effective and beautiful tools.',
              style: body,
            ),
          ),
        ],
      ),
    );
  }
}
