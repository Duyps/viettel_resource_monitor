/// Configuration class for `ViettelResourceMonitor`.
class ViettelResourceMonitorConfig {
  /// Whether to enable FPS tracking and reporting.
  final bool enableFPS;

  /// Whether to enable Network request tracking.
  final bool enableNetwork;

  /// Creates a configuration for the resource monitor.
  const ViettelResourceMonitorConfig({
    this.enableFPS = true,
    this.enableNetwork = true,
  });

  /// Creates a default configuration.
  factory ViettelResourceMonitorConfig.defaultConfig() {
    return const ViettelResourceMonitorConfig();
  }
}
