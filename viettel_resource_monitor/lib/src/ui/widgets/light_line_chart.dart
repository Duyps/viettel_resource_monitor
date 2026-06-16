import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../tabs/fps_tab.dart'; // Để dùng chung model FpsDataPoint

class SemanticFpsLineChart extends StatefulWidget {
  final List<FpsDataPoint> data;
  final double threshold;

  const SemanticFpsLineChart({
    super.key, 
    required this.data,
    this.threshold = 55.0,
  });

  @override
  State<SemanticFpsLineChart> createState() => _SemanticFpsLineChartState();
}

class _SemanticFpsLineChartState extends State<SemanticFpsLineChart> {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('Đang thu thập dữ liệu khung hình...'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          // Bắt sự kiện chạm/vuốt để hiển thị Tooltip (Bong bóng thông tin)
          onPanUpdate: (details) => _updateHover(details.localPosition, constraints.maxWidth),
          onPanDown: (details) => _updateHover(details.localPosition, constraints.maxWidth),
          onPanCancel: () => setState(() => hoveredIndex = null),
          onPanEnd: (_) => setState(() => hoveredIndex = null),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _SemanticFpsPainter(
              data: widget.data,
              hoveredIndex: hoveredIndex,
              threshold: widget.threshold,
            ),
          ),
        );
      },
    );
  }

  void _updateHover(Offset localPosition, double width) {
    if (widget.data.isEmpty) return;
    
    final double paddingLeft = 40.0;
    final double chartWidth = width - paddingLeft - 10;
    
    // Nếu chạm ra ngoài lề trái, xoá tooltip
    if (localPosition.dx < paddingLeft) {
      setState(() => hoveredIndex = null);
      return;
    }
    
    // Tính toán index gần nhất
    final double stepX = widget.data.length > 1 ? chartWidth / (widget.data.length - 1) : chartWidth;
    final int index = ((localPosition.dx - paddingLeft) / stepX).round();
    
    if (index >= 0 && index < widget.data.length) {
      if (hoveredIndex != index) {
        setState(() => hoveredIndex = index);
      }
    } else {
      if (hoveredIndex != null) {
        setState(() => hoveredIndex = null);
      }
    }
  }
}

class _SemanticFpsPainter extends CustomPainter {
  final List<FpsDataPoint> data;
  final int? hoveredIndex;
  final double threshold;
  
  _SemanticFpsPainter({
    required this.data, 
    this.hoveredIndex,
    required this.threshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingLeft = 40.0;
    final double paddingBottom = 30.0;
    final double chartWidth = size.width - paddingLeft - 10;
    final double chartHeight = size.height - paddingBottom - 10;

    // Y-Axis cố định khung cao nhất là 60 FPS
    final double dynamicMax = 60.0; 

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
      
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600);

    // 1. Vẽ các đường ngang (Y-Axis) tại các mốc 60, 55, 30, 0
    final yTicks = [0.0, 30.0, threshold, 60.0];
    for (double yValue in yTicks) {
      double yPos = 10 + chartHeight - (yValue / dynamicMax) * chartHeight;
      
      if (yValue == threshold) {
        // Đường Target Line nét đứt màu xám mờ
        final thresholdPaint = Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1.5;
        _drawDashedLine(canvas, Offset(paddingLeft, yPos), Offset(size.width - 10, yPos), thresholdPaint);
      } else {
        // Line thường
        canvas.drawLine(Offset(paddingLeft, yPos), Offset(size.width - 10, yPos), gridPaint);
      }
      
      // In text (0, 30, 55, 60)
      final tp = TextPainter(
        text: TextSpan(text: yValue.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 8, yPos - tp.height / 2));
    }

    // 2. Vẽ Trục Hoành (X-Axis): Tên Màn Hình & Ranh giới (Vertical Dividers)
    final double stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    
    String? currentScreen;
    for (int i = 0; i < data.length; i++) {
      double xPos = paddingLeft + (i * stepX);
      
      // Chuyển cảnh (Sang màn hình khác)
      if (data[i].screenName != currentScreen) {
        currentScreen = data[i].screenName;
        
        // Vẽ vạch phân cách dọc
        _drawDashedLineVertical(canvas, Offset(xPos, 10), Offset(xPos, 10 + chartHeight), gridPaint);
        
        // Viết Tên Màn hình (Hành trình)
        final tp = TextPainter(
          text: TextSpan(
            text: currentScreen, 
            style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.w800)
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(xPos + 6, 10 + chartHeight + 6));
      }
    }

    // 3. Vẽ Đồ Thị Động (Dynamic Line Chart) với Semantic Colors
    for (int i = 0; i < data.length - 1; i++) {
      final p1 = data[i];
      final p2 = data[i + 1];

      final double x1 = paddingLeft + (i * stepX);
      final double y1 = 10 + chartHeight - (p1.fps.clamp(0, dynamicMax) / dynamicMax) * chartHeight;
      
      final double x2 = paddingLeft + ((i + 1) * stepX);
      final double y2 = 10 + chartHeight - (p2.fps.clamp(0, dynamicMax) / dynamicMax) * chartHeight;

      // Xác định trạng thái màu của đoạn thẳng
      final segmentAvgFps = (p1.fps + p2.fps) / 2;
      Color segmentColor = const Color(0xFF10B981); // Xanh lá (Mượt)
      
      if (segmentAvgFps < 30) {
        segmentColor = const Color(0xFFEE0000); // Viettel Red (Nguy hiểm)
      } else if (segmentAvgFps < threshold) {
        segmentColor = const Color(0xFFF59E0B); // Vàng/Cam (Cảnh báo nhẹ)
      }

      final linePaint = Paint()
        ..color = segmentColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // 4. Vẽ Bong Bóng Tĩnh: Spike Dots (Vị trí bị sụt FPS dưới 30)
    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      if (p.fps < 30) {
        final double x = paddingLeft + (i * stepX);
        final double y = 10 + chartHeight - (p.fps.clamp(0, dynamicMax) / dynamicMax) * chartHeight;
        
        // Halo mờ
        canvas.drawCircle(Offset(x, y), 6.0, Paint()..color = const Color(0xFFEE0000).withValues(alpha: 0.25));
        // Lõi đỏ đậm
        canvas.drawCircle(Offset(x, y), 3.0, Paint()..color = const Color(0xFFEE0000));
      }
    }

    // 5. Vẽ Pop-up Tooltip khi Tương tác (Hover/Touch)
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < data.length) {
      final p = data[hoveredIndex!];
      final double x = paddingLeft + (hoveredIndex! * stepX);
      final double y = 10 + chartHeight - (p.fps.clamp(0, dynamicMax) / dynamicMax) * chartHeight;

      // Vòng tròn định vị (Cắm cờ)
      canvas.drawCircle(Offset(x, y), 5.0, Paint()..color = const Color(0xFF1F2937));
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = Colors.white);

      // Kích thước hộp Tooltip
      const double tooltipWidth = 140;
      const double tooltipHeight = 65;
      
      // Auto-layout: Chống tràn cạnh trái/phải
      double tooltipX = x - tooltipWidth / 2;
      if (tooltipX < paddingLeft) tooltipX = paddingLeft;
      if (tooltipX + tooltipWidth > size.width) tooltipX = size.width - tooltipWidth - 10;
      
      // Auto-layout: Chống tràn cạnh trên (Lật xuống nếu cấn)
      double tooltipY = y - tooltipHeight - 15;
      if (tooltipY < 10) tooltipY = y + 15; 

      final tooltipRect = Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);
      
      // Bóng đổ mờ của popup
      canvas.drawShadow(Path()..addRRect(RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8))), Colors.black45, 4.0, false);
      
      // Vẽ Box
      canvas.drawRRect(RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8)), Paint()..color = const Color(0xFF1F2937));

      // Tính thời gian render 1 khung hình (Càng lâu FPS càng thấp)
      final double renderMs = p.fps > 0 ? (1000.0 / p.fps) : 0.0;

      // Chuẩn bị nội dung
      final String fpsText = '${p.fps.toStringAsFixed(1)} FPS';
      final String renderText = 'Render: ${renderMs.toStringAsFixed(1)} ms';
      final String warning = p.fps < 30 ? '⚠️ Điểm nghẽn (Jank)' : (p.fps < threshold ? '⚠️ Drop Frame' : '✅ Mượt mà');

      // In nội dung
      _drawText(canvas, fpsText, Offset(tooltipX + 12, tooltipY + 8), const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold));
      _drawText(canvas, renderText, Offset(tooltipX + 12, tooltipY + 28), TextStyle(color: Colors.grey.shade300, fontSize: 10));
      _drawText(canvas, warning, Offset(tooltipX + 12, tooltipY + 44), TextStyle(
        color: p.fps < 30 ? const Color(0xFFFCA5A5) : (p.fps < threshold ? const Color(0xFFFCD34D) : const Color(0xFF6EE7B7)), 
        fontSize: 10, 
        fontWeight: FontWeight.bold
      ));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(Offset(startX, p1.dy), Offset(startX + dashWidth, p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  void _drawDashedLineVertical(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = p1.dy;
    while (startY < p2.dy) {
      canvas.drawLine(Offset(p1.dx, startY), Offset(p1.dx, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _SemanticFpsPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex || oldDelegate.data.length != data.length;
  }
}
