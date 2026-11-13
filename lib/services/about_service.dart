import '../models/about_stats.dart';

/// Serves the database statistics shown on the About screen.
///
/// Mocked for beta — no backend endpoint exists yet. Swap [fetchStats]'s
/// body for a real `GET /api/about` call once one does; [AboutStats.fromJson]
/// already matches the agreed response shape.
class AboutService {
  Future<AboutStats> fetchStats() async {
    return AboutStats.fromJson(const {
      'databaseStatus': 'Active',
      'registeredMedicines': 18342,
      'lastUpdated': '2026-07-01',
      'verificationSource': 'Ghana FDA',
    });
  }
}
