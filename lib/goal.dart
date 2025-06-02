import 'package:flutter/material.dart';
import 'dart:math' as math;

class Goal extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fieldWidth = size.width;
    final fieldHeight = size.height; 

    final scaleX = fieldWidth / 60.0;
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

  
    // Draw goal
    final goalWidth = 7.3 * scaleX; // 7.3m (standard goal width)
    final goalHeight = 4.0 * scaleY; // 2m depth for visual representation
    final goalLeft = (fieldWidth - goalWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(goalLeft, fieldHeight - goalHeight, goalWidth, goalHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
