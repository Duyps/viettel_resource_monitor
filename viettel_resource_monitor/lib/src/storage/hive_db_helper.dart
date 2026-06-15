import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/screen_session.dart';

class ViettelDbHelper {
  static const String boxName = 'viettel_resource_monitor_box';
  Box? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  Future<void> saveSession(ScreenSession session) async {
    if (_box == null) return;
    
    // Convert to JSON string for simple NoSQL storage without writing Hive Adapters
    final String jsonStr = jsonEncode(session.toJson());
    await _box!.add(jsonStr);
  }

  List<ScreenSession> getAllSessions() {
    if (_box == null) return [];
    
    final List<ScreenSession> sessions = [];
    for (var i = 0; i < _box!.length; i++) {
      final String? jsonStr = _box!.getAt(i) as String?;
      if (jsonStr != null) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          sessions.add(ScreenSession.fromJson(map));
        } catch (e) {
          // ignore parsing error for corrupted data
        }
      }
    }
    return sessions;
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }
}
