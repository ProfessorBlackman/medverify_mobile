import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medverify_mobile/screens/feedback_screen.dart';
import 'package:medverify_mobile/screens/how_it_works_screen.dart';
import 'package:medverify_mobile/screens/splash_screen.dart';
import 'package:medverify_mobile/utils/globals.dart';
import 'package:provider/provider.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This must be called before any Hive operation.
  await LocalDatabase.instance.init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://b9d4cac4039c29c995a2cacfe4f0588a@o4506223513239552.ingest.us.sentry.io/4510612957954048';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          Provider(create: (_) => VerificationService()),
        ],
        child: SentryWidget(child: const DrugCheckerApp()),
      ),
    ),
  );

  // Initialize your FCM helper
  await FirebaseApi().initNotifications();
}

class DrugCheckerApp extends StatelessWidget {
  const DrugCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrugChecker',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/manual': (context) => const ManualEntryScreen(),
        '/results': (context) => const ResultsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/info': (context) => const InfoHubScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/how_it_works': (context) => const HowItWorksScreen(),
      },
    );
  }
}
