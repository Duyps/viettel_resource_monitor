import 'resource_metric.dart';
import 'network_metric.dart';

/// Represents a user's session on a specific screen.
class ScreenSession {
  final String screenName;
  final DateTime startTime;
  DateTime? endTime;

  final List<ResourceMetric> resourceMetrics = [];
  final List<NetworkMetric> networkMetrics = [];

  ScreenSession({
    required this.screenName,
    required this.startTime,
  });

  /// Calculates the total duration spent on this screen in milliseconds.
  int? get durationMilliseconds {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMilliseconds;
  }

  /// Concludes the session by setting the end time.
  void endSession() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'screenName': screenName,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationMilliseconds': durationMilliseconds,
    'resourceMetrics': resourceMetrics.map((e) => e.toJson()).toList(),
    'networkMetrics': networkMetrics.map((e) => e.toJson()).toList(),
  };

  factory ScreenSession.fromJson(Map<String, dynamic> json) {
    final session = ScreenSession(
      screenName: json['screenName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
    );
    if (json['endTime'] != null) {
      session.endTime = DateTime.parse(json['endTime'] as String);
    }
    // We skip deep parsing of metrics for simplicity in this report unless needed
    return session;
  }
}
