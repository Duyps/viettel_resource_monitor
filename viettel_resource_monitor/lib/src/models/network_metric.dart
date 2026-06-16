/// Represents a network request tracked by the monitor.
class NetworkMetric {
  final String url;
  final String method;
  final int statusCode;
  final int durationMilliseconds;
  final int requestSizeBytes;
  final int responseSizeBytes;
  final DateTime timestamp;

  NetworkMetric({
    required this.url,
    required this.method,
    required this.statusCode,
    required this.durationMilliseconds,
    this.requestSizeBytes = 0,
    this.responseSizeBytes = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': method,
    'statusCode': statusCode,
    'durationMilliseconds': durationMilliseconds,
    'requestSizeBytes': requestSizeBytes,
    'responseSizeBytes': responseSizeBytes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory NetworkMetric.fromJson(Map<String, dynamic> json) {
    return NetworkMetric(
      url: json['url'] as String,
      method: json['method'] as String,
      statusCode: json['statusCode'] as int,
      durationMilliseconds: json['durationMilliseconds'] as int,
      requestSizeBytes: json['requestSizeBytes'] as int,
      responseSizeBytes: json['responseSizeBytes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
