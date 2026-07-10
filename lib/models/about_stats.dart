/// Database metadata shown on the About screen.
///
/// Mirrors the shape of the future `GET /api/about` endpoint so the screen
/// can switch from mocked to live data without changing its UI code.
class AboutStats {
  final String databaseStatus;
  final int registeredMedicines;
  final DateTime lastUpdated;
  final String verificationSource;

  const AboutStats({
    required this.databaseStatus,
    required this.registeredMedicines,
    required this.lastUpdated,
    required this.verificationSource,
  });

  factory AboutStats.fromJson(Map<String, dynamic> json) {
    return AboutStats(
      databaseStatus: json['databaseStatus'] as String? ?? 'Unknown',
      registeredMedicines: (json['registeredMedicines'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
      verificationSource: json['verificationSource'] as String? ?? 'Ghana FDA',
    );
  }
}
