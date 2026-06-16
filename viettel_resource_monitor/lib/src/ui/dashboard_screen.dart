import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../viettel_resource_monitor.dart';
import 'widgets/sparkline_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data history for charts
  final List<double> _fpsHistory = [];
  final List<double> _ramHistory = [];
  final List<double> _cpuHistory = [];
  
  final List<ResourceAlert> _alerts = [];
  
  StreamSubscription? _metricSub;
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _metricSub = ViettelResourceMonitor.instance.metricStream.listen((metric) {
      if (!mounted) return;
      setState(() {
        _fpsHistory.add(metric.fps);
        _ramHistory.add(metric.memoryUsageMB);
        _cpuHistory.add(metric.cpuUsagePercentage);
        
        // Keep only last 30 data points
        if (_fpsHistory.length > 30) _fpsHistory.removeAt(0);
        if (_ramHistory.length > 30) _ramHistory.removeAt(0);
        if (_cpuHistory.length > 30) _cpuHistory.removeAt(0);
      });
    });

    _alertSub = ViettelResourceMonitor.instance.alertStream.listen((alert) {
      if (!mounted) return;
      setState(() {
        _alerts.insert(0, alert);
        if (_alerts.length > 50) _alerts.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metricSub?.cancel();
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacity(0.75),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart, color: Color(0xFF00E5FF), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Resource Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00E5FF),
              labelColor: const Color(0xFF00E5FF),
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(icon: Icon(Icons.insights), text: 'Overview'),
                Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
                Tab(icon: Icon(Icons.network_check), text: 'Network'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAlertsTab(),
                  _buildNetworkTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SparklineChart(
          data: _fpsHistory,
          color: const Color(0xFF00E5FF),
          maxValue: 60,
          label: 'FPS (Frames Per Second)',
          unit: 'FPS',
        ),
        const SizedBox(height: 20),
        SparklineChart(
          data: _ramHistory,
          color: const Color(0xFFB388FF),
          maxValue: 400,
          label: 'RAM Usage',
          unit: 'MB',
        ),
        const SizedBox(height: 20),
        SparklineChart(
          data: _cpuHistory,
          color: const Color(0xFFFF4081),
          maxValue: 100,
          label: 'CPU Usage',
          unit: '%',
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return Center(
        child: Text('No alerts recorded.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
      );
    }
    
    return ListView.builder(
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    alert.screenName,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${alert.timestamp.hour}:${alert.timestamp.minute}:${alert.timestamp.second}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                alert.message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetworkTab() {
    // For MVP Week 6, we just show a placeholder as network metrics 
    // are stored in SessionManager. We will fetch them in future.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, color: Colors.white.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text('Network History UI is under construction.', 
            style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}
