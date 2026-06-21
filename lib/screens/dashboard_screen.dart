import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/verification_result.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getStatusText(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
      case VerificationStatus.valid:
        return 'Verified';
      case VerificationStatus.nearExpiry:
        return 'Nearing Expiry';
      default:
        return 'Unverified';
    }
  }

  Color _getStatusColor(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
      case VerificationStatus.valid:
        return AppTheme.primaryGreen;
      case VerificationStatus.nearExpiry:
        return AppTheme.warningOrange;
      default:
        return AppTheme.warningRed;
    }
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(),
                  const CustomSearchBar(),
                  const ScanCard(),
                  const SizedBox(height: 8),
                  const VerifyProductCard(),
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
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      final recentScans = provider.scanHistory.take(3).toList();
                      if (recentScans.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No recent scans to show.'),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentScans.length,
                          itemBuilder: (context, index) {
                            final scan = recentScans[index];
                            final statusText = _getStatusText(scan.status);
                            final statusColor = _getStatusColor(scan.status);
                            return RecentScanItem(
                              name: scan.productName ?? 'Unknown Product',
                              status: statusText,
                              time: scan.scannedAt != null
                                  ? DateFormat('MMM d, h:mm a')
                                      .format(scan.scannedAt!)
                                  : 'N/A',
                              isSafe: statusText == 'Verified',
                              imageUrl: scan.imageUrl,
                              statusColor: statusColor,
                              onTap: () {
                                Navigator.pushNamed(context, '/results',
                                    arguments: scan);
                              },
                            );
                          },
                        ),
                      );
                    },
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
