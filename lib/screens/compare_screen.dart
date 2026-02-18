import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/aqi_data.dart';
import '../utils/app_colors.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final TextEditingController _city1Controller = TextEditingController();
  final TextEditingController _city2Controller = TextEditingController();
  final ApiService _apiService = ApiService();
  
  AQIData? _city1Data;
  AQIData? _city2Data;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Compare Cities', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Inputs Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildCityInput(_city1Controller, 'First City')),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        Expanded(child: _buildCityInput(_city2Controller, 'Second City')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _compareCities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('COMPARE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red))
              else if (_city1Data != null && _city2Data != null)
                _buildComparisonResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Future<void> _compareCities() async {
    if (_city1Controller.text.isEmpty || _city2Controller.text.isEmpty) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final city1 = await _apiService.fetchAQIByCity(_city1Controller.text);
      final city2 = await _apiService.fetchAQIByCity(_city2Controller.text);

      setState(() {
        _city1Data = city1;
        _city2Data = city2;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildComparisonResults() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCityCard(_city1Data!)),
            const SizedBox(width: 10),
            Expanded(child: _buildCityCard(_city2Data!)),
          ],
        ),
        const SizedBox(height: 20),
        _buildComparisonChart(),
      ],
    );
  }

  Widget _buildCityCard(AQIData data) {
    final color = AppColors.getAQIColor(data.aqi);
    final status = AppColors.getAQIStatus(data.aqi);
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(data.city, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${data.aqi}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 10),
          Text(status, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const Divider(height: 20),
          _buildParamRow('PM2.5', '${data.pm2_5}'),
          _buildParamRow('PM10', '${data.pm10}'),
          _buildParamRow('Temp', '${data.temperature}°'),
        ],
      ),
    );
  }
  
  Widget _buildParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildComparisonChart() {
    // Simple visual bar comparison
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AQI Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildBar(_city1Data!),
          const SizedBox(height: 10),
          _buildBar(_city2Data!),
        ],
      ),
    );
  }
  
  Widget _buildBar(AQIData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.city, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              flex: data.aqi,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.getAQIColor(data.aqi),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Expanded(
              flex: 500 - data.aqi > 0 ? 500 - data.aqi : 0, 
              child: const SizedBox(),
            ),
            const SizedBox(width: 10),
            Text('${data.aqi}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
