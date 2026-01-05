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
    await box.add(result.toMap());
  }

  Future<List<VerificationResult>> fetchHistory() async {
    final box = Hive.box<Map>(_historyBoxName);
    return box.values
        .map((e) => VerificationResult.fromMap(e.cast<String, dynamic>()))
        .toList()
        .reversed
        .toList();
  }

  Future<void> clearAllHistory() async {
    final box = Hive.box<Map>(_historyBoxName);
    await box.clear();
  }

  Future<void> close() async {
    await Hive.close();
  }
}
