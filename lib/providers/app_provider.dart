import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
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
    try {
      _scanHistory = await LocalDatabase.instance.fetchHistory();
    } catch (e) {
      await Sentry.captureException(e);
      _scanHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addScan(VerificationResult result) async {
    final resultWithId = result.copyWith(id: const Uuid().v4());
    await LocalDatabase.instance.insertResult(resultWithId);
    _scanHistory.insert(0, resultWithId);
    notifyListeners();
  }

  Future<void> updateResult(VerificationResult oldResult, String newSource) async {
    final newResult = oldResult.copyWith(source: newSource);
    await LocalDatabase.instance.updateResult(newResult);

    final index = _scanHistory.indexOf(oldResult);
    if (index != -1) {
      _scanHistory[index] = newResult;
      notifyListeners();
    }
  }

  VerificationResult? checkLocalLookup(String query) {
    final lowerQuery = query.toLowerCase();
    for (final result in _scanHistory) {
      if (result.regNumber == query) return result;
      if (result.productName?.toLowerCase().contains(lowerQuery) ?? false) {
        return result;
      }
    }
    return null;
  }

  List<VerificationResult> get todayScans {
    final now = DateTime.now();
    return _scanHistory.where((scan) {
      if (scan.scannedAt == null) return false;
      return scan.scannedAt!.year == now.year &&
             scan.scannedAt!.month == now.month &&
             scan.scannedAt!.day == now.day;
    }).toList();
  }

  Future<void> clearHistory() async {
    await LocalDatabase.instance.clearAllHistory();
    _scanHistory = [];
    notifyListeners();
  }
}
