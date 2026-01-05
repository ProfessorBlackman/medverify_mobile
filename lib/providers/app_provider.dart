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

  Future<void> _loadHistoryFromDb() async {
    _isLoading = true;
    notifyListeners();

    _scanHistory = await LocalDatabase.instance.fetchHistory();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addScan(VerificationResult result) async {
    await LocalDatabase.instance.insertResult(result);
    _scanHistory.insert(0, result);
    notifyListeners();
  }

  Future<VerificationResult?> checkLocalLookup(String query) async {
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
      return true;
    }).toList();
  }

  Future<void> clearHistory() async {
    await LocalDatabase.instance.clearAllHistory();
    _scanHistory = [];
    notifyListeners();
  }
}
