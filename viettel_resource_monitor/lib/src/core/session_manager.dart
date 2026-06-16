import 'dart:async';
import '../models/screen_session.dart';
import '../models/resource_metric.dart';
import '../models/network_metric.dart';
import '../storage/hive_db_helper.dart';
import 'data_analyzer.dart';

class ViettelSessionManager {
  ScreenSession? _currentSession;
  ScreenSession? get currentSession => _currentSession;
  final ViettelDbHelper _dbHelper = ViettelDbHelper();
  ViettelDataAnalyzer? analyzer;

  Future<void> init() async {
    await _dbHelper.init();
  }

  void startSession(String screenName) {
    _closeCurrentSession();
    _currentSession = ScreenSession(screenName: screenName, startTime: DateTime.now());
  }

  void _closeCurrentSession() {
    if (_currentSession != null) {
      _currentSession!.endSession();
      analyzer?.analyzeSession(_currentSession!);
      // Save to Hive
      _dbHelper.saveSession(_currentSession!);
      _currentSession = null;
    }
  }

  void addResourceMetric(ResourceMetric metric) {
    _currentSession?.resourceMetrics.add(metric);
    if (_currentSession != null) {
      analyzer?.analyzeImmediateResource(metric, _currentSession!.screenName);
    }
  }

  void addNetworkMetric(NetworkMetric metric) {
    _currentSession?.networkMetrics.add(metric);
    if (_currentSession != null) {
      analyzer?.analyzeImmediateNetwork(metric, _currentSession!.screenName);
    }
  }

  List<ScreenSession> getSavedSessions() {
    return _dbHelper.getAllSessions();
  }

  Future<void> clearAllData() async {
    await _dbHelper.clearAll();
  }
}
