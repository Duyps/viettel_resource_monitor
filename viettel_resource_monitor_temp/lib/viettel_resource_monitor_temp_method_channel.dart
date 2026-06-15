import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'viettel_resource_monitor_temp_platform_interface.dart';

/// An implementation of [ViettelResourceMonitorTempPlatform] that uses method channels.
class MethodChannelViettelResourceMonitorTemp extends ViettelResourceMonitorTempPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('viettel_resource_monitor_temp');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
