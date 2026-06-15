import Flutter
import UIKit

public class ViettelResourceMonitorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "viettel_resource_monitor", binaryMessenger: registrar.messenger())
    let instance = ViettelResourceMonitorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "getCpuUsage") {
      // Return Mock data for iOS to prevent crash
      result(0.0)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}
