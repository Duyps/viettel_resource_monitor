import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'viettel_resource_monitor_temp_method_channel.dart';

abstract class ViettelResourceMonitorTempPlatform extends PlatformInterface {
  /// Constructs a ViettelResourceMonitorTempPlatform.
  ViettelResourceMonitorTempPlatform() : super(token: _token);

  static final Object _token = Object();

  static ViettelResourceMonitorTempPlatform _instance = MethodChannelViettelResourceMonitorTemp();

  /// The default instance of [ViettelResourceMonitorTempPlatform] to use.
  ///
  /// Defaults to [MethodChannelViettelResourceMonitorTemp].
  static ViettelResourceMonitorTempPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ViettelResourceMonitorTempPlatform] when
  /// they register themselves.
  static set instance(ViettelResourceMonitorTempPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
