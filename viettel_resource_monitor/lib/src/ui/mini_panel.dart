import 'dart:async';
import 'package:flutter/material.dart';
import '../../viettel_resource_monitor.dart';
import 'dashboard_screen.dart';
import 'dart:math';

class ViettelMiniPanel extends StatefulWidget {
  const ViettelMiniPanel({Key? key}) : super(key: key);

  @override
  State<ViettelMiniPanel> createState() => _ViettelMiniPanelState();
}

class _ViettelMiniPanelState extends State<ViettelMiniPanel> {
  double _xOffset = 20;
  double _yOffset = 100;
  
  double _fps = 0;
  double _ram = 0;
  bool _isAlerting = false;
  Timer? _alertTimer;

  StreamSubscription? _metricSub;
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    _metricSub = ViettelResourceMonitor.instance.metricStream.listen((metric) {
      if (mounted) {
        setState(() {
          _fps = metric.fps;
          _ram = metric.memoryUsageMB;
        });
      }
    });

    _alertSub = ViettelResourceMonitor.instance.alertStream.listen((alert) {
      if (mounted) {
        setState(() => _isAlerting = true);
        _alertTimer?.cancel();
        _alertTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isAlerting = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _metricSub?.cancel();
    _alertSub?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  void _openDashboard() {
    final navState = ViettelResourceMonitor.instance.navigatorObserver.navigator;
    if (navState == null) {
      debugPrint('ViettelResourceMonitor: No Navigator found to display Dashboard.');
      return;
    }

    showModalBottomSheet(
      context: navState.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DashboardScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Keep it within screen bounds during orientation changes
    _xOffset = max(0, min(_xOffset, size.width - 120));
    _yOffset = max(0, min(_yOffset, size.height - 60));

    return Positioned(
      left: _xOffset,
      top: _yOffset,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xOffset += details.delta.dx;
            _yOffset += details.delta.dy;
          });
        },
        onTap: _openDashboard,
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isAlerting ? Colors.redAccent : const Color(0xFF00E5FF),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isAlerting ? Colors.redAccent.withOpacity(0.5) : const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Color(0xFF00E5FF), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_fps.toStringAsFixed(0)} FPS',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.memory, color: Color(0xFFB388FF), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_ram.toStringAsFixed(0)} MB',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
