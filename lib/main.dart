import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medverify_mobile/screens/feedback_screen.dart';
import 'package:medverify_mobile/screens/how_it_works_screen.dart';
import 'package:medverify_mobile/screens/privacy_policy_screen.dart';
import 'package:medverify_mobile/screens/splash_screen.dart';
import 'package:medverify_mobile/services/analytics_service.dart';
import 'package:medverify_mobile/utils/globals.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_client.dart';
import 'services/device_auth_service.dart';
import 'services/file_upload_service.dart';
import 'services/multi_evidence_verification_service.dart';
import 'services/notifications_service.dart';
import 'firebase_options.dart';
import 'services/local_database.dart';
import 'theme.dart';
import 'providers/app_provider.dart';
import 'providers/verification_session_provider.dart';
import 'services/verification_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';
import 'screens/info_hub_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/verification_session_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'screens/app_settings_screen.dart';
import 'screens/about_screen.dart';

Future<void> main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 0.2;
      options.profilesSampleRate = 0.2;
    },
    appRunner: () async {
      // Infrastructure — fast, no network, must complete before runApp.
      ApiClient.instance.init();
      await LocalDatabase.instance.init();
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // Non-blocking platform work.
      FirebaseApi().initNotifications();
      AnalyticsService.instance.init();

      final prefs = await SharedPreferences.getInstance();
      final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      final appProvider = AppProvider();

      if (isFirstTime) {
        // No splash screen for first-timers. Start device auth in the
        // background while they read the welcome flow; by the time they
        // reach the dashboard, registration will have completed.
        DeviceAuthService.instance
            .ensureRegistered()
            .then((_) => appProvider.init())
            .catchError((_) {});
      }
      // For returning users, SplashScreen drives device auth and history
      // loading with a real progress bar — no blank-screen wait.

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appProvider),
            Provider(create: (_) => VerificationService()),
            Provider(create: (_) => FileUploadService()),
            Provider(create: (_) => MultiEvidenceVerificationService()),
            ChangeNotifierProvider(
                create: (_) => VerificationSessionProvider()),
          ],
          child: SentryWidget(child: DrugCheckerApp(isFirstTime: isFirstTime)),
        ),
      );
    }
  );
}

class DrugCheckerApp extends StatelessWidget {
  final bool isFirstTime;
  const DrugCheckerApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedVerify',
      navigatorKey: navigatorKey,
      navigatorObservers: [AnalyticsService.instance.observer],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => isFirstTime ? const WelcomeScreen() : const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/manual': (context) => const ManualEntryScreen(),
        '/results': (context) => const ResultsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/info': (context) => const InfoHubScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/how_it_works': (context) => const HowItWorksScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/settings': (context) => const AppSettingsScreen(),
        '/about': (context) => const AboutScreen(),
        '/verify': (context) => const VerificationSessionScreen(),
      },
    );
  }
}
