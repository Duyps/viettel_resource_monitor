import 'package:flutter/material.dart';
import '../../models/screen_session.dart';
import '../widgets/light_line_chart.dart';

class FpsTab extends StatelessWidget {
  final List<ScreenSession> allSessions;

  const FpsTab({Key? key, required this.allSessions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (allSessions.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));

    List<double> fpsTimeline = [];
    for (var session in allSessions) {
      for (var m in session.resourceMetrics) {
        fpsTimeline.add(m.fps);
      }
    }
    if (fpsTimeline.length > 50) {
      fpsTimeline = fpsTimeline.sublist(fpsTimeline.length - 50); // Only show last 50 data points for clarity
    }

    if (fpsTimeline.isEmpty) {
      return const Center(child: Text('Đang thu thập dữ liệu FPS...'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Theo dõi Tốc độ khung hình (FPS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Biểu đồ đường ghi nhận FPS theo dòng thời gian. Ngưỡng dưới 30 FPS cảnh báo đỏ.', style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 24),
        LightLineChart(
          data: fpsTimeline,
          color: Colors.blueAccent,
          threshold: 30.0, // Alert threshold at 30 FPS
        ),
      ],
    );
  }
}
