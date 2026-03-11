import '../models/aqi_data.dart';
import '../models/travel_recommendation.dart';

class TravelService {
  
  static TravelRecommendation analyzeTravelPlan(AQIData aqiData, {AQIData? comparisonData}) {
    // 1. Calculate Risk Level
    TravelRiskLevel riskLevel = _calculateRiskLevel(aqiData.aqi);

    // 2. Generate Advisories
    List<String> advisories = _generateAdvisories(aqiData.aqi);

    // 3. Identify Best Dates (from forecast)
    List<String> bestDates = _findBestDates(aqiData.forecast);
    
    // 4. Check for Season Alert
    String? seasonAlert = _checkSeasonAlert(aqiData.city);

    // 5. recursive call for comparison if provided
    TravelRecommendation? comparisonRec;
    if (comparisonData != null) {
      comparisonRec = analyzeTravelPlan(comparisonData); // Recursive but without comparisonData to avoid infinite loop
    }

    return TravelRecommendation(
      city: aqiData.city,
      riskLevel: riskLevel,
      bestDates: bestDates,
      advisories: advisories,
      seasonAlert: seasonAlert,
      averageAqi: aqiData.aqi,
      primaryPollutant: 'PM2.5', // Simplified
      comparison: comparisonRec,
    );
  }

  static TravelRiskLevel _calculateRiskLevel(int aqi) {
    if (aqi <= 100) return TravelRiskLevel.low;
    if (aqi <= 200) return TravelRiskLevel.moderate;
    if (aqi <= 300) return TravelRiskLevel.high;
    return TravelRiskLevel.severe;
  }

  static List<String> _generateAdvisories(int aqi) {
    List<String> tips = [];
    if (aqi > 200) {
      tips.add('Carry N95 masks.');
      tips.add('Avoid outdoor activities, especially in the morning.');
      tips.add('Consider using air purifiers indoors.');
    } else if (aqi > 100) {
      tips.add('Sensitive groups should wear masks.');
      tips.add('Limit prolonged outdoor exertion.');
    } else {
      tips.add('Air quality is good. Enjoy your travel!');
      tips.add('Great for outdoor activities.');
    }
    
    tips.add('Stay hydrated to help flush out toxins.');
    return tips;
  }

  static List<String> _findBestDates(List<AQIForecast> forecast) {
    // Return dates where AQI is forecasted to be lowest (top 3)
    if (forecast.isEmpty) return [];
    
    // Sort by Average AQI ascending
    var sorted = List<AQIForecast>.from(forecast)
      ..sort((a, b) => a.avg.compareTo(b.avg));
      
    // Take top 3 best days
    return sorted.take(3).map((e) => '${e.day} (AQI: ${e.avg})').toList();
  }

  static String? _checkSeasonAlert(String city) {
    // Simple hardcoded checks for demonstration
    // In a real app, this would check current month + location history
    DateTime now = DateTime.now();
    int month = now.month;
    
    if (city.toLowerCase().contains('delhi') || 
        city.toLowerCase().contains('ncr') ||
        city.toLowerCase().contains('gurugram') ||
        city.toLowerCase().contains('noida')) {
      if (month >= 10 || month <= 1) {
        return 'High pollution season (Winter Smog) expected.';
      }
    }
    
    return null;
  }
}
