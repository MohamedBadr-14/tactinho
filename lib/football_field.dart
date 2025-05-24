import 'package:flutter/material.dart';

class HalfFootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1E6C41)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Goal box
    final goalBoxWidth = size.width * 0.4;
    final goalBoxHeight = size.height * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalBoxWidth) / 2,
        0,
        goalBoxWidth,
        goalBoxHeight,
      ),
      linePaint,
    );

    // Penalty box
    final penaltyBoxWidth = size.width * 0.7;
    final penaltyBoxHeight = size.height * 0.27;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyBoxWidth) / 2,
        0,
        penaltyBoxWidth,
        penaltyBoxHeight,
      ),
      linePaint,
    );

    // Penalty spot
    final penaltySpot = Offset(size.width / 2, penaltyBoxHeight * 0.75);
    canvas.drawCircle(
      penaltySpot,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Penalty arc
    final arcRadius = penaltyBoxWidth * 0.23;
    final arcCenter = Offset(size.width / 2, penaltyBoxHeight);
    final arcRect = Rect.fromCircle(center: arcCenter, radius: arcRadius);
    canvas.drawArc(arcRect, 3.14, -3.14, false, linePaint);

    // End line
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height - 2),
      linePaint,
    );

    // Half circle at end line
    final centerRadius = size.width * 0.2;
    final arcCenter2 = Offset(size.width / 2, size.height - 2);
    final arcRect2 = Rect.fromCircle(center: arcCenter2, radius: centerRadius);
    canvas.drawArc(arcRect2, -3.14, 3.14, false, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
