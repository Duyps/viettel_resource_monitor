import 'package:flutter/material.dart';
import 'mini_panel.dart';

class ViettelMonitorWrapper extends StatelessWidget {
  final Widget child;

  const ViettelMonitorWrapper({Key? key, required this.child}) : super(key: key);

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
