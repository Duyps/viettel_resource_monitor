import 'package:flutter_test/flutter_test.dart';
import 'package:viettel_resource_monitor_temp/viettel_resource_monitor_temp.dart';
import 'package:viettel_resource_monitor_temp/viettel_resource_monitor_temp_platform_interface.dart';
import 'package:viettel_resource_monitor_temp/viettel_resource_monitor_temp_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockViettelResourceMonitorTempPlatform
    with MockPlatformInterfaceMixin
    implements ViettelResourceMonitorTempPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ViettelResourceMonitorTempPlatform initialPlatform = ViettelResourceMonitorTempPlatform.instance;

  test('$MethodChannelViettelResourceMonitorTemp is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelViettelResourceMonitorTemp>());
  });

  test('getPlatformVersion', () async {
    ViettelResourceMonitorTemp viettelResourceMonitorTempPlugin = ViettelResourceMonitorTemp();
    MockViettelResourceMonitorTempPlatform fakePlatform = MockViettelResourceMonitorTempPlatform();
    ViettelResourceMonitorTempPlatform.instance = fakePlatform;

    expect(await viettelResourceMonitorTempPlugin.getPlatformVersion(), '42');
  });
}
