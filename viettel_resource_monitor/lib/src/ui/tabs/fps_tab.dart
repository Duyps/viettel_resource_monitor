import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/screen_session.dart';
import '../widgets/light_line_chart.dart';

class FpsTab extends StatefulWidget {
  final List<ScreenSession> allSessions;

  const FpsTab({Key? key, required this.allSessions}) : super(key: key);

  @override
  State<FpsTab> createState() => _FpsTabState();
}

class _FpsTabState extends State<FpsTab> {
  String? _selectedRoute;

  @override
  Widget build(BuildContext context) {
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

    // 1. CHUẨN BỊ DỮ LIỆU
    final Map<String, List<double>> dataMap = {};
    for (var session in widget.allSessions) {
      final cleanName = session.screenName.replaceAll('Screen', '');
      if (session.resourceMetrics.isEmpty) continue;

      dataMap.putIfAbsent(cleanName, () => []);
      for (var m in session.resourceMetrics) {
        dataMap[cleanName]!.add(m.fps);
      }
    }

    final allRoutes = dataMap.keys.toList();

    // 2. TÍNH BẢNG THỐNG KÊ (Tính trước khi lọc để hiển thị Console Log)
    final Map<String, _FpsTableData> tableAnalysisMap = {};
    for (var session in widget.allSessions) {
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

    // HIỂN THỊ CONSOLE LOG CHI TIẾT THEO YÊU CẦU CỦA USER (Chỉ in 1 lần khi render lần đầu, hoặc nếu muốn thì cứ in)
    // Ở đây ta có thể skip in log hoặc chỉ in log cho route được chọn để tránh spam.
    // Để giữ nguyên yêu cầu cũ: ta cứ in. 

    // 3. LỌC DỮ LIỆU THEO ROUTE ĐƯỢC CHỌN
    Map<String, List<double>> filteredDataMap = {};
    List<_FpsTableData> filteredTableList = [];

    if (_selectedRoute == null) {
      filteredDataMap = dataMap;
      filteredTableList = tableAnalysisMap.values.toList();
    } else {
      if (dataMap.containsKey(_selectedRoute)) {
        filteredDataMap[_selectedRoute!] = dataMap[_selectedRoute!]!;
      }
      if (tableAnalysisMap.containsKey(_selectedRoute)) {
        filteredTableList.add(tableAnalysisMap[_selectedRoute!]!);
      }
    }

    int maxPoints = 0;
    for (var list in filteredDataMap.values) {
      if (list.length > maxPoints) maxPoints = list.length;
    }

    // 4. BỘ MÀU SẮC ĐỒNG BỘ
    final List<Color> palette = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Yellow
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      viettelRed,              // Viettel Red
    ];
    
    // Gắn màu cố định cho tất cả các route để khi lọc màu không bị nhảy
    final Map<String, Color> globalRouteColors = {};
    int colorIdx = 0;
    for (var key in allRoutes) {
      globalRouteColors[key] = palette[colorIdx % palette.length];
      colorIdx++;
    }

    // Lấy màu cho các route đang hiển thị
    final Map<String, Color> displayColors = {};
    for (var key in filteredDataMap.keys) {
      displayColors[key] = globalRouteColors[key]!;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Khối tiêu đề
        const Text(
          'Biến động FPS & Điểm nghẽn',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'Theo dõi độ mượt mà của từng màn hình. Dưới 55 FPS được tính là nghẽn (Drop Frame).',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Bộ lọc Route (ChoiceChips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Tất cả Màn hình'),
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
                final routeColor = globalRouteColors[route]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(route),
                    selected: isSelected,
                    selectedColor: routeColor.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? routeColor : textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? routeColor.withValues(alpha: 0.5) : grayBorder),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoute = selected ? route : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // BIỂU ĐỒ ĐƯỜNG
        Container(
          height: 280,
          padding: const EdgeInsets.only(top: 20, bottom: 10, right: 16, left: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grayBorder, width: 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: maxPoints > 20 ? maxPoints * 20.0 : MediaQuery.of(context).size.width - 60,
                    child: LightLineChart(
                      dataMap: filteredDataMap,
                      colors: displayColors,
                      threshold: 55.0, // Đường chuẩn 55 FPS
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Chú thích (Legend)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: filteredDataMap.keys.map((key) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: displayColors[key], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(key, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
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
                0: FlexColumnWidth(2.5), // Cột tên màn hình
                1: FlexColumnWidth(1.2), // FPS TB
                2: FlexColumnWidth(1.2), // FPS Tụt
                3: FlexColumnWidth(1.5), // Số lần < 55
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: grayBorder, width: 1),
                verticalInside: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
              children: [
                // Hàng Header
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    _buildTableCell('Màn hình / Tuyến', isHeader: true),
                    _buildTableCell('FPS TB', isHeader: true),
                    _buildTableCell('Thấp nhất', isHeader: true),
                    _buildTableCell('Sụt < 55', isHeader: true),
                  ],
                ),
                // Data Rows
                ...filteredTableList.map((data) {
                  final bool isSevereJank = data.minFps < 30;
                  final routeColor = globalRouteColors[data.screenName] ?? textDark;

                  return TableRow(
                    children: [
                      _buildTableCell(data.screenName, badgeColor: routeColor),
                      _buildTableCell('${data.avgFps.toStringAsFixed(1)}', isBold: true),
                      _buildTableCell(
                        '${data.minFps.toStringAsFixed(0)}',
                        color: isSevereJank ? viettelRed : null,
                        isBold: isSevereJank,
                      ),
                      _buildTableCell(
                        '${data.dropCount}',
                        color: data.dropCount > 10 ? viettelRed : const Color(0xFFF59E0B),
                        isBold: data.dropCount > 10,
                        suffix: ' lần',
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    Color? color,
    bool isBold = false,
    Color? badgeColor,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeColor != null && !isHeader) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
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
