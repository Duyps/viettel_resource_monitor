import 'package:flutter/material.dart';
import 'dart:async';
import '../../viettel_resource_monitor.dart';
import '../models/screen_session.dart';
import 'widgets/light_bar_chart.dart';
import 'widgets/light_line_chart.dart';

class MobileAcademicDashboard extends StatefulWidget {
  const MobileAcademicDashboard({Key? key}) : super(key: key);

  @override
  State<MobileAcademicDashboard> createState() => _MobileAcademicDashboardState();
}

class _MobileAcademicDashboardState extends State<MobileAcademicDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ScreenSession> _allSessions = [];
  StreamSubscription? _metricSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    // Auto-refresh when new metrics arrive
    _metricSub = ViettelResourceMonitor.instance.metricStream.listen((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _metricSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final manager = ViettelResourceMonitor.instance.sessionManager;
    final saved = manager.getSavedSessions();
    final current = manager.currentSession;
    
    // Debug Logging
    debugPrint('ViettelResourceMonitor: --- DASHBOARD DEBUG INFO ---');
    debugPrint('ViettelResourceMonitor: Saved Sessions count: ${saved.length}');
    debugPrint('ViettelResourceMonitor: Current Session active: ${current != null}');
    if (current != null) {
      debugPrint('ViettelResourceMonitor: Current Session Screen: ${current.screenName}');
      debugPrint('ViettelResourceMonitor: Current Session Metrics: ${current.resourceMetrics.length}');
      debugPrint('ViettelResourceMonitor: Current Session Network: ${current.networkMetrics.length}');
    }
    debugPrint('ViettelResourceMonitor: ----------------------------');

    setState(() {
      _allSessions = [...saved];
      if (current != null) {
        _allSessions.add(current);
      }
      _allSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    });
  }

  void _clearData() async {
    await ViettelResourceMonitor.instance.sessionManager.clearAllData();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa dữ liệu cũ!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFFEE0000),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          title: const Text('Phân tích Tài nguyên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black54),
              onPressed: _clearData,
              tooltip: 'Xóa dữ liệu cũ',
            ),
            TextButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh, color: Color(0xFFEE0000), size: 16),
              label: const Text('Refresh', style: TextStyle(color: Color(0xFFEE0000), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScreenComparisonTab(),
                  _buildRenderPipelineTab(),
                  _buildNetworkAnalysisTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFEE0000),
        unselectedLabelColor: Colors.black54,
        indicatorColor: const Color(0xFFEE0000),
        tabs: const [
          Tab(text: 'RAM/CPU'),
          Tab(text: 'FPS Timeline'),
          Tab(text: 'Network API'),
        ],
      ),
    );
  }

  Widget _buildScreenComparisonTab() {
    if (_allSessions.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));

    // Prepare data for Bar Chart
    List<String> labels = [];
    List<double> ramValues = [];
    
    for (var session in _allSessions.take(5).toList().reversed) {
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

  Widget _buildRenderPipelineTab() {
    if (_allSessions.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));

    List<double> fpsTimeline = [];
    for (var session in _allSessions) {
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

  Widget _buildNetworkAnalysisTab() {
    final allRequests = _allSessions.expand((s) => s.networkMetrics).toList();
    allRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Độ trễ API & Network Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: allRequests.isEmpty
              ? const Center(child: Text('Chưa có yêu cầu mạng nào được ghi nhận.'))
              : ListView.separated(
                  itemCount: allRequests.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final req = allRequests[idx];
                    final isSlow = req.durationMilliseconds > 2000;
                    return ListTile(
                      tileColor: Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSlow ? const Color(0xFFEE0000).withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(req.method, style: TextStyle(color: isSlow ? const Color(0xFFEE0000) : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(req.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      subtitle: Text('${req.statusCode} • Payload: ${req.responseSizeBytes}B', style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                        '${req.durationMilliseconds}ms',
                        style: TextStyle(
                          color: isSlow ? const Color(0xFFEE0000) : Colors.black87,
                          fontWeight: isSlow ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }


}
