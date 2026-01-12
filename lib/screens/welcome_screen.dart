import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medverify_mobile/screens/scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'how_it_works_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Inside your Onboarding Screen's button action:
  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              radius: 20,
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'MedVerify',
              style: GoogleFonts.publicSans(
                color: AppTheme.textLight,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              children: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      _completeOnboarding();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()),);
                    },
                    child: Text(
                      'Go to Dashboard',
                      style: GoogleFonts.publicSans(
                        color: AppTheme.secondGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Hero Image / Animation Placeholder
                Container(
                  height: 330,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset(
                      'assets/images/welcome.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                Text(
                  'Verify Your Medicine Instantly',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Don't guess with your health. Use DrugChecker to instantly check if your medication is licensed by the Food and Drugs Authority (FDA) of Ghana.",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Trust Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Powered by Official FDA Data',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _completeOnboarding();
                      MaterialPageRoute(builder: (context) => const ScannerScreen());
                      Navigator.pushReplacement(
                        context,
                          MaterialPageRoute(builder: (context) => const ScannerScreen())
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Start Scanning'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    _completeOnboarding();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HowItWorksScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Learn how it works',
                    style: GoogleFonts.publicSans(
                      color: AppTheme.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
