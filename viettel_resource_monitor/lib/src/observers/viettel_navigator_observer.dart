import 'package:flutter/material.dart';

/// Intercepts route changes to track screen sessions, ignoring dialogs, overlays and bottom sheets.
class ViettelNavigatorObserver extends NavigatorObserver {
  String? _currentRouteName;
  void Function(String routeName)? onRouteChanged;

  /// Keeps track of active page routes (full screens), ignoring PopupRoutes.
  final List<PageRoute<dynamic>> _pageRouteStack = [];

  /// Retrieves the current route name.
  String? get currentRouteName => _currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _pageRouteStack.add(route);
      _updateActiveRoute();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      _pageRouteStack.remove(route);
      _updateActiveRoute();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute is PageRoute) {
      _pageRouteStack.remove(oldRoute);
    }
    if (newRoute is PageRoute) {
      _pageRouteStack.add(newRoute);
    }
    _updateActiveRoute();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PageRoute) {
      _pageRouteStack.remove(route);
      _updateActiveRoute();
    }
  }

  void _updateActiveRoute() {
    final String routeName = _pageRouteStack.isNotEmpty
        ? (_pageRouteStack.last.settings.name ?? 'UnnamedRoute')
        : 'UnnamedRoute';

    if (_currentRouteName == routeName) return;
    _currentRouteName = routeName;
    onRouteChanged?.call(routeName);
  }
}
