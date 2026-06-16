import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/screen_session.dart';

class RamCpuTab extends StatelessWidget {
  final List<ScreenSession> allSessions;

  const RamCpuTab({Key? key, required this.allSessions}) : super(key: key);

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

    // Định nghĩa màu sắc tối giản hệ thống Viettel DMS
    const viettelRed = Color(0xFFEE0000);
    const cpuBlue = Color(0xFF3B82F6);
    const grayBorder = Color(0xFFE5E7EB);

    // Xử lý và nhóm số liệu thống kê cho từng màn hình riêng biệt (Mục 5 đề tài)
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
        // Nếu trùng tên màn hình (ở phiên khác), lấy giá trị đỉnh cao nhất
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

    // Tìm giá trị lớn nhất toàn cục để tính toán tỷ lệ % độ dài thanh bar ngang
    double globalMaxRam = displayList
        .map((e) => e.maxRam)
        .reduce((a, b) => a > b ? a : b);
    if (globalMaxRam == 0) globalMaxRam = 1;

    // HIỂN THỊ CONSOLE LOG CHI TIẾT THEO YÊU CẦU CỦA USER
    debugPrint('\n════════════════════ [BÁO CÁO PHÂN TÍCH RAM/CPU] ════════════════════');
    debugPrint('Tổng số màn hình phân tích: ${displayList.length}');
    for (var data in displayList) {
      final double ramRatio = data.maxRam / globalMaxRam;
      final int barLength = (ramRatio * 20).round(); // Độ dài thanh bar trong console
      final String bar = '█' * barLength + '░' * (20 - barLength);
      
      debugPrint(' 📱 Màn hình: ${data.screenName.padRight(15)}');
      debugPrint('    RAM Đỉnh:   [${bar}] ${data.maxRam.toStringAsFixed(1)} MB');
      debugPrint('    CPU:        Đỉnh: ${data.maxCpu.toStringAsFixed(1)}% | Trung bình: ${data.avgCpu.toStringAsFixed(1)}%');
      debugPrint('  -------------------------------------------------------------------');
    }
    debugPrint('═════════════════════════════════════════════════════════════════════\n');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 1. Khối tiêu đề phân tích
        const Text(
          'Phân tích & So sánh theo Màn hình',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'So sánh mức tiêu thụ RAM đỉnh (Peak) giữa các giao diện ứng dụng.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 24),

        // 2. KHU VỰC BIỂU ĐỒ ĐƯỜNG NGANG CHUYÊN CHO DI ĐỘNG (Dễ so sánh nhất)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grayBorder, width: 1),
          ),
          child: Column(
            children: displayList.map((data) {
              // Tính toán độ dài thanh phần trăm dựa trên giá trị RAM đỉnh
              final double ramRatio = data.maxRam / globalMaxRam;

              return Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data.screenName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '${data.maxRam.toStringAsFixed(0)} MB',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Thanh Bar ngang tối giản thể hiện dung lượng
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ramRatio.clamp(
                            0.05,
                            1.0,
                          ), // Đảm bảo thanh luôn hiển thị ít nhất 5% để nhìn thấy màu
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              // Đỏ Viettel chuẩn, không dùng gradient cầu kỳ
                              color: viettelRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 28),

        // 3. KHU VỰC BẢNG SỐ LIỆU ĐỐI CHIẾU CHI TIẾT (Dùng cho Báo cáo / Slide thực tập)
        const Text(
          'Bảng chi tiết chỉ số phụ tải (RAM & CPU)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
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
                0: FlexColumnWidth(
                  2.5,
                ), // Tên màn hình chiếm nhiều khoảng trống nhất
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: grayBorder, width: 1),
              ),
              children: [
                // Hàng Tiêu Đề Bảng
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    _buildTableCell('Màn hình', isHeader: true),
                    _buildTableCell('RAM Đỉnh', isHeader: true),
                    _buildTableCell('CPU Đỉnh / Avg', isHeader: true),
                  ],
                ),
                // Các hàng dữ liệu
                ...displayList.map((data) {
                  return TableRow(
                    children: [
                      _buildTableCell(data.screenName),
                      _buildTableCell('${data.maxRam.toStringAsFixed(0)} MB'),
                      _buildTableCell(
                        '${data.maxCpu.toStringAsFixed(0)}% / ${data.avgCpu.toStringAsFixed(0)}%',
                        color: cpuBlue,
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

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader
              ? const Color(0xFF4B5563)
              : (color ?? const Color(0xFF1F2937)),
          fontFeatures: isHeader ? null : const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// Lớp lưu trữ cấu trúc dữ liệu nội bộ phục vụ tính toán thống kê phân tích
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
