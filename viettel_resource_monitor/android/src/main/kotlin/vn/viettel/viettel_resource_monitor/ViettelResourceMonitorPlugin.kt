package vn.viettel.viettel_resource_monitor

import android.os.Process
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class ViettelResourceMonitorPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private var lastCpuTime: Long = 0
  private var lastUptime: Long = 0

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "viettel_resource_monitor")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getCpuUsage") {
      val currentCpuTime = Process.getElapsedCpuTime()
      val currentUptime = SystemClock.elapsedRealtime()

      if (lastCpuTime == 0L || lastUptime == 0L) {
        lastCpuTime = currentCpuTime
        lastUptime = currentUptime
        result.success(0.0)
        return
      }

      val cpuDiff = currentCpuTime - lastCpuTime
      val uptimeDiff = currentUptime - lastUptime

      if (uptimeDiff > 0) {
        val cpuUsage = (cpuDiff.toDouble() / uptimeDiff.toDouble()) * 100.0
        val cores = Runtime.getRuntime().availableProcessors()
        val finalUsage = cpuUsage / cores
        
        lastCpuTime = currentCpuTime
        lastUptime = currentUptime
        
        result.success(finalUsage)
      } else {
        result.success(0.0)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
