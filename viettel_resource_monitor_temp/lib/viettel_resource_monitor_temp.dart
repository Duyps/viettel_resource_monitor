
import 'viettel_resource_monitor_temp_platform_interface.dart';

class ViettelResourceMonitorTemp {
  Future<String?> getPlatformVersion() {
    return ViettelResourceMonitorTempPlatform.instance.getPlatformVersion();
  }
}
