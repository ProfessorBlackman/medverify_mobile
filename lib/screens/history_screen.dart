import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/verification_result.dart';
import '../theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        automaticallyImplyLeading: false, // Hide back button if using BottomNav
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final history = provider.scanHistory;

          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No scans yet'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search scanned drugs...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Filter Chips (Visual only for now)
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('All'),
                      selected: true,
                      onSelected: null,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Approved'),
                      selected: false,
                      onSelected: null,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Not Approved'),
                      selected: false,
                      onSelected: null,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Warning'),
                      selected: false,
                      onSelected: null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Today Section
              Text(
                'TODAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...history.map((result) => _buildHistoryItem(context, result)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/scanner');
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // History
        selectedItemColor: AppTheme.primaryGreen,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/'); // Home
          } else if (index == 2) {
            // Profile placeholder
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, VerificationResult result) {
    final isVerified = result.status == VerificationStatus.verified;
    final isWarning =
        result.status == VerificationStatus.unregistered ||
        result.status == VerificationStatus.recalled;

    final icon = isVerified
        ? Icons.check_circle
        : (isWarning ? Icons.error : Icons.history);

    final color = isVerified
        ? AppTheme.primaryGreen
        : (isWarning ? AppTheme.warningRed : AppTheme.expiredOrange);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication,
            color: Colors.grey[400],
          ), // Placeholder image
        ),
        title: Text(
          result.productName ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.manufacturer ?? 'N/A'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  DateFormat('h:mm a').format(result.scannedAt ?? DateTime.now()),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  isVerified
                      ? 'FDA Approved'
                      : (isWarning ? 'Not Approved' : 'License Expired'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(icon, color: color),
        onTap: () {
          Navigator.pushNamed(context, '/results', arguments: result);
        },
      ),
    );
  }
}
