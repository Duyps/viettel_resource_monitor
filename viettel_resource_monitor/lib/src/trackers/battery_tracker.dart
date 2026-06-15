import 'package:battery_plus/battery_plus.dart';

class ViettelBatteryTracker {
  final Battery _battery = Battery();

  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 100; // Default fallback
    }
  }
}
