import 'package:flutter/foundation.dart';
import 'src/viettel_resource_monitor_config.dart';
import 'src/observers/viettel_navigator_observer.dart';
import 'src/trackers/fps_tracker.dart';
import 'src/trackers/network_tracker.dart';
import 'src/trackers/memory_tracker.dart';
import 'src/trackers/battery_tracker.dart';
import 'src/trackers/cpu_tracker.dart';
import 'src/core/session_manager.dart';
import 'src/core/data_analyzer.dart';
import 'src/models/resource_metric.dart';
import 'dart:async';
import 'src/models/resource_alert.dart';

export 'src/viettel_resource_monitor_config.dart';
export 'src/models/resource_metric.dart';
export 'src/models/network_metric.dart';
export 'src/models/screen_session.dart';
export 'src/models/resource_alert.dart';
export 'src/observers/viettel_navigator_observer.dart';

/// The main entry point for the Viettel Resource Monitor.
///
/// Implements a thread-safe Singleton pattern.
class ViettelResourceMonitor {
  // Private constructor
  ViettelResourceMonitor._privateConstructor() {
    navigatorObserver = ViettelNavigatorObserver();
  }

  late final ViettelNavigatorObserver navigatorObserver;
  late final ViettelSessionManager sessionManager = ViettelSessionManager();
  ViettelFpsTracker? _fpsTracker;
  ViettelNetworkTracker? _networkTracker;
  final ViettelMemoryTracker _memoryTracker = ViettelMemoryTracker();
  final ViettelBatteryTracker _batteryTracker = ViettelBatteryTracker();
  final ViettelCpuTracker _cpuTracker = ViettelCpuTracker();
  
  final StreamController<ResourceAlert> _alertStreamController = StreamController<ResourceAlert>.broadcast();

  /// Stream of resource alerts for real-time Dashboard/UI rendering
  Stream<ResourceAlert> get alertStream => _alertStreamController.stream;

  // The single instance
  static final ViettelResourceMonitor _instance = ViettelResourceMonitor._privateConstructor();

  /// Provides access to the single instance of the monitor.
  static ViettelResourceMonitor get instance => _instance;

  ViettelResourceMonitorConfig? _config;
  bool _isInitialized = false;

  /// Initializes the resource monitor with the given [config].
  ///
  /// This should be called once, typically in `main()` before `runApp()`.
  Future<void> init([ViettelResourceMonitorConfig? config]) async {
    if (_isInitialized) {
      debugPrint('ViettelResourceMonitor is already initialized.');
      return;
    }

    await sessionManager.init();

    _config = config ?? ViettelResourceMonitorConfig.defaultConfig();
    _isInitialized = true;

    // Initialize Analyzer
    final analyzer = ViettelDataAnalyzer(_config!.alertConfig, _config!.onAlert, _alertStreamController);
    sessionManager.analyzer = analyzer;

    debugPrint('ViettelResourceMonitor initialized with FPS tracking: ${_config!.enableFPS}, Network tracking: ${_config!.enableNetwork}');
    
    _setupMonitors();
  }

  void _setupMonitors() {
    if (_config!.enableFPS) {
      _fpsTracker = ViettelFpsTracker(navigatorObserver);
      _fpsTracker!.onReportMetric = (fps) async {
        if (fps > 0) {
          final cpu = await _cpuTracker.getCpuUsage();
          final battery = await _batteryTracker.getBatteryLevel();
          final ram = _memoryTracker.getRssMemoryMB();
          final dartHeap = _memoryTracker.getDartHeapUsageMB();
          
          final metric = ResourceMetric(
            timestamp: DateTime.now(),
            fps: fps,
            cpuUsagePercentage: cpu,
            batteryLevel: battery,
            memoryUsageMB: ram,
            dartHeapUsageMB: dartHeap,
          );
          sessionManager.addResourceMetric(metric);

          if (kDebugMode) {
            debugPrint('ViettelResourceMonitor: FPS=$fps, CPU=${cpu.toStringAsFixed(1)}%, RAM=${ram.toStringAsFixed(1)}MB, Pin=$battery%');
          }
        }
      };
      _fpsTracker!.start();
      debugPrint('ViettelResourceMonitor: FPS tracking enabled.');
    }

    if (_config!.enableNetwork) {
      _networkTracker = ViettelNetworkTracker();
      _networkTracker!.onNetworkReport = (metric) {
        sessionManager.addNetworkMetric(metric);
      };
      _networkTracker!.start();
      debugPrint('ViettelResourceMonitor: Network tracking enabled (HttpOverrides).');
    }

    // Connect observers to SessionManager
    navigatorObserver.onRouteChanged = (routeName) {
      sessionManager.startSession(routeName);
    };
  }

  /// Indicates whether the monitor has been successfully initialized.
  bool get isInitialized => _isInitialized;
}
