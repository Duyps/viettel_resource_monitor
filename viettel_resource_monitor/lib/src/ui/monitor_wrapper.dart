import 'package:flutter/material.dart';
import 'mini_panel.dart';

class ViettelMonitorWrapper extends StatelessWidget {
  final Widget child;

  const ViettelMonitorWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            child,
            const ViettelMiniPanel(),
          ],
        ),
      ),
    );
  }
}
