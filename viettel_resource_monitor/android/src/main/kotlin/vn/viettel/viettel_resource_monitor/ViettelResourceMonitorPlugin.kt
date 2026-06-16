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
      val reader = java.io.BufferedReader(java.io.FileReader("/proc/self/stat"))
      val stat = reader.readLine()
      reader.close()
      val stats = stat.split(" ")
      val utime = stats[13].toLong()
      val stime = stats[14].toLong()
      val cutime = stats[15].toLong()
      val cstime = stats[16].toLong()

      val totalCpuTime = utime + stime + cutime + cstime
      val currentUptime = SystemClock.elapsedRealtime()

      if (lastCpuTime == 0L || lastUptime == 0L) {
        lastCpuTime = totalCpuTime
        lastUptime = currentUptime
        result.success(0.0)
        return
      }

      val cpuDiff = totalCpuTime - lastCpuTime
      val uptimeDiff = currentUptime - lastUptime

      if (uptimeDiff > 0) {
        val clockTicksPerSecond = android.system.Os.sysconf(android.system.OsConstants._SC_CLK_TCK).toDouble()
        // cpuDiff is in clock ticks. uptimeDiff is in milliseconds.
        val cpuUsage = (cpuDiff / clockTicksPerSecond) / (uptimeDiff / 1000.0) * 100.0
        val cores = Runtime.getRuntime().availableProcessors()
        val finalUsage = cpuUsage / cores
        
        lastCpuTime = totalCpuTime
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
