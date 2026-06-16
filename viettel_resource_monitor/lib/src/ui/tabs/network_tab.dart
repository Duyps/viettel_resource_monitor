import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/screen_session.dart';

class NetworkTab extends StatefulWidget {
  final List<ScreenSession> allSessions;

  const NetworkTab({Key? key, required this.allSessions}) : super(key: key);

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  // Bộ lọc danh sách: 'all' (Tất cả), 'slow' (Chậm), 'error' (Lỗi)
  String _activeFilter = 'all';

  // Định dạng lại kích thước payload tin cho chuẩn kỹ thuật dễ phân tích
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // Thu thập toàn bộ request từ tất cả các phiên
    final allRequests = widget.allSessions
        .expand((s) => s.networkMetrics)
        .toList();
    allRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    const viettelRed = Color(0xFFEE0000);
    const warningOrange = Color(0xFFD97706);
    const successGreen = Color(0xFF10B981);
    const grayBorder = Color(0xFFE5E7EB);
    const textDark = Color(0xFF1F2937);

    // 1. Tính toán số liệu thống kê cho bộ chỉ số chính (Mục 4 đề tài)
    final int totalCount = allRequests.length;
    final int slowCount = allRequests
        .where((req) => req.durationMilliseconds > 1500)
        .length; // Ngưỡng 1500ms theo main.dart
    final int errorCount = allRequests
        .where((req) => req.statusCode >= 400)
        .length;

    // 2. Lọc danh sách request theo tab người dùng đang chọn để phục vụ so sánh
    final filteredRequests = allRequests.where((req) {
      if (_activeFilter == 'slow') return req.durationMilliseconds > 1500;
      if (_activeFilter == 'error') return req.statusCode >= 400;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KHỐI TIÊU ĐỀ PHÂN TÍCH HẠ TẦNG
        const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giám sát Hạ tầng & Lưu lượng mạng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Phân tích thời gian trễ (Latency), mã trạng thái HTTP và dung lượng payload gói tin.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // THANH BẤM BỘ LỌC ĐA CHIỀU (Kết hợp hiển thị số liệu tổng quan trực quan)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterCard(
                  title: 'Tất cả API',
                  value: totalCount.toString(),
                  color: Colors.blue,
                  isActive: _activeFilter == 'all',
                  onTap: () => setState(() => _activeFilter = 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterCard(
                  title: 'Trễ mạng (>1.5s)',
                  value: slowCount.toString(),
                  color: warningOrange,
                  isActive: _activeFilter == 'slow',
                  onTap: () => setState(() => _activeFilter = 'slow'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterCard(
                  title: 'Yêu cầu lỗi',
                  value: errorCount.toString(),
                  color: viettelRed,
                  isActive: _activeFilter == 'error',
                  onTap: () => setState(() => _activeFilter = 'error'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // DANH SÁCH LỊCH SỬ DÒNG MẠNG (HIGH-DENSITY DATA LOGS)
        Expanded(
          child: filteredRequests.isEmpty
              ? Center(
                  child: Text(
                    _activeFilter == 'all'
                        ? 'Chưa có yêu cầu mạng nào được ghi nhận.'
                        : 'Không tìm thấy request nào phù hợp bộ lọc.',
                    style: const TextStyle(color: Colors.black38, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredRequests.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (ctx, idx) {
                    final req = filteredRequests[idx];
                    final bool isSlow = req.durationMilliseconds > 1500;
                    final bool isError = req.statusCode >= 400;

                    // Xác định màu sắc chỉ báo nghiệp vụ APM Monitor
                    Color metricColor = successGreen;
                    if (isError) {
                      metricColor = viettelRed;
                    } else if (isSlow) {
                      metricColor = warningOrange;
                    }

                    // Tách gọn URL để hiển thị thông minh trên màn hình hẹp điện thoại
                    final uri = Uri.tryParse(req.url);
                    final host = uri?.host ?? '';
                    final path = uri?.path ?? req.url;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: grayBorder, width: 1),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Dải màu chỉ báo trạng thái kỹ thuật (Indicator Bar) chạy dọc bên trái card
                            Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: metricColor,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(10),
                                ),
                              ),
                            ),

                            // Toàn bộ khối nội dung chính của gói tin Network
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Nhãn giao thức (METHOD BADGE)
                                    Container(
                                      width: 48,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: metricColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        req.method.toUpperCase(),
                                        style: TextStyle(
                                          color: metricColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2. KHỐI THÔNG TIN URL PATH & HOST NAME
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            path,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: textDark,
                                            ),
                                          ),
                                          if (host.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              host,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black38,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),

                                          // Khối Metadata phụ (Thời gian thực + Kích thước Payload)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.black26,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                req.timestamp
                                                    .toString()
                                                    .substring(11, 19),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black45,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.data_usage_outlined,
                                                size: 12,
                                                color: Colors.black26,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatBytes(
                                                  req.responseSizeBytes,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black45,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 3. KHỐI HIỂN THỊ SỐ LIỆU ĐỘ TRỄ (LATENCY) & MÃ LỖI HTTP
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${req.durationMilliseconds}ms',
                                          style: TextStyle(
                                            color: metricColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'HTTP ${req.statusCode}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isError
                                                ? viettelRed
                                                : Colors.grey.shade600,
                                            fontWeight: isError
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Widget phụ tạo khối thẻ vừa hiển thị số lượng vừa làm nút chuyển đổi bộ lọc
  Widget _buildFilterCard({
    required String title,
    required String value,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : const Color(0xFFE5E7EB),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isActive ? color : const Color(0xFF374151),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? color.withValues(alpha: 0.9)
                    : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
