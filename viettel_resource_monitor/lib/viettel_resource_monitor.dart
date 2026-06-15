library viettel_resource_monitor;

import 'package:flutter/foundation.dart';
import 'src/viettel_resource_monitor_config.dart';

export 'src/viettel_resource_monitor_config.dart';

/// The main entry point for the Viettel Resource Monitor.
///
/// Implements a thread-safe Singleton pattern.
class ViettelResourceMonitor {
  // Private constructor
  ViettelResourceMonitor._privateConstructor();

  // The single instance
  static final ViettelResourceMonitor _instance = ViettelResourceMonitor._privateConstructor();

  /// Provides access to the single instance of the monitor.
  static ViettelResourceMonitor get instance => _instance;

  ViettelResourceMonitorConfig? _config;
  bool _isInitialized = false;

  /// Initializes the resource monitor with the given [config].
  ///
  /// This should be called once, typically in `main()` before `runApp()`.
  void init([ViettelResourceMonitorConfig? config]) {
    if (_isInitialized) {
      debugPrint('ViettelResourceMonitor is already initialized.');
      return;
    }

    _config = config ?? ViettelResourceMonitorConfig.defaultConfig();
    _isInitialized = true;

    debugPrint('ViettelResourceMonitor initialized with FPS tracking: ${_config!.enableFPS}, Network tracking: ${_config!.enableNetwork}');
    
    _setupMonitors();
  }

  void _setupMonitors() {
    if (_config!.enableFPS) {
      // TODO: Implement FPS tracking initialization
      debugPrint('ViettelResourceMonitor: FPS tracking enabled.');
    }

    if (_config!.enableNetwork) {
      // TODO: Implement Network tracking initialization
      debugPrint('ViettelResourceMonitor: Network tracking enabled.');
    }
  }

  /// Indicates whether the monitor has been successfully initialized.
  bool get isInitialized => _isInitialized;
}
