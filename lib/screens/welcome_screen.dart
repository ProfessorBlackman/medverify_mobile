import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medverify_mobile/screens/scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'how_it_works_screen.dart';

import 'dart:async'; // Add this import

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _agreedToTerms = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPage < _slides.length - 1) {
        _nextPage();
      } else {
        timer.cancel();
      }
    });
  }

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/images/welcome.png',
      'title': 'Verify Your Medicine Instantly',
      'description':
          "Don't guess with your health. Use MedVerify to instantly check if your medication is licensed by the Food and Drugs Authority (FDA) of Ghana.",
    },
    {
      'image': 'assets/images/instant_scanning.png',
      'title': 'Instant Verification',
      'description':
          'Quickly scan any drug barcode or QR code to check its registration status with the Ghana FDA.',
    },
    {
      'image': 'assets/images/official_fda_data.png',
      'title': 'Direct FDA Database',
      'description':
          'Access real-time information from the FDA of Ghana to ensure the medicines you buy are licensed and safe for use.',
    },
    {
      'image': 'assets/images/safer_ghana.png',
      'title': 'Build a Safer Ghana',
      'description':
          'Contribute to our database by sharing prices and purchase locations to help others find affordable and authentic drugs.',
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToLast() {
    _pageController.jumpToPage(_slides.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          if (_currentPage < _slides.length - 1)
            TextButton(
              onPressed: _skipToLast,
              child: Text(
                'Skip',
                style: GoogleFonts.publicSans(
                  color: AppTheme.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image
                         Container(
                          height: 330,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.asset(
                              _slides[index]['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          _slides[index]['title']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                              ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          _slides[index]['description']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        
                        if (index == 0) ...[
                          const SizedBox(height: 20),
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
                        ],

                        if (index == _slides.length - 1) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (value) {
                                  setState(() {
                                    _agreedToTerms = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: GoogleFonts.publicSans(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: GoogleFonts.publicSans(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryGreen
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _currentPage == _slides.length - 1
                          ? (_agreedToTerms ? _completeOnboarding : null)
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentPage == _slides.length - 1 && !_agreedToTerms ? Colors.grey[500] : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
