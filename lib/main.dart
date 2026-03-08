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
import 'services/notifications_service.dart';
import 'firebase_options.dart';
import 'services/local_database.dart';
import 'theme.dart';
import 'providers/app_provider.dart';
import 'services/verification_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';
import 'screens/info_hub_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'screens/app_settings_screen.dart';
import 'screens/about_screen.dart';

Future<void> main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://b9d4cac4039c29c995a2cacfe4f0588a@o4506223513239552.ingest.us.sentry.io/4510612957954048';
      options.tracesSampleRate = 0.2;
      options.profilesSampleRate = 0.2;
    },
    appRunner: () async {
      // Heavy init here, after Flutter is ready to render
      await LocalDatabase.instance.init();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // Fire off heavy network and platform-channel requests asynchronously
      // without blocking the rendering pipeline.
      FirebaseApi().initNotifications();
      AnalyticsService.instance.init();

      final prefs = await SharedPreferences.getInstance();
      final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
            Provider(create: (_) => VerificationService()),
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
      title: 'DrugChecker',
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
      },
    );
  }
}
