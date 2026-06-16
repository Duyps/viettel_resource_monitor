import 'package:flutter/material.dart';

/// Intercepts route changes to track screen sessions.
class ViettelNavigatorObserver extends NavigatorObserver {
  String? _currentRouteName;
  void Function(String routeName)? onRouteChanged;

  /// Retrieves the current route name.
  String? get currentRouteName => _currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteTransition(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _handleRouteTransition(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _handleRouteTransition(newRoute?.settings.name);
  }

  void _handleRouteTransition(String? newRouteName) {
    final routeName = newRouteName ?? 'UnnamedRoute';
    if (_currentRouteName == routeName) return;

    // TODO: Connect to Session Manager to end previous session and start a new one.
    // debugPrint('ViettelResourceMonitor: Transitioned to screen [$routeName]');
    
    _currentRouteName = routeName;
    onRouteChanged?.call(routeName);
  }
}
