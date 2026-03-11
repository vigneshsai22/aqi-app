class AQIData {
  final int aqi;
  final String city;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double latitude;
  final double longitude;

  AQIData({
    required this.aqi,
    required this.city,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.latitude,
    required this.longitude,
    required this.forecast,
    this.pm2_5 = 0,
    this.pm10 = 0,
    this.no2 = 0,
    this.o3 = 0,
    this.so2 = 0,
  });

  final double pm2_5;
  final double pm10;
  final double no2;
  final double o3;
  final double so2;

  factory AQIData.fromOpenMeteo(
      Map<String, dynamic> aqiJson,
      Map<String, dynamic> weatherJson,
      String cityName) {
    
    final currentAqi = aqiJson['current'];
    final currentWeather = weatherJson['current'];
    
    // Parse forecast (using hourly pm2_5 as a proxy for forecast trend)
    List<AQIForecast> parsedForecast = [];
    if (aqiJson['hourly'] != null) {
       final times = aqiJson['hourly']['time'] as List;
       final pm25s = aqiJson['hourly']['pm2_5'] as List;
       
       // Group by day roughly or just take next few hours? 
       // For simplicity, let's take one reading per day for next 5 days
       // Open-Meteo returns hourly.
       
       Map<String, List<double>> dailyPm25 = {};
       
       for(int i=0; i<times.length; i++) {
         String date = times[i].toString().substring(0, 10);
         if (dailyPm25[date] == null) dailyPm25[date] = [];
         var pm25Val = pm25s[i];
         if (pm25Val != null) {
            dailyPm25[date]!.add((pm25Val as num).toDouble());
         }
       }
       
       dailyPm25.forEach((date, values) {
         if (parsedForecast.length >= 7) return;
         
         double avg = values.reduce((a, b) => a + b) / values.length;
         double min = values.reduce((a, b) => a < b ? a : b);
         double max = values.reduce((a, b) => a > b ? a : b);
         
         parsedForecast.add(AQIForecast(
           day: date, 
           avg: avg.round(), 
           min: min.round(), 
           max: max.round()
         ));
       });
    }

    // Extract hourly data for rolling averages
    Map<String, dynamic> hourly = aqiJson['hourly'] ?? {};

    List<dynamic> pm25s = hourly['pm2_5'] ?? [];
    List<dynamic> pm10s = hourly['pm10'] ?? [];
    List<dynamic> no2s = hourly['nitrogen_dioxide'] ?? [];
    List<dynamic> so2s = hourly['sulphur_dioxide'] ?? [];
    List<dynamic> o3s = hourly['ozone'] ?? [];

    // Calculate 24h averages and maxes
    // We assume the list is sorted by time and ends with current/forecast
    // "current" index should be roughly near the end of past_days data.
    // However, simplest robust way is to take the last 24 non-null values.
    
    double pm25Avg = _calculateRollingAverage(pm25s, 24);
    double pm10Avg = _calculateRollingAverage(pm10s, 24);
    double no2Avg = _calculateRollingAverage(no2s, 24);
    double so2Avg = _calculateRollingAverage(so2s, 24);
    double o3Max8h = _calculateMaxRollingAverage(o3s, 8);

    // If rolling averages are 0 (e.g. not enough data), fallback to current
    if (pm25Avg == 0) pm25Avg = (currentAqi['pm2_5'] as num?)?.toDouble() ?? 0;
    if (pm10Avg == 0) pm10Avg = (currentAqi['pm10'] as num?)?.toDouble() ?? 0;
    if (no2Avg == 0) no2Avg = (currentAqi['nitrogen_dioxide'] as num?)?.toDouble() ?? 0;
    if (o3Max8h == 0) o3Max8h = (currentAqi['ozone'] as num?)?.toDouble() ?? 0;
    if (so2Avg == 0) so2Avg = (currentAqi['sulphur_dioxide'] as num?)?.toDouble() ?? 0;

    return AQIData(
      aqi: _calculateIndianAQI(pm25Avg, pm10Avg, no2Avg, so2Avg, o3Max8h), // Use Rolling Averages
      city: cityName,
      temperature: (currentWeather['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      humidity: (currentWeather['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (currentWeather['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      latitude: (aqiJson['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (aqiJson['longitude'] as num?)?.toDouble() ?? 0.0,
      forecast: parsedForecast,
      pm2_5: pm25Avg, // Display the average used for calculation
      pm10: pm10Avg,
      no2: no2Avg,
      o3: o3Max8h,
      so2: so2Avg,
    );
  }

  static double _calculateRollingAverage(List<dynamic> values, int hours) {
    if (values.isEmpty) return 0;
    
    // Get last 'hours' valid values (ignoring nulls if possible, or strictly last N indices)
    // Open-Meteo returns nulls for future, but valid for past.
    // We want the *last available* 24 hours relative to "now".
    // Since we don't have "now" index easily without parsing time strings, 
    // we'll take the non-null values from the end of the list (assuming list contains [past...current...forecast])
    
    // Filter non-nulls
    List<double> validValues = values.whereType<num>().map((e) => e.toDouble()).toList();
    
    if (validValues.isEmpty) return 0;
    
    // Take last N
    int count = validValues.length < hours ? validValues.length : hours;
    List<double> lastN = validValues.sublist(validValues.length - count);
    
    if (lastN.isEmpty) return 0;
    
    return lastN.reduce((a, b) => a + b) / lastN.length;
  }

  static double _calculateMaxRollingAverage(List<dynamic> values, int windowSize) {
     // Calculate max of 8h moving averages
     List<double> validValues = values.whereType<num>().map((e) => e.toDouble()).toList();
     if (validValues.length < windowSize) return _calculateRollingAverage(values, windowSize);
     
     double maxAvg = 0;
     // Optimization: just check last 24 hours of 8h averages? or all?
     // Let's check the last 24 hours worth of data for the max 8h avg.
     int checkRange = 24; 
     if (validValues.length < checkRange) checkRange = validValues.length;
     
     // Start from end
     for (int i = 0; i < checkRange; i++) {
       int endIdx = validValues.length - i;
       int startIdx = endIdx - windowSize;
       if (startIdx < 0) break;
       
       List<double> window = validValues.sublist(startIdx, endIdx);
       double avg = window.reduce((a, b) => a + b) / window.length;
       if (avg > maxAvg) maxAvg = avg;
     }
     
     return maxAvg;
  }


  // Keep original factory for backward compatibility if needed, or remove.
  // We will likely not use it anymore.
  factory AQIData.fromJson(Map<String, dynamic> json) {
    return AQIData.fromOpenMeteo(json, {}, 'Unknown');
  }

  final List<AQIForecast> forecast;


  // Helper to calculate Indian AQI
  static int _calculateIndianAQI(double pm25, double pm10, double no2, double so2, double o3) {
    // Breakpoints for Indian AQI (CPCB)
    // PM2.5 (24h)
    int iPm25 = _getSubIndex(pm25, [30, 60, 90, 120, 250]);
    // PM10 (24h)
    int iPm10 = _getSubIndex(pm10, [50, 100, 250, 350, 430]);
    // NO2 (24h)
    int iNo2 = _getSubIndex(no2, [40, 80, 180, 280, 400]);
    // SO2 (24h)
    int iSo2 = _getSubIndex(so2, [40, 80, 380, 800, 1600]);
    // O3 (8h) - We only have hourly, so treating as current
    int iO3 = _getSubIndex(o3, [50, 100, 168, 208, 748]);

    // Overall AQI is the maximum of sub-indices
    return [iPm25, iPm10, iNo2, iSo2, iO3].reduce((a, b) => a > b ? a : b);
  }

  static int _getSubIndex(double value, List<double> limits) {
    // Calculation based on linear interpolation within range
    // Formula: I = [(Ihi - Ilo) / (BPhi - BPlo)] * (Cp - BPlo) + Ilo
    
    double bpLo = 0;
    double bpHi = 0;
    double iLo = 0;
    double iHi = 0;

    if (value <= limits[0]) {
      bpLo = 0; bpHi = limits[0]; iLo = 0; iHi = 50;
    } else if (value <= limits[1]) {
      bpLo = limits[0]; bpHi = limits[1]; iLo = 51; iHi = 100;
    } else if (value <= limits[2]) {
      bpLo = limits[1]; bpHi = limits[2]; iLo = 101; iHi = 200;
    } else if (value <= limits[3]) {
      bpLo = limits[2]; bpHi = limits[3]; iLo = 201; iHi = 300;
    } else if (value <= limits[4]) {
      bpLo = limits[3]; bpHi = limits[4]; iLo = 301; iHi = 400;
    } else {
      bpLo = limits[4]; bpHi = limits[4] * 2; // Approximate upper bound
      iLo = 401; iHi = 500;
    }
    
    if (bpHi == bpLo) return iLo.toInt();

    return (((iHi - iLo) / (bpHi - bpLo)) * (value - bpLo) + iLo).round();
  }
}


class AQIForecast {
  final String day;
  final int avg;
  final int min;
  final int max;

  AQIForecast({required this.day, required this.avg, required this.min, required this.max});

  factory AQIForecast.fromJson(Map<String, dynamic> json) {
    return AQIForecast(
      day: json['day'] ?? '',
      avg: json['avg'] is int ? json['avg'] : int.tryParse(json['avg'].toString()) ?? 0,
      min: json['min'] is int ? json['min'] : int.tryParse(json['min'].toString()) ?? 0,
      max: json['max'] is int ? json['max'] : int.tryParse(json['max'].toString()) ?? 0,
    );
  }
}



