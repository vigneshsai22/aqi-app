import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/travel_service.dart';
import '../models/aqi_data.dart';
import '../models/travel_recommendation.dart';
import 'travel_result_screen.dart';

class TravelPlanningScreen extends StatefulWidget {
  const TravelPlanningScreen({super.key});

  @override
  State<TravelPlanningScreen> createState() => _TravelPlanningScreenState();
}

class _TravelPlanningScreenState extends State<TravelPlanningScreen> {
  final TextEditingController _cityController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _analyzeTravel() async {
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination city')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch data for the destination
      AQIData destinationData = await _apiService.fetchAQIByCity(_cityController.text);

      // 2. Fetch data for current location (comparison) - simplified for now, defaulting to 'Delhi' or random if unavailable?
      // Better: Try to get current location if possible, or just skip comparison if failed.
      // For this user flow, let's try to fetch a known city like 'New Delhi' as a baseline if we can't get real location easily here without permissions,
      // BUT `LocationService` exists in the project. Let's not complicate with permissions here yet.
      // We will skip explicit current location fetch for now unless the user asks, OR we can just pass null.
      // However, to demo the "City Comparison" feature, let's fetch a fixed interesting city if the user didn't select it,
      // Or better, let's try to fetch "New Delhi" as a comparison point if the user is not in Delhi.
      
      AQIData? comparisonData;
      // For demo purposes, let's compare with 'New Delhi' if the destination is not New Delhi
      if (!_cityController.text.toLowerCase().contains('delhi')) {
         try {
           comparisonData = await _apiService.fetchAQIByCity('New Delhi');
         } catch (e) {
           // ignore comparison failure
         }
      }

      // 3. Analyze
      TravelRecommendation recommendation = TravelService.analyzeTravelPlan(
        destinationData, 
        comparisonData: comparisonData
      );

      if (!mounted) return;

      // 3. Navigate to results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TravelResultScreen(recommendation: recommendation),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Planner'),
        backgroundColor: Colors.transparent, // Modern look
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Plan your Safe Trip',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Find the best time to visit and stay safe.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Destination Input
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Destination City',
                hintText: 'e.g. Jaipur',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDateRange == null
                          ? 'Select Travel Dates (Optional)'
                          : '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDateRange == null ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),

            // Analyze Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _analyzeTravel,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Analyze Travel Plan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
