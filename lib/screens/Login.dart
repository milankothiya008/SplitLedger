import 'package:SmartSpend/theme/app_theme.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _busy = false;

  /// Signs in with Google. The Wrapper reacts to the auth change and shows the
  /// app, so no navigation happens here.
  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        // Web: use Firebase's Google popup (no google_sign_in client ID needed)
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // User cancelled
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup-closed-by-user' && e.code != 'cancelled-popup-request' && mounted) {
        showSnack(context, 'Sign-in failed: ${e.message ?? e.code}', error: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Sign-in failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kWideBreakpoint;
    final form = _SignInPanel(busy: _busy, onSignIn: _login, showLogo: !wide);

    if (!wide) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: form),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: form),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInPanel extends StatelessWidget {
  const _SignInPanel({required this.busy, required this.onSignIn, required this.showLogo});

  final bool busy;
  final VoidCallback onSignIn;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: showLogo ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (showLogo) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset('assets/images/logo.jpg', width: 112, height: 112, fit: BoxFit.cover),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          showLogo ? 'SmartSpend' : 'Welcome to SmartSpend',
          textAlign: showLogo ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Track expenses, set budgets and see where your money goes.',
          textAlign: showLogo ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : onSignIn,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 54),
              backgroundColor: Theme.of(context).cardTheme.color,
              foregroundColor: scheme.onSurface,
            ),
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/google.png', width: 22, height: 22),
                      const SizedBox(width: 12),
                      const Text('Continue with Google'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'By continuing you agree to our Terms & Conditions.',
          textAlign: showLogo ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.receipt_long_rounded, 'Log expenses in seconds', 'Pick a category, enter the amount, done.'),
      (Icons.savings_rounded, 'Budgets that track themselves', 'Overall or per category, with alerts near the limit.'),
      (Icons.pie_chart_rounded, 'Clear insights', 'See where your money goes, by category and over time.'),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brand, Color(0xFF3F4DB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/logo.jpg', width: 44, height: 44),
            ),
            const SizedBox(width: 12),
            const Text('SmartSpend', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          const Spacer(),
          const Text(
            'Your personal\nfinance buddy.',
            style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 40),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.$1, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(f.$3, style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}
