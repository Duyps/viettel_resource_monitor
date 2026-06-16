import 'package:flutter/material.dart';
import '../../models/screen_session.dart';
import '../widgets/light_line_chart.dart';

class FpsDataPoint {
  final double fps;
  final String screenName;
  final DateTime timestamp;

  FpsDataPoint({
    required this.fps,
    required this.screenName,
    required this.timestamp,
  });
}

class FpsTab extends StatefulWidget {
  final List<ScreenSession> allSessions;

  const FpsTab({super.key, required this.allSessions});

  @override
  State<FpsTab> createState() => _FpsTabState();
}

class _FpsTabState extends State<FpsTab> {
  String? _selectedRoute;
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollEnabled = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _autoScrollEnabled) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    if (widget.allSessions.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu hiệu năng khung hình',
          style: TextStyle(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    const viettelRed = Color(0xFFEE0000);
    const grayBorder = Color(0xFFE5E7EB);
    const textDark = Color(0xFF1F2937);

    // 1. TỔNG HỢP DỮ LIỆU THÀNH CHUỖI THỜI GIAN (SEMANTIC TIMELINE)
    final List<FpsDataPoint> timelinePoints = [];
    final List<String> allRoutes = [];

    // Lọc và sắp xếp toàn bộ dữ liệu từ các session
    final sortedSessions = List<ScreenSession>.from(widget.allSessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (var session in sortedSessions) {
      final cleanName = session.screenName.replaceAll('Screen', '');
      if (!allRoutes.contains(cleanName) && cleanName.isNotEmpty) {
        allRoutes.add(cleanName);
      }

      for (var m in session.resourceMetrics) {
        timelinePoints.add(FpsDataPoint(
          fps: m.fps,
          screenName: cleanName,
          timestamp: m.timestamp,
        ));
      }
    }

    // 2. LỌC DỮ LIỆU THEO ROUTE
    List<FpsDataPoint> filteredPoints = timelinePoints;
    if (_selectedRoute != null) {
      filteredPoints = timelinePoints.where((p) => p.screenName == _selectedRoute).toList();
    }

    // 3. TÍNH BẢNG THỐNG KÊ CHI TIẾT
    final Map<String, _FpsTableData> tableAnalysisMap = {};
    for (var session in sortedSessions) {
      final cleanName = session.screenName.replaceAll('Screen', '');
      if (session.resourceMetrics.isEmpty) continue;

      double totalFps = 0;
      double minFps = 60;
      int dropFramesCount = 0;

      for (var m in session.resourceMetrics) {
        totalFps += m.fps;
        if (m.fps < minFps) minFps = m.fps;
        if (m.fps < 55) dropFramesCount++;
      }

      double avgFps = totalFps / session.resourceMetrics.length;

      if (tableAnalysisMap.containsKey(cleanName)) {
        final existing = tableAnalysisMap[cleanName]!;
        tableAnalysisMap[cleanName] = _FpsTableData(
          screenName: cleanName,
          avgFps: (avgFps + existing.avgFps) / 2,
          minFps: minFps < existing.minFps ? minFps : existing.minFps,
          dropCount: dropFramesCount + existing.dropCount,
        );
      } else {
        tableAnalysisMap[cleanName] = _FpsTableData(
          screenName: cleanName,
          avgFps: avgFps,
          minFps: minFps,
          dropCount: dropFramesCount,
        );
      }
    }

    List<_FpsTableData> filteredTableList = tableAnalysisMap.values.toList();
    if (_selectedRoute != null) {
      filteredTableList = filteredTableList.where((data) => data.screenName == _selectedRoute).toList();
    }

    // Độ rộng biểu đồ tự mở rộng theo số lượng điểm (mỗi giây = 40px cho dễ nhìn)
    final double minChartWidth = MediaQuery.of(context).size.width - 32;
    double chartWidth = filteredPoints.length > 2 ? filteredPoints.length * 40.0 : minChartWidth;
    if (chartWidth < minChartWidth) chartWidth = minChartWidth;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Khối tiêu đề
        const Text(
          'Hành Trình Giao Diện (Semantic Timeline)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'Theo dõi độ mượt mà theo từng màn hình thực tế. Đổi màu Đỏ khi <30 FPS, Vàng <55 FPS. Chạm vào điểm neo để xem chi tiết.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Bộ lọc Route (ChoiceChips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Toàn bộ hành trình'),
                selected: _selectedRoute == null,
                selectedColor: viettelRed.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: _selectedRoute == null ? viettelRed : textDark,
                  fontWeight: _selectedRoute == null ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _selectedRoute == null ? viettelRed.withValues(alpha: 0.5) : grayBorder),
                ),
                onSelected: (selected) {
                  setState(() => _selectedRoute = null);
                },
              ),
              const SizedBox(width: 8),
              ...allRoutes.map((route) {
                final isSelected = _selectedRoute == route;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(route),
                    selected: isSelected,
                    selectedColor: viettelRed.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? viettelRed : textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? viettelRed.withValues(alpha: 0.5) : grayBorder),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoute = selected ? route : null;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // BIỂU ĐỒ ĐƯỜNG LIÊN TỤC
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grayBorder, width: 1),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                // Người dùng chủ động vuốt ngược về quá khứ -> Tắt auto scroll
                if (notification.metrics.pixels < notification.metrics.maxScrollExtent - 20) {
                  _autoScrollEnabled = false;
                }
              }
              // Nếu người dùng vuốt trạm đáy (bên phải) -> Bật lại auto scroll
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 10) {
                _autoScrollEnabled = true;
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: SemanticFpsLineChart(
                  data: filteredPoints,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Chú thích (Legend)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Mượt (>55)', const Color(0xFF10B981)),
            const SizedBox(width: 16),
            _buildLegendItem('Jank nhẹ (30-55)', const Color(0xFFF59E0B)),
            const SizedBox(width: 16),
            _buildLegendItem('Điểm nghẽn (<30)', viettelRed),
          ],
        ),

        const SizedBox(height: 28),

        // BẢNG THỐNG KÊ CHI TIẾT
        const Text(
          'Thống kê chi tiết đối chiếu',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textDark),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grayBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: grayBorder, width: 1),
                verticalInside: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    _buildTableCell('Màn hình / Tuyến', isHeader: true),
                    _buildTableCell('FPS TB', isHeader: true),
                    _buildTableCell('Thấp nhất', isHeader: true),
                    _buildTableCell('Sụt < 55', isHeader: true),
                  ],
                ),
                ...filteredTableList.map((data) {
                  final bool isSevereJank = data.minFps < 30;

                  return TableRow(
                    children: [
                      _buildTableCell(data.screenName),
                      _buildTableCell(data.avgFps.toStringAsFixed(1), isBold: true),
                      _buildTableCell(
                        data.minFps.toStringAsFixed(0),
                        color: isSevereJank ? viettelRed : null,
                        isBold: isSevereJank,
                      ),
                      _buildTableCell(
                        '${data.dropCount}',
                        color: data.dropCount > 10 ? viettelRed : (data.dropCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                        isBold: data.dropCount > 10,
                        suffix: ' lần',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    Color? color,
    bool isBold = false,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: RichText(
              textAlign: isHeader ? TextAlign.left : TextAlign.start,
              text: TextSpan(
                text: text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isHeader ? FontWeight.w700 : (isBold ? FontWeight.bold : FontWeight.w500),
                  color: isHeader ? const Color(0xFF4B5563) : (color ?? const Color(0xFF1F2937)),
                  fontFeatures: isHeader ? null : const [FontFeature.tabularFigures()],
                ),
                children: [
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: suffix,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FpsTableData {
  final String screenName;
  final double avgFps;
  final double minFps;
  final int dropCount;

  _FpsTableData({
    required this.screenName,
    required this.avgFps,
    required this.minFps,
    required this.dropCount,
  });
}
