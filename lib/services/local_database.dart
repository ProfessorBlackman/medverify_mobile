import 'package:hive_flutter/hive_flutter.dart';
import '../models/verification_result.dart';

class LocalDatabase {
  static const String _historyBoxName = 'scan_history';

  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Future<void> init() async {
    // This ensures Hive is initialized in a Flutter environment.
    await Hive.initFlutter();
    // Now, it's safe to open a box.
    await Hive.openBox<Map>(_historyBoxName);
  }

  Future<void> insertResult(VerificationResult result) async {
    final box = Hive.box<Map>(_historyBoxName);
    // Use UUID as key for stable lookup; fall back to auto-increment for
    // records that pre-date the id field.
    if (result.id != null) {
      await box.put(result.id, result.toMap());
    } else {
      await box.add(result.toMap());
    }
  }

  Future<void> updateResult(VerificationResult result) async {
    final box = Hive.box<Map>(_historyBoxName);
    if (result.id != null && box.containsKey(result.id)) {
      await box.put(result.id, result.toMap());
    }
  }

  Future<List<VerificationResult>> fetchHistory() async {
    final box = Hive.box<Map>(_historyBoxName);
    final results = box.values
        .map((e) => VerificationResult.fromMap(e.cast<String, dynamic>()))
        .toList();
    results.sort((a, b) =>
        (b.scannedAt ?? DateTime(0)).compareTo(a.scannedAt ?? DateTime(0)));
    return results;
  }

  Future<void> clearAllHistory() async {
    final box = Hive.box<Map>(_historyBoxName);
    await box.clear();
  }

  Future<void> close() async {
    await Hive.close();
  }
}
