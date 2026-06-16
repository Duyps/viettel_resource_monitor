import 'dart:async';
import '../models/screen_session.dart';
import '../models/resource_metric.dart';
import '../models/network_metric.dart';
import '../models/resource_alert.dart';
import '../viettel_resource_monitor_config.dart';

class ViettelDataAnalyzer {
  final ViettelAlertConfig _config;
  final void Function(ResourceAlert alert)? _onAlertCallback;
  final StreamController<ResourceAlert> _alertStreamController;

  ViettelDataAnalyzer(
    this._config,
    this._onAlertCallback,
    this._alertStreamController,
  );

  void _emitAlert(ResourceAlert alert) {
    _onAlertCallback?.call(alert);
    if (!_alertStreamController.isClosed) {
      _alertStreamController.add(alert);
    }
  }

  /// Called immediately when a new ResourceMetric is captured
  void analyzeImmediateResource(ResourceMetric metric, String screenName) {
    if (metric.memoryUsageMB > _config.maxMemoryMB) {
      _emitAlert(
        ResourceAlert(
          screenName: screenName,
          alertType: AlertType.memoryLeak,
          message:
              'Cảnh báo: RAM vọt lên mức nguy hiểm (${metric.memoryUsageMB.toStringAsFixed(1)}MB > ${_config.maxMemoryMB}MB)',
          timestamp: metric.timestamp,
        ),
      );
    }

    if (metric.cpuUsagePercentage > _config.maxCpuPercentage) {
      _emitAlert(
        ResourceAlert(
          screenName: screenName,
          alertType: AlertType.highCpu,
          message:
              'Cảnh báo: CPU quá tải (${metric.cpuUsagePercentage.toStringAsFixed(1)}% > ${_config.maxCpuPercentage}%)',
          timestamp: metric.timestamp,
        ),
      );
    }
  }

  /// Called immediately when a Network request finishes
  void analyzeImmediateNetwork(NetworkMetric metric, String screenName) {
    if (metric.durationMilliseconds > _config.maxNetworkDurationMs) {
      _emitAlert(
        ResourceAlert(
          screenName: screenName,
          alertType: AlertType.slowNetwork,
          message:
              'API [${metric.method}] phản hồi quá chậm: ${metric.durationMilliseconds}ms (Ngưỡng: ${_config.maxNetworkDurationMs}ms)\nURL: ${metric.url}',
          timestamp: metric.timestamp,
        ),
      );
    }
  }

  /// Called when a ScreenSession is closed
  void analyzeSession(ScreenSession session) {
    if (session.resourceMetrics.isEmpty) return;

    double totalFps = 0;
    double maxRam = 0;
    double maxCpu = 0;

    for (var metric in session.resourceMetrics) {
      totalFps += metric.fps;
      if (metric.memoryUsageMB > maxRam) maxRam = metric.memoryUsageMB;
      if (metric.cpuUsagePercentage > maxCpu) {
        maxCpu = metric.cpuUsagePercentage;
      }
    }

    double avgFps = totalFps / session.resourceMetrics.length;

    if (avgFps < _config.minFps) {
      _emitAlert(
        ResourceAlert(
          screenName: session.screenName,
          alertType: AlertType.fpsDrop,
          message:
              'Cảnh báo Jank! Màn hình giật lag với FPS trung bình chỉ: ${avgFps.toStringAsFixed(1)} (Dưới ${_config.minFps})',
          timestamp: DateTime.now(),
        ),
      );
    }

    // You can also emit a sessionSummary alert here if needed
    // if (kDebugMode) {
    //   debugPrint(
    //     'ViettelResourceMonitor: [Summary ${session.screenName}] AvgFPS: ${avgFps.toStringAsFixed(1)}, PeakRAM: ${maxRam.toStringAsFixed(1)}MB, PeakCPU: ${maxCpu.toStringAsFixed(1)}%',
    //   );
    // }
  }
}
