import 'package:flutter/material.dart';
import '../../models/resource_alert.dart';

class AlertsTab extends StatefulWidget {
  final List<ResourceAlert> alerts;

  const AlertsTab({super.key, required this.alerts});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  String _selectedScreenFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    const viettelRed = Color(0xFFEE0000);
    const warningYellow = Color(
      0xFFD97706,
    ); // Vàng đậm tương phản cao trên nền sáng
    const infoBlue = Color(0xFF2563EB);
    const grayBorder = Color(0xFFE5E7EB);

    if (widget.alerts.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có cảnh báo nào được ghi nhận.',
          style: TextStyle(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    // Tự động gom danh sách các màn hình duy nhất xuất hiện trong log để làm bộ lọc
    final uniqueScreens = [
      'Tất cả',
      ...widget.alerts.map((a) => a.screenName).toSet(),
    ];

    // Lọc danh sách log dựa trên chip được chọn
    final filteredAlerts = _selectedScreenFilter == 'Tất cả'
        ? widget.alerts
        : widget.alerts
              .where((a) => a.screenName == _selectedScreenFilter)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. THANH TIÊU ĐỀ
        const Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 20.0,
            bottom: 8.0,
          ),
          child: Text(
            'Nhật ký lỗi hệ thống',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
        ),

        // 2. BỘ LỌC CHIP CUỘN NGANG (Giúp so sánh, tra cứu cực tiện)
        Container(
          height: 38,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: uniqueScreens.length,
            itemBuilder: (context, index) {
              final screen = uniqueScreens[index];
              final isSelected = _selectedScreenFilter == screen;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    screen,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: viettelRed, // Điểm nhấn Đỏ Viettel khi chọn
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide.none,
                  elevation: 0,
                  pressElevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (bool selected) {
                    setState(() => _selectedScreenFilter = screen);
                  },
                ),
              );
            },
          ),
        ),

        // 3. DANH SÁCH LOG CẢNH BÁO TỐI GIẢN
        Expanded(
          child: filteredAlerts.isEmpty
              ? const Center(
                  child: Text(
                    'Không có cảnh báo nào cho màn hình này.',
                    style: TextStyle(color: Colors.black38, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredAlerts.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemBuilder: (ctx, idx) {
                    final alert = filteredAlerts[idx];

                    Color statusColor;
                    IconData alertIcon;

                    // Phân cấp nhóm màu tín hiệu doanh nghiệp rõ ràng, bớt lòe loẹt
                    // Phan cap nhom mau tin hieu doanh nghiep ro rang, bot loe loet
                    switch (alert.alertType) {
                      case AlertType.highCpu:
                      case AlertType.slowNetwork:
                        statusColor =
                            viettelRed; // Loi phan cung/ha tang mang: Do nghiem trong
                        alertIcon = alert.alertType == AlertType.highCpu
                            ? Icons
                                  .hardware_outlined // Thay cho cpu_outlined khong ton tai
                            : Icons.cloud_off_outlined;
                        break;
                      case AlertType.memoryLeak:
                      case AlertType.fpsDrop:
                        statusColor = warningYellow; // Canh bao toi uu code
                        alertIcon = alert.alertType == AlertType.memoryLeak
                            ? Icons.memory_outlined
                            : Icons
                                  .speed_outlined; // Thay cho animation_round khong ton tai (Hợp với FPS)
                        break;
                      case AlertType.sessionSummary:
                        statusColor = infoBlue; // Thong ke tong quan
                        alertIcon = Icons.insert_chart_outlined_rounded;
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: grayBorder, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon trạng thái bọc trong vòng tròn mờ nhẹ thanh lịch
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              alertIcon,
                              color: statusColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Khối Text nội dung chi tiết số liệu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      alert.screenName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    Text(
                                      alert.timestamp.toString().substring(
                                        11,
                                        19,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black38,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert.message,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF1F2937),
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
