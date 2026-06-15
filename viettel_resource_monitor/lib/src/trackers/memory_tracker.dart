import 'dart:io';

class ViettelMemoryTracker {
  
  /// Returns the Resident Set Size (RSS) in MB (Total memory used by the process)
  double getRssMemoryMB() {
    return ProcessInfo.currentRss / (1024 * 1024);
  }

  /// Returns the Dart Heap memory usage in MB
  double getDartHeapUsageMB() {
    // Note: Accurate Dart heap requires VMService which is unavailable in release mode.
    return 0.0;
  }
}
