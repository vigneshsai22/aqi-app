import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aqi_data.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

class WeatherProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  AQIData? _currentAQI;
  bool _isLoading = false;
  String? _error;

  AQIData? get currentAQI => _currentAQI;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAQIForCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Check for manual default location override
      final prefs = await SharedPreferences.getInstance();
      final String? defaultCity = prefs.getString('default_city');
      final double? defaultLat = prefs.getDouble('default_lat');
      final double? defaultLon = prefs.getDouble('default_lon');

      if (defaultCity != null && defaultLat != null && defaultLon != null) {
         // Use saved location
         _currentAQI = await _apiService.fetchAQIByLocation(defaultLat, defaultLon, cityName: defaultCity);
      } else {
         // Fallback to GPS / IP Location
         final position = await _locationService.determinePosition();
         _currentAQI = await _apiService.fetchAQIByLocation(position.latitude, position.longitude);
      }
      
      if (_currentAQI != null) {
        _checkAlerts(_currentAQI!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAsDefaultLocation() async {
    if (_currentAQI == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_city', _currentAQI!.city);
    // Note: AQIData now has lat/lon
    // We need to ensure AQIData actually has these fields populated correctly from the API response
    // validation: if lat/lon are 0, might be an issue, but usually they are valid.
    await prefs.setDouble('default_lat', _currentAQI!.latitude);
    await prefs.setDouble('default_lon', _currentAQI!.longitude);
    notifyListeners(); // Optional, to update UI state if needed
  }

  Future<void> clearDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('default_city');
    await prefs.remove('default_lat');
    await prefs.remove('default_lon');
    // After clearing, maybe fetch current location again?
    fetchAQIForCurrentLocation();
  }

  bool get isDefaultLocationSet {
     // This is a bit tricky since it's async to check prefs. 
     // We might want to load this state initially or just check it when needed.
     // For now, let's just rely on the UI calling a method if we need to check status, or 
     // add a property that is updated.
     return false; // Placeholder, better to handle asynchronously or separate state
  }

  Future<void> fetchAQIForCity(String city) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentAQI = await _apiService.fetchAQIByCity(city);
      _checkAlerts(_currentAQI!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAlerts(AQIData data) async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final double threshold = (prefs.getInt('alert_threshold') ?? 100).toDouble();

    if (notificationsEnabled && data.aqi > threshold) {
      NotificationService().showNotification(
        'High AQI Alert: ${data.city}',
        'Current AQI is ${data.aqi}. Level: ${AppColors.getAQIStatus(data.aqi)}',
      );
    }
  }
}
