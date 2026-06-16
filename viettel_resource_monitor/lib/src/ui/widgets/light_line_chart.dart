import 'package:flutter/material.dart';
import 'dart:math';

class LightLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double threshold;
  final double height;

  const LightLineChart({
    Key? key,
    required this.data,
    required this.color,
    required this.threshold,
    this.height = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height, child: const Center(child: Text('No data')));

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _LineChartPainter(data, color, threshold),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Text('Timeline →', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          )
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double threshold;

  _LineChartPainter(this.data, this.color, this.threshold);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double dynamicMax = data.reduce(max);
    if (dynamicMax < threshold * 1.5) dynamicMax = threshold * 1.5;
    if (dynamicMax == 0) dynamicMax = 1;

    final double stepX = size.width / (data.length > 1 ? data.length - 1 : 1);

    // Draw threshold line
    final thresholdY = size.height - ((threshold / dynamicMax) * size.height);
    final thresholdPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, thresholdY), Offset(size.width, thresholdY), thresholdPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double normalizedY = data[i] / dynamicMax;
      final double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(Offset(startX, p1.dy), Offset(startX + dashWidth, p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


