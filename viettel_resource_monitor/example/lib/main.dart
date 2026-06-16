import 'dart:async';
import 'package:flutter/material.dart';
import 'package:viettel_resource_monitor/viettel_resource_monitor.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ViettelResourceMonitor.instance.init(
    ViettelResourceMonitorConfig(
      enableFPS: true,
      enableNetwork: true,
      alertConfig: const ViettelAlertConfig(
        maxMemoryMB: 200, // Thấp để dễ test Memory Leak
        maxNetworkDurationMs: 1500, // Thấp để dễ test Mạng chậm
        minFps: 40,
        maxCpuPercentage: 50,
      ),
      onAlert: (alert) {
        debugPrint('\n⚠️ [VIETTEL ALERT TRIGGERED] ⚠️');
        debugPrint('Nội dung: ${alert.message}');

        // Trích xuất báo cáo phân tích nhanh (giống trên Dashboard) khi có lỗi xảy ra
        final sessions = ViettelResourceMonitor.instance.sessionManager
            .getSavedSessions();
        final currentSession =
            ViettelResourceMonitor.instance.sessionManager.currentSession;
        final allSessions = [...sessions];
        if (currentSession != null) allSessions.add(currentSession);

        if (allSessions.isEmpty) return;

        final Map<String, List<double>> summaryMap = {};
        for (var session in allSessions) {
          final cleanName = session.screenName.replaceAll('Screen', '');
          if (session.resourceMetrics.isEmpty) continue;

          double peakRam = 0;
          double peakCpu = 0;
          double totalCpu = 0;
          for (var m in session.resourceMetrics) {
            if (m.memoryUsageMB > peakRam) peakRam = m.memoryUsageMB;
            if (m.cpuUsagePercentage > peakCpu) peakCpu = m.cpuUsagePercentage;
            totalCpu += m.cpuUsagePercentage;
          }
          double avgCpu = totalCpu / session.resourceMetrics.length;

          if (summaryMap.containsKey(cleanName)) {
            final existing = summaryMap[cleanName]!;
            summaryMap[cleanName] = [
              peakRam > existing[0] ? peakRam : existing[0],
              peakCpu > existing[1] ? peakCpu : existing[1],
              (avgCpu + existing[2]) / 2,
            ];
          } else {
            summaryMap[cleanName] = [peakRam, peakCpu, avgCpu];
          }
        }

        double globalMaxRam = summaryMap.values.fold(
          0.0,
          (prev, element) => element[0] > prev ? element[0] : prev,
        );
        if (globalMaxRam == 0) globalMaxRam = 1;

        debugPrint(
          '\n════════════════════ [BÁO CÁO NHANH RAM/CPU] ════════════════════',
        );
        summaryMap.forEach((name, data) {
          final double ramRatio = data[0] / globalMaxRam;
          final int barLength = (ramRatio * 20).round();
          final String bar = '█' * barLength + '░' * (20 - barLength);

          debugPrint(' 📱 Màn hình: ${name.padRight(15)}');
          debugPrint('    RAM Đỉnh:   [$bar] ${data[0].toStringAsFixed(1)} MB');
          debugPrint(
            '    CPU:         Đỉnh: ${data[1].toStringAsFixed(1)}% | Trung bình: ${data[2].toStringAsFixed(1)}%',
          );
          debugPrint(
            '  -------------------------------------------------------------------',
          );
        });
        debugPrint(
          '═════════════════════════════════════════════════════════════════════\n',
        );
      },
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Viettel Resource Monitor Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEE0000)),
        useMaterial3: true,
      ),
      builder: ViettelResourceMonitor.builder(),
      navigatorObservers: [ViettelResourceMonitor.instance.navigatorObserver],
      home: const TestSuiteHome(),
    );
  }
}

class TestSuiteHome extends StatelessWidget {
  const TestSuiteHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Viettel Monitor - Test Suite',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFEE0000),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Chọn một kịch bản để kiểm thử các cảnh báo tài nguyên của hệ thống:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _buildTestCard(
            context,
            title: 'Test Jank & Drop FPS',
            icon: Icons.speed,
            color: Colors.orange,
            route: '/test_fps',
            builder: (ctx) => const FpsTestScreen(),
          ),
          _buildTestCard(
            context,
            title: 'Test Memory Leak (RAM)',
            icon: Icons.memory,
            color: Colors.blue,
            route: '/test_ram',
            builder: (ctx) => const MemoryTestScreen(),
          ),
          _buildTestCard(
            context,
            title: 'Test Tải CPU Cao',
            icon: Icons.developer_board,
            color: Colors.purple,
            route: '/test_cpu',
            builder: (ctx) => const CpuTestScreen(),
          ),
          _buildTestCard(
            context,
            title: 'Test Mạng Chậm (API)',
            icon: Icons.network_check,
            color: Colors.green,
            route: '/test_network',
            builder: (ctx) => const NetworkTestScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
    required WidgetBuilder builder,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          // ĐÃ FIX: Thay thế .withOpacity lỗi thời sang .withValues chuẩn mã nguồn hiện đại
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: RouteSettings(name: route),
              builder: builder,
            ),
          );
        },
      ),
    );
  }
}

// ================= TEST SCREENS =================

class FpsTestScreen extends StatelessWidget {
  const FpsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FPS Jank Test')),
      body: ListView.builder(
        itemCount: 1000,
        itemBuilder: (context, index) {
          if (index % 5 == 0) {
            for (
              var i = 0;
              i < 800000;
              i++
            ) {} // Giả lập nghẽn luồng UI vẽ đồng bộ
          }
          return ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text('Heavy Item $index'),
          );
        },
      ),
    );
  }
}

class MemoryTestScreen extends StatefulWidget {
  const MemoryTestScreen({super.key});

  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends State<MemoryTestScreen> {
  final List<String> _leakedMemory = [];

  void _leakMemory() {
    setState(() {
      for (int i = 0; i < 500000; i++) {
        _leakedMemory.add(
          'This is a very long string used to consume memory quickly to test the Viettel Resource Monitor Memory tracking feature... $i',
        );
      }
    });
    debugPrint(
      'ViettelResourceMonitor: Appended 500,000 strings to memory list.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Leak Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Objects in Memory: ${_leakedMemory.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _leakMemory,
              icon: const Icon(Icons.memory),
              label: const Text('Allocate +500,000 Objects'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CpuTestScreen extends StatefulWidget {
  const CpuTestScreen({super.key});

  @override
  State<CpuTestScreen> createState() => _CpuTestScreenState();
}

class _CpuTestScreenState extends State<CpuTestScreen> {
  bool _isCalculating = false;

  void _startHeavyComputation() async {
    setState(() => _isCalculating = true);
    debugPrint('ViettelResourceMonitor: Starting heavy CPU computation...');

    await Future.delayed(const Duration(milliseconds: 100));

    double result = 0.0;
    for (int i = 0; i < 20000000; i++) {
      result += sin(i) * cos(i);
    }

    debugPrint('ViettelResourceMonitor: CPU computation done. Result: $result');
    if (mounted) setState(() => _isCalculating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CPU Overload Test')),
      body: Center(
        child: _isCalculating
            ? const CircularProgressIndicator(color: Colors.purple)
            : ElevatedButton.icon(
                onPressed: _startHeavyComputation,
                icon: const Icon(Icons.calculate),
                label: const Text('Chạy vòng lặp tính toán nặng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
      ),
    );
  }
}

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  String _status = 'Nhấn nút để gọi API...';

  // 1. Kịch bản API chạy nhanh bình thường
  Future<void> _fetchFastApi() async {
    setState(() => _status = 'Đang gọi API nhanh...');
    try {
      final res = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
      );
      if (mounted) {
        setState(
          () => _status = 'API Nhanh (200 OK): ${res.body.length} bytes',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi kết nối API nhanh: $e');
    }
  }

  // 2. Kịch bản API bị trễ / phản hồi chậm (ĐÃ THÊM BỔ SUNG ĐỂ SỬA LỖI)
  Future<void> _fetchSlowApi() async {
    setState(() => _status = 'Đang gọi API chậm (Giả lập delay)...');
    try {
      // Gọi qua endpoint trì hoãn của httpbin để test tính năng đo thời gian phản hồi mạng (Mục 4)
      final res = await http.get(Uri.parse('https://httpbin.org/delay/3'));
      if (mounted) {
        setState(() => _status = 'API Chậm (200 OK): ${res.body.length} bytes');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi kết nối API chậm: $e');
    }
  }

  // 3. Khối hàm dựng giao diện (Đã tách biệt độc lập, không còn bị lồng trong hàm xử lý)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network API Latency Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _status,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchFastApi,
              icon: const Icon(Icons.flash_on),
              label: const Text('Gọi API Nhanh (< 500ms)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchSlowApi,
              icon: const Icon(Icons.hourglass_bottom),
              label: const Text('Gọi API Chậm (> 3000ms)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
