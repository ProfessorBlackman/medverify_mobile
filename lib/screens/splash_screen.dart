import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/device_auth_service.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  double _progress = 0.0;
  String _loadingText = 'Verifying device identity...';
  String _version = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadVersion();
    _startLoading();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() =>
          _version = 'v${info.version} (Build ${info.buildNumber})');
    }
  }

  Future<void> _startLoading() async {
    try {
      // Step 1 — device auth (network call; main source of latency)
      if (mounted) {
        setState(() {
          _progress = 0.05;
          _loadingText = 'Verifying device identity...';
        });
      }
      await DeviceAuthService.instance.ensureRegistered();

      // Step 2 — load scan history from local storage
      if (!mounted) return;
      setState(() {
        _progress = 0.7;
        _loadingText = 'Loading your scan history...';
      });
      await context.read<AppProvider>().init();

      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _loadingText = 'Ready!';
      });

      // Brief pause so the completed bar is visible before navigating.
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (_) {
      // Auth or storage failure — navigate anyway. Individual screens
      // surface errors when they need network or local data.
    }

    if (mounted) _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Decorative blurs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: AppTheme.primaryGreen,
                        size: 64,
                      ),
                      // Scan line animation
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, _) {
                          return Transform.translate(
                            offset: Offset(0, _scanAnimation.value * 64),
                            child: Container(
                              height: 64,
                              width: 128,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.primaryGreen
                                        .withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Titles
                Text(
                  'MedVerify',
                  style: GoogleFonts.publicSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify Safety. Trust Your Meds.',
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(flex: 3),
                // Loading section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _loadingText,
                            style: GoogleFonts.publicSans(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: GoogleFonts.publicSans(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.security,
                      color: AppTheme.secondaryText,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Powered by FDA Ghana Data',
                      style: GoogleFonts.publicSans(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _version,
                  style: GoogleFonts.publicSans(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
