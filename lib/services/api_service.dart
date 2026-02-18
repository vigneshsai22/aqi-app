import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/aqi_data.dart';

class ApiService {
  final String _aqiBaseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  final String _weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Hardcoded coordinates for Indian cities to avoid geocoding API limits/complexity
  final Map<String, Map<String, double>> _indianCitiesCoords = {
    'New Delhi': {'lat': 28.6139, 'lon': 77.2090},
    'Mumbai': {'lat': 19.0760, 'lon': 72.8777},
    'Bengaluru': {'lat': 12.9716, 'lon': 77.5946},
    'Chennai': {'lat': 13.0827, 'lon': 80.2707},
    'Kolkata': {'lat': 22.5726, 'lon': 88.3639},
    'Hyderabad': {'lat': 17.3850, 'lon': 78.4867},
    'Pune': {'lat': 18.5204, 'lon': 73.8567},
    'Ahmedabad': {'lat': 23.0225, 'lon': 72.5714},
    'Jaipur': {'lat': 26.9124, 'lon': 75.7873},
    'Lucknow': {'lat': 26.8467, 'lon': 80.9462},
  };

  final String _geocodingUrl = 'https://api.bigdatacloud.net/data/reverse-geocode-client';

  Future<AQIData> fetchAQIByLocation(double lat, double lon, {String? cityName}) async {
    try {
      String finalCityName = cityName ?? 'Unknown Location';
      
      // If cityName is not provided, fetch it via reverse geocoding
      if (cityName == null) {
        try {
          finalCityName = await _getCityName(lat, lon);
        } catch (e) {
          debugPrint('Reverse geocoding failed: $e');
           // Fallback is already set to 'Unknown Location'
        }
      }

      // 1. Fetch AQI
      final aqiResponse = await http.get(Uri.parse(
          '$_aqiBaseUrl?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5,pm10,nitrogen_dioxide,ozone,sulphur_dioxide&hourly=pm2_5&timezone=auto'));

      // 2. Fetch Weather
      final weatherResponse = await http.get(Uri.parse(
          '$_weatherBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m&timezone=auto'));

      if (aqiResponse.statusCode == 200 && weatherResponse.statusCode == 200) {
        final aqiJson = jsonDecode(aqiResponse.body);
        final weatherJson = jsonDecode(weatherResponse.body);

        return AQIData.fromOpenMeteo(
          aqiJson,
          weatherJson,
          finalCityName,
        );
      } else {
        throw Exception('Failed to load data from Open-Meteo');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<String> _getCityName(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse('$_geocodingUrl?latitude=$lat&longitude=$lon&localityLanguage=en'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Try to find the most relevant name
        return json['city'] ?? json['locality'] ?? json['principalSubdivision'] ?? 'Unknown Location';
      }
    } catch (e) {
      // Ignore and return default
    }
    return 'Your Location';
  }

  final String _geocodingApiUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<AQIData> fetchAQIByCity(String city) async {
    try {
      // 1. Get Coordinates from Geocoding API (Fetch more results to filter by country)
      final geoResponse = await http.get(Uri.parse(
          '$_geocodingApiUrl?name=$city&count=10&language=en&format=json'));

      if (geoResponse.statusCode == 200) {
        final geoJson = jsonDecode(geoResponse.body);
        if (geoJson['results'] != null && (geoJson['results'] as List).isNotEmpty) {
          // Filter for Indian cities only
          final results = geoJson['results'] as List;
          final indianCity = results.firstWhere(
            (r) => r['country_code'] == 'IN' || r['country'] == 'India',
            orElse: () => null,
          );

          if (indianCity != null) {
            final double lat = indianCity['latitude'];
            final double lon = indianCity['longitude'];
            final String name = indianCity['name'];
            final String? admin1 = indianCity['admin1']; // State name usually

            // 2. Fetch AQI data for these coordinates
            return fetchAQIByLocation(lat, lon, cityName: '$name${admin1 != null ? ', $admin1' : ''}');
          } else {
             throw Exception('City "$city" not found in India.');
          }
        } else {
           throw Exception('City not found: $city');
        }
      } else {
        throw Exception('Failed to search city: ${geoResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error finding city: $e');
      throw Exception('$e'); // Pass actual error message
    }
  }
}
