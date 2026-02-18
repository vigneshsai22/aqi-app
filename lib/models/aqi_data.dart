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
         dailyPm25[date]!.add((pm25s[i] as num).toDouble());
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

    return AQIData(
      aqi: (currentAqi['us_aqi'] as num).toInt(),
      city: cityName,
      temperature: (currentWeather['temperature_2m'] as num).toDouble(),
      humidity: (currentWeather['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (currentWeather['wind_speed_10m'] as num).toDouble(),
      latitude: (aqiJson['latitude'] as num).toDouble(),
      longitude: (aqiJson['longitude'] as num).toDouble(),
      forecast: parsedForecast,
      pm2_5: (currentAqi['pm2_5'] as num?)?.toDouble() ?? 0,
      pm10: (currentAqi['pm10'] as num?)?.toDouble() ?? 0,
      no2: (currentAqi['nitrogen_dioxide'] as num?)?.toDouble() ?? 0,
      o3: (currentAqi['ozone'] as num?)?.toDouble() ?? 0,
      so2: (currentAqi['sulphur_dioxide'] as num?)?.toDouble() ?? 0,
    );
  }

  // Keep original factory for backward compatibility if needed, or remove.
  // We will likely not use it anymore.
  factory AQIData.fromJson(Map<String, dynamic> json) {
    return AQIData.fromOpenMeteo(json, {}, 'Unknown');
  }

  final List<AQIForecast> forecast;


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


  // Helper to get color based on AQI
  // 0-50 Good (Green)
  // 51-100 Moderate (Yellow)
  // 101-150 Unhealthy for Sensitive (Orange)
  // 151-200 Unhealthy (Red)
  // 201-300 Very Unhealthy (Purple)
  // 300+ Hazardous (Maroon)
}
