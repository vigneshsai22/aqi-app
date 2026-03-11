import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/commute_service.dart';
import '../models/aqi_data.dart';
import '../models/commute_model.dart';
import '../utils/app_colors.dart';

class CommuteScreen extends StatefulWidget {
  const CommuteScreen({super.key});

  @override
  State<CommuteScreen> createState() => _CommuteScreenState();
}

class _CommuteScreenState extends State<CommuteScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  TransportMode _selectedMode = TransportMode.car;
  bool _isLoading = false;
  ExposureResult? _result;
  final ApiService _apiService = ApiService();

  Future<void> _calculateExposure() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // 1. Fetch AQI for Start and End
      // In a real app we might want to check if start/end are same to avoid double fetch if unnecessary, 
      // but users might type distinct areas even in same city (which our API might not distinct well without full address, 
      // but let's assume city-level or locality-level for now).
      
      final startData = await _apiService.fetchAQIByCity(_originController.text);
      final endData = await _apiService.fetchAQIByCity(_destinationController.text);
      
      double duration = double.tryParse(_durationController.text) ?? 30.0;

      // 2. Calculate
      final result = CommuteService.calculateExposure(
        startData: startData,
        endData: endData,
        mode: _selectedMode,
        durationMinutes: duration,
      );

      setState(() {
        _result = result;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commute Exposure'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const Text(
                'Calculute Your Intake',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Estimate how much pollution you inhale during your daily commute.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
          
              // Inputs
              _buildTextField(_originController, 'Start Location', Icons.home_outlined),
              const SizedBox(height: 16),
              _buildTextField(_destinationController, 'Destination', Icons.work_outline),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<TransportMode>(
                      value: _selectedMode,
                      decoration: InputDecoration(
                        labelText: 'Mode',
                        prefixIcon: const Icon(Icons.directions_car_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      items: TransportMode.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(mode.name, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMode = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(_durationController, 'Mins', Icons.timer_outlined, isNumber: true),
                  ),
                ],
              ),
          
              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _calculateExposure,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Calculate Exposure'),
                ),
              ),
          
              const SizedBox(height: 32),
          
              // Results
              if (_result != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    Color color = Colors.green;
    if (r.riskLevel == 'Moderate') color = Colors.orange;
    if (r.riskLevel == 'High') color = Colors.deepOrange;
    if (r.riskLevel == 'Severe') color = Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
        child: Column(
          children: [
            Text(
              'Exposure Risk: ${r.riskLevel}',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Intake', '${r.dosageMicrograms} µg', Icons.air),
                _buildStat('Cigarettes', '≈ ${r.cigaretteEquivalents.toStringAsFixed(1)}', Icons.smoking_rooms),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                const SizedBox(width: 12),
                Expanded(child: Text(r.recommendation, style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
