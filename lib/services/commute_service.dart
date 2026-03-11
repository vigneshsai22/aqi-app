
import '../models/aqi_data.dart';
import '../models/commute_model.dart';
import 'dart:math';

class CommuteService {

  // PM2.5 in ug/m3 based on AQI (approximate reverse calculation for Ind-AQI)
  static double _aqiToPm25(double aqi) {
    // Very rough approximation for Indian AQI PM2.5 sub-index
    // 0-50 AQI ~ 0-30 ug/m3
    // 51-100 AQI ~ 31-60 ug/m3
    // ...
    // Let's use a linear scaler for simplicity as we stored AQI not raw PM2.5 in some cases
    // But AQIData has pm2_5 field! We should use that if available.
    return aqi * 0.8; // Fallback heuristic if pm2_5 is missing
  }

  static ExposureResult calculateExposure({
    required AQIData startData, 
    required AQIData endData, 
    required TransportMode mode, 
    required double durationMinutes
  }) {
    
    // 1. Get average PM2.5 concentration (ug/m3) along the route
    // Using start and end points
    double startPm25 = startData.pm2_5 > 0 ? startData.pm2_5 : _aqiToPm25(startData.aqi.toDouble());
    double endPm25 = endData.pm2_5 > 0 ? endData.pm2_5 : _aqiToPm25(endData.aqi.toDouble());
    
    double avgPm25 = (startPm25 + endPm25) / 2;
    
    // 2. Apply Protection Factor
    double effectivePm25 = avgPm25 * mode.protectionFactor;

    // 3. Calculate Dosage
    // Dosage (ug) = Concentration (ug/m3) * Breathing Rate (L/min) * Duration (min) * (1 m3 / 1000 L)
    double dosage = effectivePm25 * mode.breathingRate * durationMinutes / 1000.0;

    // 4. Calculate Cigarette Equivalents
    // Rule of thumb: 22 ug/m3 for 24 hours ~ 1 cigarette (Berkeley Earth)
    // 1 cigarette ~ 12 mg of PM2.5 inhaled? No, the calculation is usually based on ambient exposure.
    // "One cigarette per day is the rough equivalent of a PM2.5 level of 22 μg/m3." - for a full day.
    // So 22 * 24h exposure ~ 1 cig. Check calculations carefully.
    // Let's use the widely cited: 1 cigarette ~ 22ug/m3 average for 24 hours.
    // That means inhaled mass for 1 cig ~ 22 (ug/m3) * 15 (m3/day breathed) ~ 330 ug.
    // Let's assume 1 cigarette ~ 300 ug of PM2.5 inhaled.
    double cigaretteEquiv = dosage / 300.0;

    // 5. Risk Assessment
    String riskLevel;
    String recommendation;

    if (dosage < 5) {
      riskLevel = 'Low';
      recommendation = 'Safe commute.';
    } else if (dosage < 15) {
      riskLevel = 'Moderate';
      recommendation = 'Consider wearing a mask if you have sensitivities.';
    } else if (dosage < 30) {
      riskLevel = 'High';
      recommendation = 'Wear a mask. Try to reduce commute time or choose a cleaner mode (Metro/Car).';
    } else {
      riskLevel = 'Severe';
      recommendation = 'Major Health Risk! Avoid this commute mode immediately.';
    }

    return ExposureResult(
      dosageMicrograms: double.parse(dosage.toStringAsFixed(2)),
      cigaretteEquivalents: double.parse(cigaretteEquiv.toStringAsFixed(2)),
      riskLevel: riskLevel,
      recommendation: recommendation,
      startAqi: startData.aqi.toDouble(),
      endAqi: endData.aqi.toDouble(),
    );
  }
}
