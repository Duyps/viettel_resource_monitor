import 'package:flutter/services.dart';

class ViettelCpuTracker {
  static const MethodChannel _channel = MethodChannel('viettel_resource_monitor');

  Future<double> getCpuUsage() async {
    try {
      final double usage = await _channel.invokeMethod('getCpuUsage') ?? 0.0;
      return usage;
    } on PlatformException {
      return 0.0;
    }
  }
}
