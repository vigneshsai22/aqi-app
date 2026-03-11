
class TravelRecommendation {
  final String city;
  final TravelRiskLevel riskLevel;
  final List<String> bestDates;
  final List<String> advisories;
  final String? seasonAlert;
  final int averageAqi;
  final String primaryPollutant;
  final TravelRecommendation? comparison; // Recommendation for another city (e.g., current location)

  TravelRecommendation({
    required this.city,
    required this.riskLevel,
    required this.bestDates,
    required this.advisories,
    this.seasonAlert,
    required this.averageAqi,
    required this.primaryPollutant,
    this.comparison,
  });
}

enum TravelRiskLevel {
  low,      // AQI < 100
  moderate, // AQI 100-200
  high,     // AQI 200-300
  severe    // AQI > 300
}
