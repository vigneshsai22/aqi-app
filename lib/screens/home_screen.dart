import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/aqi_card.dart';
import '../widgets/history_chart.dart';
import '../utils/app_colors.dart';
import '../models/aqi_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _indianCities = [
    'New Delhi',
    'Mumbai',
    'Bengaluru',
    'Chennai',
    'Kolkata',
    'Hyderabad',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Lucknow'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).fetchAQIForCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Air Quality Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () async {
              final provider = Provider.of<WeatherProvider>(context, listen: false);
              if (provider.currentAQI != null) {
                await provider.saveAsDefaultLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Default location set to ${provider.currentAQI!.city}')),
                  );
                }
              }
            },
            tooltip: 'Set as Default Location',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              Provider.of<WeatherProvider>(context, listen: false).clearDefaultLocation();
            },
            tooltip: 'Reset to My Location (GPS)',
          ),
        ],
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          // Define gradient based on AQI if data is available
          Gradient backgroundGradient = const LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

          if (provider.currentAQI != null) {
            Color aqiColor = AppColors.getAQIColor(provider.currentAQI!.aqi);
            backgroundGradient = LinearGradient(
              colors: [aqiColor.withOpacity(0.2), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            );
          }

          return Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: SafeArea(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? _buildErrorView(provider)
                      : _buildContent(provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(WeatherProvider provider) {
    if (provider.currentAQI == null) {
      return const Center(child: Text('No data available.'));
    }

    final data = provider.currentAQI!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildSearchBar(provider),
          _buildCityChips(provider),
          const SizedBox(height: 10),
          
          // Main AQI Card
          Center(child: AQICard(data: data)), // Use updated AQICard
          
          const SizedBox(height: 20),
          
          // Pollutants Grid
          const Text('Pollutants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildPollutantsGrid(data),

          const SizedBox(height: 20),
          
          // Weather Details
          const Text('Weather Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildWeatherRow(data),

          const SizedBox(height: 20),
          
          if (data.forecast.isNotEmpty) ...[
             const Text('Forecast Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             HistoryChart(history: data.forecast),
             const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(WeatherProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search City...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (_searchController.text.isNotEmpty) {
              provider.fetchAQIForCity(_searchController.text);
            }
          },
        ),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          provider.fetchAQIForCity(value);
        }
      },
    );
  }

  Widget _buildCityChips(WeatherProvider provider) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _indianCities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = _indianCities[index];
          return ActionChip(
            label: Text(city),
            onPressed: () => provider.fetchAQIForCity(city),
            backgroundColor: Colors.white,
            elevation: 1,
          );
        },
      ),
    );
  }

  Widget _buildPollutantsGrid(AQIData data) {
    // Grid of pollutants
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildPollutantCard('PM2.5', '${data.pm2_5.round()}'),
        _buildPollutantCard('PM10', '${data.pm10.round()}'),
        _buildPollutantCard('NO2', '${data.no2.round()}'),
        _buildPollutantCard('O3', '${data.o3.round()}'),
        _buildPollutantCard('SO2', '${data.so2.round()}'),
      ],
    );
  }

  Widget _buildPollutantCard(String name, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(AQIData data) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceAround,
         children: [
           _buildWeatherItem(Icons.thermostat, '${data.temperature}°C', 'Temp'),
           _buildWeatherItem(Icons.water_drop, '${data.humidity}%', 'Humidity'),
           _buildWeatherItem(Icons.air, '${data.windSpeed} km/h', 'Wind'),
         ],
       ),
     );
  }

  Widget _buildWeatherItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueGrey),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildErrorView(WeatherProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 10),
          Text(provider.error ?? 'Unknown Error'),
          ElevatedButton(onPressed: () => provider.fetchAQIForCurrentLocation(), child: const Text('Retry'))
        ],
      ),
    );
  }
}
