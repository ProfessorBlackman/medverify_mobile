import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medverify_mobile/providers/app_provider.dart';
import 'package:medverify_mobile/theme.dart';
import 'package:provider/provider.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
         iconTheme: const IconThemeData(color: AppTheme.textLight),
         bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildSectionHeader('ABOUT & FEEDBACK'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.star_rate_rounded,
                    title: 'Rate the App',
                    subtitle: 'Love using the app? Let us know!',
                    iconColor: Colors.orange,
                    iconBgColor: Colors.orange[50]!,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rating feature coming soon!')),
                      );
                    },
                    isFirst: true,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.share,
                    title: 'Share App',
                    iconColor: Colors.grey[600]!,
                    iconBgColor: Colors.grey[50]!,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing feature coming soon!')),
                      );
                    },
                  ),
                   _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: 'About MedVerify',
                    iconColor: Colors.grey[600]!,
                    iconBgColor: Colors.grey[50]!,
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                   _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    iconColor: Colors.grey[600]!,
                    iconBgColor: Colors.grey[50]!,
                    onTap: () {
                       Navigator.pushNamed(context, '/privacy');
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),
             const SizedBox(height: 32),
            _buildSectionHeader('DATA MANAGEMENT'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.history,
                    title: 'Scan History',
                    subtitle: 'Manage your past scans',
                    iconColor: Colors.grey[600]!,
                    iconBgColor: Colors.grey[50]!,
                    onTap: () {
                      Navigator.pushNamed(context, '/history');
                    },
                    isFirst: true,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.storage,
                    title: 'Offline Database',
                    subtitle: 'Last updated: 2 days ago', // Could be dynamic
                    iconColor: Colors.grey[600]!,
                    iconBgColor: Colors.grey[50]!,
                    onTap: () {},
                  ),
                  _buildDivider(),
                    _buildSettingItem(
                    icon: Icons.delete_outline,
                    title: 'Clear All Data',
                    titleColor: Colors.red[600],
                    iconColor: Colors.red[500]!,
                    iconBgColor: Colors.red[50]!,
                    onTap: () {
                      _showClearDataDialog(context);
                    },
                     isLast: true,
                     showChevron: false
                  ),
                ],
              ),
            ),
             const SizedBox(height: 32),
             Text(
              'FDA Ghana Verifier v2.1.0',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: Colors.grey[500],
              ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF61896f),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    Color? titleColor,
    bool isFirst = false,
    bool isLast = false,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppTheme.textLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      // const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: const Color(0xFF61896f),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 0,
      endIndent: 0,
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete your scan history and reset the app data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
               Provider.of<AppProvider>(context, listen: false).clearHistory();
              Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}
