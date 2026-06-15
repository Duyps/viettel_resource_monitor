import 'models/resource_alert.dart';

/// Configuration for threshold alerting.
class ViettelAlertConfig {
  final double minFps;
  final double maxMemoryMB;
  final double maxCpuPercentage;
  final int maxNetworkDurationMs;

  const ViettelAlertConfig({
    this.minFps = 40.0,
    this.maxMemoryMB = 300.0,
    this.maxCpuPercentage = 50.0,
    this.maxNetworkDurationMs = 2000,
  });
}

/// Configuration class for `ViettelResourceMonitor`.
class ViettelResourceMonitorConfig {
  /// Whether to enable FPS tracking and reporting.
  final bool enableFPS;

  /// Whether to enable Network request tracking.
  final bool enableNetwork;

  /// Whether to show the floating Bubble UI.
  final bool showBubble;

  final ViettelAlertConfig alertConfig;
  final void Function(ResourceAlert alert)? onAlert;

  /// Creates a configuration for the resource monitor.
  const ViettelResourceMonitorConfig({
    this.enableFPS = true,
    this.enableNetwork = true,
    this.showBubble = true,
    this.alertConfig = const ViettelAlertConfig(),
    this.onAlert,
  });

  /// Creates a default configuration.
  factory ViettelResourceMonitorConfig.defaultConfig() {
    return const ViettelResourceMonitorConfig();
  }
}
