import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/screens/AboutUs.dart';
import 'package:SmartSpend/screens/FAQs.dart';
import 'package:SmartSpend/screens/Help.dart';
import 'package:SmartSpend/screens/TermsCondition.dart';
import 'package:SmartSpend/theme/app_theme.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _reset(BuildContext context) async {
    final first = await confirm(
      context,
      title: 'Reset all data?',
      message: 'This permanently deletes all your expenses and budgets. Your account and profile stay. '
          'This cannot be undone.',
      confirmLabel: 'Continue',
      destructive: true,
    );
    if (!first || !context.mounted) return;
    final second = await confirm(
      context,
      title: 'Are you absolutely sure?',
      message: 'Every expense and budget you have saved will be erased.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!second || !context.mounted) return;
    try {
      await context.read<AppData>().deleteAllData();
      if (context.mounted) showSnack(context, 'All expenses and budgets were deleted');
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not delete your data. Please try again.', error: true);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await confirm(
      context,
      title: 'Log out?',
      message: 'You can sign back in any time with the same Google account.',
      confirmLabel: 'Log out',
    );
    if (!ok || !context.mounted) return;
    // Return to the root; the Wrapper swaps to the Login screen on sign-out.
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AppData.signOut();
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final scheme = Theme.of(context).colorScheme;

    Widget tile(IconData icon, String title, VoidCallback onTap, {Color? color, bool chevron = true}) => ListTile(
          leading: Icon(icon, color: color ?? scheme.primary),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
          trailing: chevron ? const Icon(Icons.chevron_right_rounded) : null,
          onTap: onTap,
        );

    Widget group(List<Widget> tiles) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const Divider(indent: 56), tiles[i]],
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageListView(
        maxWidth: 640,
        bottom: 32,
        children: [
          const SectionHeader('Appearance', top: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                    ],
                    selected: {theme.mode},
                    onSelectionChanged: (s) => theme.mode = s.first,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Support'),
          group([
            tile(Icons.help_outline_rounded, 'Help & contact', () => _open(context, const HelpPage())),
            tile(Icons.quiz_outlined, 'FAQs', () => _open(context, const FaqsPage())),
          ]),
          const SectionHeader('About'),
          group([
            tile(Icons.policy_outlined, 'Terms & Conditions', () => _open(context, const TermsAndConditionsPage())),
            tile(Icons.info_outline_rounded, 'About SmartSpend', () => _open(context, const AboutUsPage())),
          ]),
          const SectionHeader('Account'),
          group([
            tile(Icons.delete_forever_outlined, 'Reset all data', () => _reset(context),
                color: AppColors.danger, chevron: false),
            tile(Icons.logout_rounded, 'Log out', () => _logout(context), color: AppColors.danger, chevron: false),
          ]),
        ],
      ),
    );
  }
}
