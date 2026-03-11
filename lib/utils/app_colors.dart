import 'package:flutter/material.dart';

class AppColors {
  static Color getAQIColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00B050); // Good - Dark Green
    if (aqi <= 100) return const Color(0xFF92D050); // Satisfactory - Light Green
    if (aqi <= 200) return const Color(0xFFFFC107); // Moderate - Amber/Dark Yellow
    if (aqi <= 300) return const Color(0xFFFF9900); // Poor - Orange
    if (aqi <= 400) return const Color(0xFFFF0000); // Very Poor - Red
    return const Color(0xFFC00000); // Severe - Dark Red
  }

  static String getAQIStatus(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }
}
