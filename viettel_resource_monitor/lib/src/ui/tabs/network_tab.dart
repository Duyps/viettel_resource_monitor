import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/screen_session.dart';

class NetworkTab extends StatelessWidget {
  final List<ScreenSession> allSessions;

  const NetworkTab({Key? key, required this.allSessions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allRequests = allSessions.expand((s) => s.networkMetrics).toList();
    allRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    const viettelRed = Color(0xFFEE0000);
    const grayBorder = Color(0xFFE5E7EB);
    const textDark = Color(0xFF1F2937);

    // Tính toán thống kê nhanh
    int totalRequests = allRequests.length;
    int slowRequests = allRequests.where((req) => req.durationMilliseconds > 2000).length;
    int failedRequests = allRequests.where((req) => req.statusCode >= 400).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 1. Khối tiêu đề
        const Text(
          'Độ trễ API & Payload',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'Theo dõi thời gian phản hồi (Latency) và lưu lượng truy cập của các API được gọi trong phiên làm việc.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // 2. Khối Thống kê tổng quan (Grid)
        Row(
          children: [
            Expanded(child: _buildStatCard('Tổng Request', totalRequests.toString(), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('API Chậm (>2s)', slowRequests.toString(), Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Lỗi (>=400)', failedRequests.toString(), viettelRed)),
          ],
        ),
        const SizedBox(height: 28),

        // 3. Danh sách Request chi tiết
        const Text(
          'Lịch sử Network Request',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textDark),
        ),
        const SizedBox(height: 12),
        
        if (allRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: grayBorder),
            ),
            alignment: Alignment.center,
            child: const Text('Chưa có yêu cầu mạng nào được ghi nhận.', style: TextStyle(color: Colors.black38)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: grayBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allRequests.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1, color: grayBorder),
              itemBuilder: (ctx, idx) {
                final req = allRequests[idx];
                final isSlow = req.durationMilliseconds > 2000;
                final isError = req.statusCode >= 400;
                
                Color statusColor = Colors.green;
                if (isError) statusColor = viettelRed;
                else if (isSlow) statusColor = Colors.orange;

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Method Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          req.method.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // URL & Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.url,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textDark),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.data_object, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Payload: ${req.responseSizeBytes} Bytes',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      // Status Code & Duration
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${req.durationMilliseconds}ms',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'HTTP ${req.statusCode}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
