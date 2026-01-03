import 'package:flutter/material.dart';
import '../models/verification_result.dart';
import '../services/local_database.dart';

class AppProvider with ChangeNotifier {
  List<VerificationResult> _scanHistory = [];
  bool _isLoading = true;

  List<VerificationResult> get scanHistory => List.unmodifiable(_scanHistory);
  bool get isLoading => _isLoading;

  AppProvider() {
    _loadHistoryFromDb();
  }

  // Load from SQLite on startup
  Future<void> _loadHistoryFromDb() async {
    _isLoading = true;
    notifyListeners();

    _scanHistory = await LocalDatabase.instance.fetchHistory();

    _isLoading = false;
    notifyListeners();
  }

  // Add to both Memory AND Database
  Future<void> addScan(VerificationResult result) async {
    // 1. Update Database
    await LocalDatabase.instance.insertResult(result);

    // 2. Update Memory for immediate UI feedback
    _scanHistory.insert(0, result);
    notifyListeners();
  }

  // Fast lookup for OCR logic
  Future<VerificationResult?> checkLocalLookup(String query) async {
    // Logic: Look through memory first (it's fastest)
    try {
      return _scanHistory.firstWhere(
              (element) => element.regNumber == query ||
              (element.productName?.toLowerCase().contains(query.toLowerCase()) ?? false)
      );
    } catch (_) {
      return null;
    }
  }

  List<VerificationResult> get todayScans {
    final now = DateTime.now();
    return _scanHistory.where((scan) {
      // In the modified toMap, we'd need to store scannedAt to filter properly
      // For now, returning the list
      return true;
    }).toList();
  }

  Future<void> clearHistory() async {
    // 1. Clear the persistent storage
    await LocalDatabase.instance.clearAllHistory();

    // 2. Clear the in-memory list
    _scanHistory = [];

    // 3. Notify UI to refresh (History screen will become empty)
    notifyListeners();
  }
}