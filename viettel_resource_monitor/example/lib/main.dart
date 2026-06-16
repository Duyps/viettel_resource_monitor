import 'dart:async';
import 'package:flutter/material.dart';
import 'package:viettel_resource_monitor/viettel_resource_monitor.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo hệ thống giám sát
  await ViettelResourceMonitor.instance.init(
    ViettelResourceMonitorConfig(
      enableFPS: true,
      enableNetwork: true,
      alertConfig: const ViettelAlertConfig(
        maxMemoryMB: 300,
        maxNetworkDurationMs: 1500,
        minFps: 40,
        maxCpuPercentage: 50,
      ),
      onAlert: (alert) {
        debugPrint('\n⚠️ [VIETTEL THRESHOLD ALERT] ${alert.message}');

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
          '\n════════════════════ [BÁO CÁO NHANH HỆ THỐNG] ════════════════════',
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
      title: 'Viettel Diagnosis Test Suite',
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
          'Hệ Thống Kiểm Thử Chẩn Đoán',
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
            'Hãy chọn các kịch bản dưới đây để tạo ra dữ liệu giả lập. Sau đó mở Tab "Chẩn Đoán" để xem AI báo cáo chính xác như mong đợi không.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 24),

          _buildTestCard(
            context,
            title: '1. Test Chạy Ổn Định (Normal)',
            subtitle: 'Kỳ vọng: Không có cảnh báo nào (Xanh lá).',
            icon: Icons.check_circle,
            color: Colors.green,
            route: '/test_normal',
            builder: (ctx) => const NormalTestScreen(),
          ),

          _buildTestCard(
            context,
            title: '2. Test Rò Rỉ Bộ Nhớ (Memory Leak)',
            subtitle:
                'Kỳ vọng: Báo cáo "Nghi ngờ Rò rỉ bộ nhớ".\nHướng dẫn: Hãy vào màn hình này, bấm nút "Nhai RAM", sau đó BẤM BACK ra ngoài. Lặp lại thao tác này 3 lần.',
            icon: Icons.memory,
            color: Colors.blue,
            route: '/test_leak',
            builder: (ctx) => const MemoryLeakTestScreen(),
          ),

          _buildTestCard(
            context,
            title: '3. Test Nghẽn Luồng Chính (Main Thread)',
            subtitle:
                'Kỳ vọng: Báo cáo "Nghẽn Luồng Chính".\nHướng dẫn: Vào màn hình này, bấm nút chạy vòng lặp nặng để CPU vượt 15% và FPS tụt dốc.',
            icon: Icons.speed,
            color: Colors.orange,
            route: '/test_main_thread',
            builder: (ctx) => const MainThreadBlockScreen(),
          ),

          _buildTestCard(
            context,
            title: '4. Test Quá Tải GPU (UI Overdraw)',
            subtitle:
                'Kỳ vọng: Báo cáo "Quá tải Render Giao diện".\nHướng dẫn: Màn hình này vẽ 1000 Widget mờ chồng lên nhau khiến FPS tụt nhưng CPU vẫn rất thấp.',
            icon: Icons.layers,
            color: Colors.purple,
            route: '/test_overdraw',
            builder: (ctx) => const UiOverdrawScreen(),
          ),

          _buildTestCard(
            context,
            title: '5. Test Nghẽn Mạng (Slow API)',
            subtitle:
                'Kỳ vọng: Báo cáo "Nút thắt cổ chai API".\nHướng dẫn: Bấm nút gọi API chậm (mất 3 giây).',
            icon: Icons.network_check,
            color: Colors.brown,
            route: '/test_network',
            builder: (ctx) => const SlowNetworkScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required WidgetBuilder builder,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: RouteSettings(name: route),
              builder: builder,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 24,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= TEST SCREENS =================

// 1. NORMAL SCREEN
class NormalTestScreen extends StatelessWidget {
  const NormalTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Màn hình Ổn định')),
      body: const Center(
        child: Text('Màn hình này siêu mượt, 60 FPS, không tốn RAM/CPU.'),
      ),
    );
  }
}

// 2. MEMORY LEAK SCREEN
// Biến toàn cục để cố tình giả lập việc quên xoá bộ nhớ (Leak)
final List<String> globalLeakedMemory = [];

class MemoryLeakTestScreen extends StatefulWidget {
  const MemoryLeakTestScreen({super.key});

  @override
  State<MemoryLeakTestScreen> createState() => _MemoryLeakTestScreenState();
}

class _MemoryLeakTestScreenState extends State<MemoryLeakTestScreen> {
  void _leakMemory() {
    setState(() {
      for (int i = 0; i < 600000; i++) {
        globalLeakedMemory.add(
          'This is a massive string to intentionally leak memory and crash the app eventually... $i',
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã nhồi thêm RAM! Hãy bấm Back ra ngoài rồi vào lại đây tiếp!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Leak Test')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _leakMemory,
          icon: const Icon(Icons.memory),
          label: const Text('Nhai thêm ~15MB RAM (Leak)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

// 3. MAIN THREAD BLOCK SCREEN
class MainThreadBlockScreen extends StatefulWidget {
  const MainThreadBlockScreen({super.key});

  @override
  State<MainThreadBlockScreen> createState() => _MainThreadBlockScreenState();
}

class _MainThreadBlockScreenState extends State<MainThreadBlockScreen> {
  bool _isCalculating = false;

  void _blockThread() async {
    setState(() => _isCalculating = true);

    // Đợi UI update chữ "Đang tính toán" rồi mới block
    await Future.delayed(const Duration(milliseconds: 100));

    // Cố tình chạy vòng lặp chặn đứng Main Thread
    double result = 0.0;
    final endTime = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(endTime)) {
      result += sin(result) * cos(result) + 1;
    }

    if (mounted) {
      setState(() => _isCalculating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vòng lặp kết thúc. FPS đã tụt mạnh và CPU đã tăng cao.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main Thread Block')),
      body: Center(
        child: _isCalculating
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Giao diện đang bị treo cứng (Jank) vì Main Thread đang bận...',
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: _blockThread,
                icon: const Icon(Icons.calculate),
                label: const Text('Chạy vòng lặp khoá luồng (3s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
      ),
    );
  }
}

// 4. UI OVERDRAW SCREEN
class UiOverdrawScreen extends StatefulWidget {
  const UiOverdrawScreen({super.key});

  @override
  State<UiOverdrawScreen> createState() => _UiOverdrawScreenState();
}

class _UiOverdrawScreenState extends State<UiOverdrawScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Tạo animation xoay liên tục để bắt Flutter phải vẽ lại (Repaint) liên tục
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Overdraw Test')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ListView.builder(
            itemCount: 500, // Vẽ 500 phần tử mờ chồng chéo lên nhau
            itemBuilder: (context, index) {
              return Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: Opacity(
                  opacity: 0.1, // Opacity làm GPU kiệt sức
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      boxShadow: const [
                        BoxShadow(color: Colors.black, blurRadius: 20),
                      ], // Shadow nặng
                    ),
                    child: const Center(child: Text('GPU Crying...')),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 5. SLOW NETWORK SCREEN
class SlowNetworkScreen extends StatefulWidget {
  const SlowNetworkScreen({super.key});

  @override
  State<SlowNetworkScreen> createState() => _SlowNetworkScreenState();
}

class _SlowNetworkScreenState extends State<SlowNetworkScreen> {
  String _status = 'Nhấn nút để gọi API...';

  Future<void> _fetchSlowApi() async {
    setState(() => _status = 'Đang chờ máy chủ phản hồi (3 giây)...');
    try {
      final res = await http.get(Uri.parse('https://httpbin.org/delay/3'));
      if (mounted)
        setState(
          () => _status = 'Thành công. Kích thước: ${res.body.length} bytes',
        );
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slow API Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchSlowApi,
              icon: const Icon(Icons.hourglass_bottom),
              label: const Text('Gọi API httpbin.org/delay/3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
