/// Represents resource consumption (CPU, RAM, FPS, Battery) at a specific timestamp.
class ResourceMetric {
  final DateTime timestamp;
  final double cpuUsagePercentage;
  final double memoryUsageMB;
  final double dartHeapUsageMB;
  final double fps;
  final int batteryLevel;

  ResourceMetric({
    required this.timestamp,
    this.cpuUsagePercentage = 0.0,
    this.memoryUsageMB = 0.0,
    this.dartHeapUsageMB = 0.0,
    this.fps = 0.0,
    this.batteryLevel = 100,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'cpuUsagePercentage': cpuUsagePercentage,
    'memoryUsageMB': memoryUsageMB,
    'dartHeapUsageMB': dartHeapUsageMB,
    'fps': fps,
    'batteryLevel': batteryLevel,
  };

  factory ResourceMetric.fromJson(Map<String, dynamic> json) {
    return ResourceMetric(
      timestamp: DateTime.parse(json['timestamp'] as String),
      cpuUsagePercentage: (json['cpuUsagePercentage'] as num).toDouble(),
      memoryUsageMB: (json['memoryUsageMB'] as num).toDouble(),
      dartHeapUsageMB: (json['dartHeapUsageMB'] as num).toDouble(),
      fps: (json['fps'] as num).toDouble(),
      batteryLevel: json['batteryLevel'] as int,
    );
  }
}
