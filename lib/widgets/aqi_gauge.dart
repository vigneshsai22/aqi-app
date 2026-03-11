import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_colors.dart';

class AQIGauge extends StatelessWidget {
  final int aqi;
  final String city;
  final String status;

  const AQIGauge({
    super.key,
    required this.aqi,
    required this.city,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          height: 140, // Height is roughly half width + padding
          child: CustomPaint(
            painter: _GaugePainter(aqi: aqi),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$aqi',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'AQI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
         Text(
          status,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.getAQIColor(aqi),
          ),
        ),
        const SizedBox(height: 8),
         Text(
          city,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black54, // Changed from white to black54 for visibility on white card
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int aqi;

  _GaugePainter({required this.aqi});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final strokeWidth = 20.0;
    
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // 1. Draw Arcs (AQI Segments)
    // Map AQI 0-500 to Angle 180 (Pi) to 0 (0) --> Wait, Draw starts from Right(0) usually in Flutter?
    // standard Arc: 0 is Right, PI is Left.
    // We want semi-circle from PI (Left) to 2*PI (Right)? No, usually Top is 3PI/2.
    // Let's us startAngle = Pi (Left), sweepAngle = Pi (180 deg).
    
    // Segments: 
    // Good (0-50): Green
    // Satisfactory (51-100): Light Green
    // Moderate (101-200): Yellow
    // Poor (201-300): Orange
    // Very Poor (301-400): Red
    // Severe (401-500): Dark Red
    
    // Total AQI Range visual: 0 to 500.
    // But physically, 0-50 might be smaller than 100-200? 
    // Usually gauges are linear in visual angle.
    // Let's assume visual range is 0 to 500.
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; // Segments touch each other

    void drawSegment(Color color, double startVal, double endVal) {
      paint.color = color;
      
      // Convert Value to Angle
      // Angle Range: Pi (Left, 180 deg) to 2*Pi (Right, 360 deg) -> Wait, 0 is East.
      // We want arc from West (Pi) clockwise to East (2*Pi) ? No, that's bottom half.
      // Top half is Pi to 2*Pi? Clockwise from Pi goes to Bottom.
      // Clockwise from Pi (Left) -> we want to go clockwise to 0 (Right) via Top? No.
      // Flutter drawArc: startAngle, sweepAngle.
      // 0 is East. Pi is West.
      // To draw top half: Start from Pi (West), Sweep Pi (180 deg) Clockwise.
      
      // Let's map 0-500 linear to 0-180 degrees.
      double startAngle = pi + (startVal / 500) * pi;
      double sweepAngle = ((endVal - startVal) / 500) * pi;
      
      // Correction: If endVal > 500 (unlikely but safe), cap it.
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
    
    // Drawing segments (Standard AQI colors)
    drawSegment(const Color(0xFF00E400), 0, 50); // Good
    drawSegment(const Color(0xFFFFFF00), 50, 100); // Moderate (Yellow)
    drawSegment(const Color(0xFFFF7E00), 100, 150); // Unhealthy for Sensitive (Orange) - wait, standard is 100-150? Indian is different.
    // Using Indian AQI logic from AppColors roughly or Standard US EPA?
    // Image shows: Green, Yellow, Orange, Red, Purple, Maroon.
    // Let's stick to AppColors colors but linear mapping?
    // AppColors: 0-50, 51-100, 101-200, 201-300, 301-400, 401+
    
    drawSegment(const Color(0xFF00B050), 0, 50);
    drawSegment(const Color(0xFF92D050), 50, 100);
    drawSegment(const Color(0xFFFFC107), 100, 200);
    drawSegment(const Color(0xFFFF9900), 200, 300);
    drawSegment(const Color(0xFFFF0000), 300, 400);
    drawSegment(const Color(0xFFC00000), 400, 500);

    // 2. Draw Separators (White lines)
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    for (var val in [50, 100, 200, 300, 400]) {
      double angle = pi + (val / 500) * pi;
      Offset p1 = center + Offset(cos(angle), sin(angle)) * (radius - strokeWidth);
      Offset p2 = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawLine(p1, p2, paint);
    }

    // 3. Draw Needle
    // Clamp value 0-500
    double val = aqi.toDouble().clamp(0, 500);
    double needleAngle = pi + (val / 500) * pi;
    
    final needlePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
      
    final needleLength = radius - 5;
    final needleBackLen = 0.0; // Pivot at center
    
    // Calculate tip
    Offset tip = center + Offset(cos(needleAngle), sin(needleAngle)) * needleLength;
    
    // Calculate base triangle (width 10)
    // Perpendicular angle
    double perpAngle = needleAngle + pi / 2;
    Offset base1 = center + Offset(cos(perpAngle), sin(perpAngle)) * 6;
    Offset base2 = center + Offset(cos(perpAngle + pi), sin(perpAngle + pi)) * 6;
    
    final path = Path()
      ..moveTo(base1.dx, base1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
      
    canvas.drawPath(path, needlePaint);
    
    // 4. Draw Center Pivot
    canvas.drawCircle(center, 8, needlePaint..color = Colors.white);
    canvas.drawCircle(center, 4, needlePaint..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
