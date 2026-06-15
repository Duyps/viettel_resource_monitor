import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viettel_resource_monitor_temp/viettel_resource_monitor_temp_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelViettelResourceMonitorTemp platform = MethodChannelViettelResourceMonitorTemp();
  const MethodChannel channel = MethodChannel('viettel_resource_monitor_temp');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
