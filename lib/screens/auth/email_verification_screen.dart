import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  Future<void> _resend(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final sent = await auth.resendVerificationEmail();
    if (!context.mounted) return;
    _showMessage(
      context,
      sent
          ? 'Verification email sent. Check your inbox and spam folder.'
          : auth.error ?? 'Could not send the verification email.',
      isError: !sent,
    );
  }

  Future<void> _check(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerification();
    if (!context.mounted || verified) return;
    _showMessage(
      context,
      auth.error ??
          'Your email is not verified yet. Check your inbox and try again.',
      isError: auth.error != null,
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
  }

  void _showMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? 'your ALU email';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verify your ALU email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to $email. Verify your address '
                    'before accessing campus reports.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isBusy ? null : () => _check(context),
                    child: auth.isBusy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text("I've verified my email"),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: auth.isBusy ? null : () => _resend(context),
                    child: const Text('Resend verification email'),
                  ),
                  TextButton(
                    onPressed: auth.isBusy ? null : () => _signOut(context),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
