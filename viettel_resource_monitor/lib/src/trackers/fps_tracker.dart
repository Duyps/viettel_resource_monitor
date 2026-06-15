import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import '../observers/viettel_navigator_observer.dart';

class ViettelFpsTracker {
  final ViettelNavigatorObserver navigatorObserver;
  void Function(double fps)? onReportMetric;
  int _frameCount = 0;
  Timer? _timer;

  ViettelFpsTracker(this.navigatorObserver);

  void start() {
    SchedulerBinding.instance.addTimingsCallback(_onReportTimings);
    _timer = Timer.periodic(const Duration(seconds: 1), _calculateAndReport);
  }

  void stop() {
    SchedulerBinding.instance.removeTimingsCallback(_onReportTimings);
    _timer?.cancel();
  }

  void _onReportTimings(List<FrameTiming> timings) {
    _frameCount += timings.length;
  }

  void _calculateAndReport(Timer timer) {
    final double fps = _frameCount.toDouble();
    _frameCount = 0; // Reset for next second

    final currentScreen = navigatorObserver.currentRouteName ?? 'Unknown';

    // Log warning if FPS drops below 40
    if (fps < 40 && fps > 0) { // Check > 0 to avoid logging when app is idle/background
      debugPrint('⚠️ [WARNING] Màn hình bị Jank! FPS giảm xuống $fps trên màn hình: $currentScreen');
    }

    onReportMetric?.call(fps);
  }
}
