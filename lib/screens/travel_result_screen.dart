import 'package:flutter/material.dart';
import '../models/travel_recommendation.dart';

class TravelResultScreen extends StatelessWidget {
  final TravelRecommendation recommendation;

  const TravelResultScreen({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(recommendation.riskLevel);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Report: ${recommendation.city}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Risk Score Card
            _buildRiskScoreCard(context, riskColor),
            
            const SizedBox(height: 16),

            // 2. Best Time to Visit
            if (recommendation.bestDates.isNotEmpty)
              _buildSectionResult(
                context, 
                'Best Time to Visit', 
                Icons.calendar_month, 
                Colors.green,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recommendation.bestDates.map((date) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(date, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )).toList(),
                )
              ),

            // 3. City Comparison (if available)
            if (recommendation.comparison != null)
              _buildSectionResult(
                context,
                'City Comparison',
                Icons.compare_arrows,
                Colors.blue,
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('City', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('AQI', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Suggestion', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    _buildComparisonRow(
                      recommendation.city, 
                      recommendation.averageAqi, 
                      recommendation.riskLevel,
                      isTarget: true,
                    ),
                    _buildComparisonRow(
                      recommendation.comparison!.city, 
                      recommendation.comparison!.averageAqi, 
                      recommendation.comparison!.riskLevel,
                    ),
                  ],
                ),
              ),

             const SizedBox(height: 16),

            // 4. Season Alert (if any)
            if (recommendation.seasonAlert != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation.seasonAlert!,
                        style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

             const SizedBox(height: 8),

            // 4. Health Advisories
            _buildSectionResult(
              context, 
              'Health Advisory', 
              Icons.medical_services_outlined, 
              Colors.redAccent,
              Column(
                children: recommendation.advisories.map((advice) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Icon(Icons.health_and_safety_outlined, color: Colors.grey.shade700, size: 20),
                        const SizedBox(width: 8),
                         Expanded(child: Text(advice, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  )).toList(),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard(BuildContext context, Color color) {
    String riskText = recommendation.riskLevel.name.toUpperCase();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Travel Risk Score',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              riskText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average AQI: ${recommendation.averageAqi}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
             const SizedBox(height: 16),
             // Simple Gauge Visual
             LinearProgressIndicator(
               value: _getRiskValue(recommendation.riskLevel),
               backgroundColor: Colors.white30,
               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
               minHeight: 8,
               borderRadius: BorderRadius.circular(4),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionResult(BuildContext context, String title, IconData icon, Color iconColor, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(TravelRiskLevel level) {
    switch (level) {
      case TravelRiskLevel.low:
        return const Color(0xFF00B050); // Green
      case TravelRiskLevel.moderate:
        return const Color(0xFFFFC107); // Amber/Yellow
      case TravelRiskLevel.high:
        return const Color(0xFFFF9900); // Orange
      case TravelRiskLevel.severe:
        return const Color(0xFFC00000); // Red
    }
  }
  
  double _getRiskValue(TravelRiskLevel level) {
     switch (level) {
      case TravelRiskLevel.low: return 0.25;
      case TravelRiskLevel.moderate: return 0.50;
      case TravelRiskLevel.high: return 0.75;
      case TravelRiskLevel.severe: return 1.0;
    }
  }

  TableRow _buildComparisonRow(String city, int aqi, TravelRiskLevel risk, {bool isTarget = false}) {
    return TableRow(
      decoration: isTarget ? BoxDecoration(color: _getRiskColor(risk).withOpacity(0.1)) : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(city, style: TextStyle(fontWeight: isTarget ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('$aqi', style: TextStyle(fontWeight: FontWeight.bold, color: _getRiskColor(risk))),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            risk == TravelRiskLevel.low ? 'Good' : 
            risk == TravelRiskLevel.moderate ? 'Moderate' : 
            risk == TravelRiskLevel.high ? 'Caution' : 'Avoid',
            style: TextStyle(
              color: _getRiskColor(risk),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
