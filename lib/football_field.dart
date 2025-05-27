import 'package:flutter/material.dart';
import 'dart:math' as math;

class HalfFootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fieldWidth = size.width;
    final fieldHeight = size.height;
    
    // Calculate scaling factors to map coordinates to actual pixel positions
    // Field dimensions: 90 width × 60 height
    final scaleX = fieldWidth / 90.0;
    final scaleY = fieldHeight / 60.0;
    
    // Field colors
    final grassColor = Color(0xFF1E6C41);
    final grassColorAlt = Color(0xFF1A5D38); // Slightly darker alternate color
    final lineColor = Colors.white;
    
    // Paint setup
    final fieldPaint = Paint()..color = grassColor;
    final fieldPaintAlt = Paint()..color = grassColorAlt;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw striped grass background
    final stripHeight = 3.3 * scaleY;
    final numStrips = (fieldHeight / stripHeight).ceil() + 1;
    
    for (int i = 0; i < numStrips; i++) {
      final stripY = i * stripHeight;
      final stripRect = Rect.fromLTWH(0, stripY, fieldWidth, stripHeight);
      canvas.drawRect(
        stripRect,
        i % 2 == 0 ? fieldPaint : fieldPaintAlt,
      );
    }
    
    // Draw field outline
    canvas.drawRect(Rect.fromLTWH(0, 0, fieldWidth, fieldHeight), linePaint);
    
    // Draw halfway line (bottom edge)
    canvas.drawLine(
      Offset(0, fieldHeight),
      Offset(fieldWidth, fieldHeight),
      linePaint,
    );
    
    // Draw center circle (half of it at the bottom edge)
    final centerY = fieldHeight;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(fieldWidth / 2, centerY),
        width: 18.3 * scaleX,
        height: 18.3 * scaleY,
      ),
      -math.pi, // Start from left side
      math.pi, // Half circle
      false,
      linePaint,
    );
    
    // Calculate penalty area coordinates
    final penaltySpotX = fieldWidth / 2;
    final penaltySpotY = 11 * scaleY; // 11m from goal line
    
    // Draw penalty area (18-yard box)
    final penAreaWidth = 40.3 * scaleX; // 40.3m width
    final penAreaHeight = 16.5 * scaleY; // 16.5m length
    final penAreaLeft = (fieldWidth - penAreaWidth) / 2;
    final penAreaTop = 0;
    
    canvas.drawRect(
      Rect.fromLTWH(penAreaLeft, penAreaTop.toDouble(), penAreaWidth, penAreaHeight),
      linePaint,
    );
    
    // Draw goal area (6-yard box)
    final goalAreaWidth = 18.3 * scaleX; // 18.3m width
    final goalAreaHeight = 5.5 * scaleY; // 5.5m length
    final goalAreaLeft = (fieldWidth - goalAreaWidth) / 2;
    final goalAreaTop = 0;
    
    canvas.drawRect(
      Rect.fromLTWH(goalAreaLeft, goalAreaTop.toDouble(), goalAreaWidth, goalAreaHeight),
      linePaint,
    );
    
    // Draw penalty spot
    canvas.drawCircle(
      Offset(penaltySpotX, penaltySpotY),
      scaleY / 2, // Small penalty spot
      Paint()..color = lineColor,
    );
    
    // Draw the penalty arc
    final arcRadius = 9.15 * scaleY;
    final arcCenter = Offset(penaltySpotX, penaltySpotY);
        
    // Calculate the angles where the arc intersects the penalty area
    final penAreaBottom = penAreaTop + penAreaHeight;

    // Calculate the start and end angles for the arc
    final halfArcWidth = math.sqrt(math.pow(arcRadius, 2) - math.pow(penAreaBottom - penaltySpotY, 2));
    final startAngle = math.pi - math.asin((penAreaBottom - penaltySpotY) / arcRadius);
    final endAngle = math.pi/4.9;

    // Draw the penalty arc (only the part outside the penalty area)
    final arcPath = Path()
      ..moveTo(penaltySpotX - halfArcWidth, penAreaBottom)
      ..arcTo(
        Rect.fromCircle(center: arcCenter, radius: arcRadius),
        startAngle,
        endAngle - startAngle,
        false
      );

    canvas.drawPath(arcPath, linePaint);
    
    // Draw goal line
    canvas.drawLine(
      Offset(0, 0),
      Offset(fieldWidth, 0),
      linePaint,
    );
    
    // Draw goal
    final goalWidth = 7.3 * scaleX; // 7.3m (standard goal width)
    final goalHeight = 2.0 * scaleY; // 2m depth for visual representation
    final goalLeft = (fieldWidth - goalWidth) / 2;
    
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, -goalHeight, goalWidth, goalHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}