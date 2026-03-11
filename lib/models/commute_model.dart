
enum TransportMode {
  walking,
  cycling,
  motorbike,
  car, // AC assumed
  bus, // Non-AC / Windows open often
  metro, // AC
}

extension TransportModeExtension on TransportMode {
  String get name {
    switch (this) {
      case TransportMode.walking: return 'Walking';
      case TransportMode.cycling: return 'Cycling';
      case TransportMode.motorbike: return 'Motorbike';
      case TransportMode.car: return 'Car (AC)';
      case TransportMode.bus: return 'Bus';
      case TransportMode.metro: return 'Metro';
    }
  }

  double get breathingRate {
    // Liters per minute approx
    switch (this) {
      case TransportMode.walking: return 25.0; // Moderate exercise
      case TransportMode.cycling: return 40.0; // Heavy exercise
      case TransportMode.motorbike: return 15.0; // Light (stress)
      case TransportMode.car: return 12.0; // Sedentary
      case TransportMode.bus: return 12.0; // Sedentary
      case TransportMode.metro: return 12.0; // Sedentary
    }
  }

  double get protectionFactor {
    // 1.0 = No protection (Direct outdoor air)
    // 0.5 = 50% reduction (e.g. Car AC filter)
    switch (this) {
      case TransportMode.walking: return 1.0;
      case TransportMode.cycling: return 1.0;
      case TransportMode.motorbike: return 0.9; // Helmet visor slightly helps?
      case TransportMode.car: return 0.4; // Good cabin filter
      case TransportMode.bus: return 0.8; // Often windows open
      case TransportMode.metro: return 0.3; // Controlled environment
    }
  }
}

class ExposureResult {
  final double dosageMicrograms; // usage: PM2.5 mass
  final double cigaretteEquivalents;
  final String riskLevel;
  final String recommendation;
  final double startAqi;
  final double endAqi;

  ExposureResult({
    required this.dosageMicrograms,
    required this.cigaretteEquivalents,
    required this.riskLevel,
    required this.recommendation,
    required this.startAqi,
    required this.endAqi,
  });
}
