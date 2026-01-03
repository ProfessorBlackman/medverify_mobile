import 'package:flutter/material.dart';
import 'package:medverify_mobile/screens/feedback_screen.dart';
import 'package:medverify_mobile/screens/how_it_works_screen.dart';
import 'package:provider/provider.dart';
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
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://b9d4cac4039c29c995a2cacfe4f0588a@o4506223513239552.ingest.us.sentry.io/4510612957954048';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const DrugCheckerApp())),
  );
  // TODO: Remove this line after sending the first sample event to sentry.
  await Sentry.captureException(Exception('This is a sample exception.'));
}

class DrugCheckerApp extends StatelessWidget {
  const DrugCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        Provider(create: (_) => VerificationService()),
      ],
      child: MaterialApp(
        title: 'DrugChecker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/scanner': (context) => const ScannerScreen(),
          '/manual_entry': (context) => const ManualEntryScreen(),
          '/results': (context) => const ResultsScreen(),
          '/history': (context) => const HistoryScreen(),
          '/info': (context) => const InfoHubScreen(),
          '/feedback': (context) => const FeedbackScreen(),
          '/how_it_works': (context) => const HowItWorksScreen(),
        },
      ),
    );
  }
}
