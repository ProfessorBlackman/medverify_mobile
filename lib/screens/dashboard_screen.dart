import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              // Space for bottom nav
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(),
                  const CustomSearchBar(),
                  const ScanCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Quick Actions',
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.history,
                            title: 'View History',
                            subtitle: 'Review past scans',
                            iconColor: Colors.blue[600]!,
                            iconBgColor: Colors.blue[50]!,
                            onTap: () {
                              Navigator.pushNamed(context, '/history');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.menu_book,
                            title: 'Info Hub',
                            subtitle: 'Safety tips & alerts',
                            iconColor: Colors.orange[600]!,
                            iconBgColor: Colors.orange[50]!,
                            onTap: () {
                              Navigator.pushNamed(context, '/info');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Scans',
                          style: GoogleFonts.publicSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/history');
                          },
                          child: Text(
                            'View all',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        RecentScanItem(
                          name: 'Panadol Extra',
                          status: 'Safe',
                          time: 'Verified today, 10:23 AM',
                          isSafe: true,
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuALsqbI4fGCGMFGnmwV4e3w_LO3FKu981EIl_c2fN1sN00hBzmP-zWanWzpuLKQGyr2_dEKxAk1SXjGYpwkbtrZqs4cMPOytDh1X-KVYuTc3nGdwuo9KLxMqc9N15DpUpaHq68V36gutclmQ480XYLTHhavp7ZY1iWYCd3RgRvOe8ObbnmoAlyF34fEGhDuzHGSBRapnwbT93M_ydH4CHgcIWJ8aeYiLTc6oYk5Aw_GyVrNnUJPxjkq49MpRQLuX_ktFIq58kJf858',
                        ),
                        SizedBox(height: 8),
                        RecentScanItem(
                          name: 'Unknown Amoxicillin',
                          status: 'Unverified',
                          time: 'Scanned yesterday',
                          isSafe: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }
}
