import 'package:flutter/material.dart';

class LightLineChart extends StatelessWidget {
  final Map<String, List<double>> dataMap;
  final Map<String, Color> colors;
  final double threshold;
  final double height;

  const LightLineChart({
    super.key,
    required this.dataMap,
    required this.colors,
    required this.threshold,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    if (dataMap.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data')),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _MultiLineChartPainter(dataMap, colors, threshold),
      ),
    );
  }
}

class _MultiLineChartPainter extends CustomPainter {
  final Map<String, List<double>> dataMap;
  final Map<String, Color> colors;
  final double threshold;

  _MultiLineChartPainter(this.dataMap, this.colors, this.threshold);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataMap.isEmpty) return;

    int maxPoints = 0;
    double dynamicMax = 60.0;
    for (var list in dataMap.values) {
      if (list.length > maxPoints) maxPoints = list.length;
      for (var val in list) {
        if (val > dynamicMax) dynamicMax = val;
      }
    }
    if (dynamicMax < threshold * 1.5) dynamicMax = threshold * 1.5;

    final double paddingLeft = 30.0;
    final double paddingBottom = 20.0;
    final double chartWidth = size.width - paddingLeft - 10;
    final double chartHeight = size.height - paddingBottom - 10;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
      
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10);

    // Draw horizontal grid lines (Y-axis)
    int ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      double yValue = (dynamicMax / ySteps) * i;
      double yPos = 10 + chartHeight - (yValue / dynamicMax) * chartHeight;
      
      canvas.drawLine(Offset(paddingLeft, yPos), Offset(size.width - 10, yPos), gridPaint);
      
      final tp = TextPainter(
        text: TextSpan(text: yValue.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 4, yPos - tp.height / 2));
    }

    // Draw vertical grid lines (X-axis)
    final double stepX = maxPoints > 1 ? chartWidth / (maxPoints - 1) : chartWidth;
    for (int i = 0; i < maxPoints; i++) {
      double xPos = paddingLeft + (i * stepX);
      canvas.drawLine(Offset(xPos, 10), Offset(xPos, 10 + chartHeight), gridPaint);
      
      if (i % 5 == 0 || i == maxPoints - 1) {
        final tp = TextPainter(
          text: TextSpan(text: i.toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(xPos - tp.width / 2, 10 + chartHeight + 4));
      }
    }

    // Draw threshold dashed line
    final thresholdY = 10 + chartHeight - ((threshold / dynamicMax) * chartHeight);
    final thresholdPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(paddingLeft, thresholdY), Offset(size.width - 10, thresholdY), thresholdPaint);

    // Draw lines and dots
    dataMap.forEach((key, list) {
      if (list.isEmpty) return;
      final linePaint = Paint()
        ..color = colors[key] ?? Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i < list.length; i++) {
        final double x = paddingLeft + (i * stepX);
        final double normalizedY = list[i] / dynamicMax;
        final double y = 10 + chartHeight - (normalizedY * chartHeight);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
      
      for (int i = 0; i < list.length; i++) {
        final double x = paddingLeft + (i * stepX);
        final double normalizedY = list[i] / dynamicMax;
        final double y = 10 + chartHeight - (normalizedY * chartHeight);
        canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = (colors[key] ?? Colors.blue));
      }
    });
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(startX + dashWidth, p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
