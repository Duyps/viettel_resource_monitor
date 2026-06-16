import 'package:flutter/material.dart';
import '../../models/screen_session.dart';

class RamCpuTab extends StatelessWidget {
  final List<ScreenSession> allSessions;

  const RamCpuTab({super.key, required this.allSessions});

  @override
  Widget build(BuildContext context) {
    if (allSessions.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu phiên làm việc',
          style: TextStyle(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    const viettelRed = Color(0xFFEE0000);
    const cpuBlue = Color(0xFF3B82F6);
    const grayBorder = Color(0xFFE5E7EB);
    const textDark = Color(0xFF1F2937);

    // 1. TỔNG HỢP DỮ LIỆU
    final Map<String, _ScreenSummaryData> summaryMap = {};

    for (var session in allSessions) {
      final cleanName = session.screenName.replaceAll('Screen', '');
      if (session.resourceMetrics.isEmpty) continue;

      double totalCpu = 0;
      double peakCpu = 0;
      double peakRam = 0;

      for (var m in session.resourceMetrics) {
        totalCpu += m.cpuUsagePercentage;
        if (m.cpuUsagePercentage > peakCpu) peakCpu = m.cpuUsagePercentage;
        if (m.memoryUsageMB > peakRam) peakRam = m.memoryUsageMB;
      }

      double avgCpu = totalCpu / session.resourceMetrics.length;

      if (summaryMap.containsKey(cleanName)) {
        final existing = summaryMap[cleanName]!;
        summaryMap[cleanName] = _ScreenSummaryData(
          screenName: cleanName,
          maxRam: peakRam > existing.maxRam ? peakRam : existing.maxRam,
          maxCpu: peakCpu > existing.maxCpu ? peakCpu : existing.maxCpu,
          avgCpu: (avgCpu + existing.avgCpu) / 2,
        );
      } else {
        summaryMap[cleanName] = _ScreenSummaryData(
          screenName: cleanName,
          maxRam: peakRam,
          maxCpu: peakCpu,
          avgCpu: avgCpu,
        );
      }
    }

    final displayList = summaryMap.values.toList();

    if (displayList.isEmpty) {
      return const Center(child: Text('Chưa thu thập đủ chỉ số tài nguyên.'));
    }

    // 2. TÌM GIÁ TRỊ LỚN NHẤT LÀM THANG ĐO CHIỀU NGANG BIỂU ĐỒ (TRỤC X)
    double globalMaxRam = displayList.map((e) => e.maxRam).reduce((a, b) => a > b ? a : b);
    double globalMaxCpu = displayList.map((e) => e.maxCpu).reduce((a, b) => a > b ? a : b);
    
    if (globalMaxRam == 0) globalMaxRam = 1;
    if (globalMaxCpu == 0) globalMaxCpu = 1;

    // Dành thêm 10% khoảng trống cuối biểu đồ cho đẹp
    final maxRamScale = globalMaxRam * 1.1; 
    final maxCpuScale = globalMaxCpu * 1.1;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Tiêu đề
        const Text(
          'Phân tích Phụ tải Hệ thống',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'Biểu đồ cột ngang (Horizontal Bar Chart) so sánh mức tiêu thụ tài nguyên phần cứng cực đại giữa các giao diện.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 24),

        // BIỂU ĐỒ CỘT NGANG (HORIZONTAL GROUPED BAR CHART)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grayBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildLegendItem('RAM Đỉnh (MB)', viettelRed),
                  const SizedBox(width: 16),
                  _buildLegendItem('CPU Đỉnh (%)', cpuBlue),
                ],
              ),
              const SizedBox(height: 24),
              
              // Trục vẽ biểu đồ
              ...displayList.map((data) {
                // Tỷ lệ cho cột
                final double ramRatio = data.maxRam / maxRamScale;
                final double cpuRatio = data.maxCpu / maxCpuScale;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Trục Y: Nhãn Tên màn hình
                      SizedBox(
                        width: 90,
                        child: Text(
                          data.screenName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Trục X: Các thanh Bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cột RAM (Màu đỏ)
                            Row(
                              children: [
                                Expanded(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: ramRatio.clamp(0.01, 1.0),
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: viettelRed,
                                        borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  data.maxRam.toStringAsFixed(0),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // Khoảng cách giữa 2 cột trong cùng nhóm
                            
                            // Cột CPU (Màu xanh)
                            Row(
                              children: [
                                Expanded(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: cpuRatio.clamp(0.01, 1.0),
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: cpuBlue,
                                        borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${data.maxCpu.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // BẢNG SỐ LIỆU ĐỐI CHIẾU CHI TIẾT
        const Text(
          'Bảng chi tiết thông số',
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
                0: FlexColumnWidth(2.0), 
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: grayBorder, width: 1),
                verticalInside: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    _buildTableCell('Màn hình', isHeader: true),
                    _buildTableCell('RAM Đỉnh', isHeader: true),
                    _buildTableCell('CPU Đỉnh', isHeader: true),
                    _buildTableCell('CPU TB', isHeader: true),
                  ],
                ),
                // Data
                ...displayList.map((data) {
                  return TableRow(
                    children: [
                      _buildTableCell(data.screenName),
                      _buildTableCell(
                        data.maxRam.toStringAsFixed(0),
                        isBold: true,
                        color: viettelRed,
                        suffix: ' MB',
                      ),
                      _buildTableCell(
                        data.maxCpu.toStringAsFixed(1),
                        isBold: true,
                        color: cpuBlue,
                        suffix: ' %',
                      ),
                      _buildTableCell(
                        data.avgCpu.toStringAsFixed(1),
                        color: Colors.grey.shade700,
                        suffix: ' %',
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
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
    );
  }
}

class _ScreenSummaryData {
  final String screenName;
  final double maxRam;
  final double maxCpu;
  final double avgCpu;

  _ScreenSummaryData({
    required this.screenName,
    required this.maxRam,
    required this.maxCpu,
    required this.avgCpu,
  });
}
