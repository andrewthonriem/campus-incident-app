import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/account_profile_error_screen.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/incident_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final requiredValues = [
      options.apiKey,
      options.appId,
      options.messagingSenderId,
      options.projectId,
    ];
    if (requiredValues.any(
      (value) => value.trim().isEmpty || value.contains('REPLACE_ME'),
    )) {
      throw StateError(
        'Firebase is not configured for this platform. Run flutterfire '
        'configure and select this platform, then restart the app.',
      );
    }
    await Firebase.initializeApp(
      options: options,
    );
  } on Object catch (error) {
    runApp(FirebaseSetupApp(error: error.toString()));
    return;
  }
  runApp(const CampusIncidentApp());
}

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(IncidentRepository()),
          update: (_, auth, incidents) => incidents!
            ..bindUser(
              auth.status == AuthStatus.signedIn ? auth.user : null,
            ),
        ),
      ],
      child: MaterialApp(
        title: 'Campus Fix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Fix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FirebaseSetupScreen(error: error),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (status) {
        AuthStatus.unknown => const SplashScreen(),
        AuthStatus.signedOut => const LoginScreen(),
        AuthStatus.requiresEmailVerification => const EmailVerificationScreen(),
        AuthStatus.profileUnavailable => const AccountProfileErrorScreen(),
        AuthStatus.signedIn => const HomeShell(),
      },
    );
  }
}
