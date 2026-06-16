import 'package:flutter/material.dart';
import 'dart:async';
import '../../viettel_resource_monitor.dart';
import '../models/screen_session.dart';
import '../models/resource_alert.dart';
import 'tabs/ram_cpu_tab.dart';
import 'tabs/fps_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/alerts_tab.dart';

class MobileAcademicDashboard extends StatefulWidget {
  const MobileAcademicDashboard({Key? key}) : super(key: key);

  @override
  State<MobileAcademicDashboard> createState() => _MobileAcademicDashboardState();
}

class _MobileAcademicDashboardState extends State<MobileAcademicDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ScreenSession> _allSessions = [];
  final List<ResourceAlert> _alerts = [];
  StreamSubscription? _metricSub;
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();

    // Auto-refresh when new metrics arrive
    _metricSub = ViettelResourceMonitor.instance.metricStream.listen((_) {
      if (mounted) _loadData();
    });

    // Listen for alerts
    _alertSub = ViettelResourceMonitor.instance.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _alerts.insert(0, alert); // Newest first
        });
      }
    });
  }

  @override
  void dispose() {
    _metricSub?.cancel();
    _alertSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final manager = ViettelResourceMonitor.instance.sessionManager;
    final saved = manager.getSavedSessions();
    final current = manager.currentSession;
    
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
    setState(() {
      _alerts.clear();
    });
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
                  RamCpuTab(allSessions: _allSessions),
                  FpsTab(allSessions: _allSessions),
                  NetworkTab(allSessions: _allSessions),
                  AlertsTab(alerts: _alerts),
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
        isScrollable: true,
        labelColor: const Color(0xFFEE0000),
        unselectedLabelColor: Colors.black54,
        indicatorColor: const Color(0xFFEE0000),
        tabAlignment: TabAlignment.start,
        tabs: [
          const Tab(text: 'RAM/CPU'),
          const Tab(text: 'FPS Timeline'),
          const Tab(text: 'Network API'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cảnh báo'),
                if (_alerts.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFEE0000), borderRadius: BorderRadius.circular(10)),
                    child: Text('${_alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
