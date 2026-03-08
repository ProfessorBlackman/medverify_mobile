import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/verification_result.dart';
import '../theme.dart';
import '../widgets/dashboard_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  int _selectedStatusFilter =
      0; // 0: All, 1: Approved, 2: Not Approved, 3: Warning
  int _selectedTypeFilter = 0; // 0: All Types, 1: Scanned, 2: Searched

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan History',
          style: GoogleFonts.publicSans(
            color: AppTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          var history = provider.scanHistory;

          // Apply search
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            history = history.where((result) {
              return (result.productName?.toLowerCase().contains(query) ??
                      false) ||
                  (result.regNumber?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          // Apply status filter
          if (_selectedStatusFilter != 0) {
            history = history.where((result) {
              final isVerified = result.status == VerificationStatus.verified;
              final isWarning =
                  result.status == VerificationStatus.unregistered ||
                  result.status == VerificationStatus.recalled ||
                  result.status == VerificationStatus.nearExpiry;

              if (_selectedStatusFilter == 1) return isVerified;
              if (_selectedStatusFilter == 2) return !isVerified && !isWarning;
              if (_selectedStatusFilter == 3) return isWarning;
              return true;
            }).toList();
          }

          // Apply type filter
          if (_selectedTypeFilter != 0) {
            history = history.where((result) {
              final isScan = result.source == 'scan';
              if (_selectedTypeFilter == 1) return isScan;
              if (_selectedTypeFilter == 2) return !isScan;
              return true;
            }).toList();
          }

          if (history.isEmpty &&
              _searchQuery.isEmpty &&
              _selectedStatusFilter == 0 &&
              _selectedTypeFilter == 0) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No history yet'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
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

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('All', style: TextStyle(fontSize: 12, color: _selectedStatusFilter == 0 ? Colors.white : Colors.black)),
                      selected: _selectedStatusFilter == 0,
                      onSelected: (selected) =>
                          setState(() => _selectedStatusFilter = 0),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Approved', style: TextStyle(fontSize: 12, color: _selectedStatusFilter == 1 ? Colors.white : Colors.black)),
                      selected: _selectedStatusFilter == 1,
                      onSelected: (selected) =>
                          setState(() => _selectedStatusFilter = 1),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Not Approved', style: TextStyle(fontSize: 12, color: _selectedStatusFilter == 2 ? Colors.white : Colors.black)),
                      selected: _selectedStatusFilter == 2,
                      onSelected: (selected) =>
                          setState(() => _selectedStatusFilter = 2),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Warning', style: TextStyle(fontSize: 12, color: _selectedStatusFilter == 3 ? Colors.white : Colors.black)),
                      selected: _selectedStatusFilter == 3,
                      onSelected: (selected) =>
                          setState(() => _selectedStatusFilter = 3),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('All Types', style: TextStyle(fontSize: 12, color: _selectedTypeFilter == 0 ? Colors.white : Colors.black)),
                      selected: _selectedTypeFilter == 0,
                      onSelected: (selected) =>
                          setState(() => _selectedTypeFilter = 0),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Scanned', style: TextStyle(fontSize: 12, color: _selectedTypeFilter == 1 ? Colors.white : Colors.black)),
                      selected: _selectedTypeFilter == 1,
                      onSelected: (selected) =>
                          setState(() => _selectedTypeFilter = 1),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Searched/Manual', style: TextStyle(fontSize: 12, color: _selectedTypeFilter == 2 ? Colors.white : Colors.black)),
                      selected: _selectedTypeFilter == 2,
                      onSelected: (selected) =>
                          setState(() => _selectedTypeFilter = 2),
                      selectedColor: AppTheme.primaryGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (history.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No results match your filters.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._buildGroupedHistory(context, history),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  List<Widget> _buildGroupedHistory(
    BuildContext context,
    List<VerificationResult> history,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <VerificationResult>[];
    final yesterdayItems = <VerificationResult>[];
    final olderItems = <VerificationResult>[];

    for (var result in history) {
      if (result.scannedAt == null) {
        olderItems.add(result);
        continue;
      }

      final date = DateTime(
        result.scannedAt!.year,
        result.scannedAt!.month,
        result.scannedAt!.day,
      );
      if (date == today) {
        todayItems.add(result);
      } else if (date == yesterday) {
        yesterdayItems.add(result);
      } else {
        olderItems.add(result);
      }
    }

    final widgets = <Widget>[];

    if (todayItems.isNotEmpty) {
      widgets.add(_buildDateHeader(context, 'TODAY'));
      widgets.addAll(todayItems.map((r) => _buildHistoryItem(context, r)));
    }

    if (yesterdayItems.isNotEmpty) {
      widgets.add(_buildDateHeader(context, 'YESTERDAY'));
      widgets.addAll(yesterdayItems.map((r) => _buildHistoryItem(context, r)));
    }

    if (olderItems.isNotEmpty) {
      widgets.add(_buildDateHeader(context, 'OLDER SCANS'));
      widgets.addAll(olderItems.map((r) => _buildHistoryItem(context, r)));
    }

    return widgets;
  }

  Widget _buildDateHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, VerificationResult result) {
    final isVerified = result.status == VerificationStatus.verified;
    final isWarning =
        result.status == VerificationStatus.unregistered ||
        result.status == VerificationStatus.recalled ||
        result.status == VerificationStatus.nearExpiry;

    final icon = isVerified
        ? Icons.check_circle
        : (isWarning ? Icons.error : Icons.history);

    final color = isVerified
        ? AppTheme.primaryGreen
        : (isWarning ? AppTheme.warningRed : AppTheme.warningOrange);

    final isScan = result.source == 'scan';
    final leadingIcon = isScan ? Icons.qr_code_scanner : Icons.search;

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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            leadingIcon,
            color: color,
          ), // Using dynamic source-based icon
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
                  DateFormat(
                    'h:mm a',
                  ).format(result.scannedAt ?? DateTime.now()),
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
