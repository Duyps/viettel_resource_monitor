import 'package:flutter/material.dart';
import '../../models/screen_session.dart';
import '../widgets/light_bar_chart.dart';

class RamCpuTab extends StatelessWidget {
  final List<ScreenSession> allSessions;

  const RamCpuTab({Key? key, required this.allSessions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (allSessions.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));

    // Prepare data for Bar Chart
    List<String> labels = [];
    List<double> ramValues = [];
    
    for (var session in allSessions.take(5).toList().reversed) {
      labels.add(session.screenName.replaceAll('Screen', ''));
      double peakRam = 0;
      for (var m in session.resourceMetrics) {
        if (m.memoryUsageMB > peakRam) peakRam = m.memoryUsageMB;
      }
      ramValues.add(peakRam);
    }

    if (ramValues.every((element) => element == 0)) {
       return const Center(child: Text('Chưa thu thập đủ dữ liệu RAM.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('So sánh Mức tiêu thụ RAM (Max MB)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Biểu đồ thể hiện màn hình nào ngốn nhiều RAM nhất trong quá trình sử dụng.', style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 24),
        LightBarChart(
          labels: labels,
          values: ramValues,
          unit: 'MB',
          color: const Color(0xFFEE0000),
        ),
      ],
    );
  }
}
