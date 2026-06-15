import 'package:flutter_test/flutter_test.dart';

import 'package:viettel_resource_monitor/viettel_resource_monitor.dart';

void main() {
  test('ViettelResourceMonitor initializes successfully', () {
    final monitor = ViettelResourceMonitor.instance;
    expect(monitor.isInitialized, false);

    monitor.init(const ViettelResourceMonitorConfig(
      enableFPS: true,
      enableNetwork: false,
    ));

    expect(monitor.isInitialized, true);
  });
}
