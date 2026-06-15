enum AlertType {
  fpsDrop,
  memoryLeak,
  highCpu,
  slowNetwork,
  sessionSummary
}

/// Represents an alert generated when a resource metric exceeds a threshold.
class ResourceAlert {
  final String screenName;
  final AlertType alertType;
  final String message;
  final DateTime timestamp;

  ResourceAlert({
    required this.screenName,
    required this.alertType,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'screenName': screenName,
    'alertType': alertType.name,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() {
    return '[${alertType.name.toUpperCase()}] $screenName: $message';
  }
}
