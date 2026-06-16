import 'dart:async';
import 'dart:ui'; // Cần thiết để sử dụng FontFeature.tabularFigures()
import 'package:flutter/material.dart';
import '../../viettel_resource_monitor.dart';
import 'mobile_academic_dashboard.dart';
import 'dart:math';

class ViettelMiniPanel extends StatefulWidget {
  const ViettelMiniPanel({Key? key}) : super(key: key);

  @override
  State<ViettelMiniPanel> createState() => _ViettelMiniPanelState();
}

class _ViettelMiniPanelState extends State<ViettelMiniPanel> {
  double _xOffset = 20;
  double _yOffset = 100;

  double _fps = 0;
  double _ram = 0;
  bool _isAlerting = false;
  Timer? _alertTimer;

  StreamSubscription? _metricSub;
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    _metricSub = ViettelResourceMonitor.instance.metricStream.listen((metric) {
      if (mounted) {
        setState(() {
          _fps = metric.fps;
          _ram = metric.memoryUsageMB;
        });
      }
    });

    _alertSub = ViettelResourceMonitor.instance.alertStream.listen((alert) {
      if (mounted) {
        setState(() => _isAlerting = true);
        _alertTimer?.cancel();
        _alertTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isAlerting = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _metricSub?.cancel();
    _alertSub?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  void _openDashboard() {
    final navState =
        ViettelResourceMonitor.instance.navigatorObserver.navigator;
    if (navState == null) {
      debugPrint(
        'ViettelResourceMonitor: No Navigator found to display Dashboard.',
      );
      return;
    }

    // Tác động rung phản hồi nhẹ khi chạm mở panel
    Feedback.forLongPress(context);

    showModalBottomSheet(
      context: navState.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FractionallySizedBox(
        heightFactor: 0.95,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: MobileAcademicDashboard(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Giới hạn vùng kéo thả thông minh, tránh đè lên status bar/navigation bar
    _xOffset = max(16, min(_xOffset, size.width - 150));
    _yOffset = max(
      padding.top + 10,
      min(_yOffset, size.height - padding.bottom - 40),
    );

    // Cấu hình font chữ số kỹ thuật cố định khoảng cách (Tối giản & Tương phản cao)
    final textStyle = TextStyle(
      color: const Color(
        0xFF1F2937,
      ), // Màu xám slate đậm tinh tế thay cho đen kịt
      fontSize: 12,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Điểm nhấn đỏ Viettel nhẹ nhàng khi có cảnh báo vượt ngưỡng tài nguyên
    final viettelRed = const Color(0xFFEE0000);

    return Positioned(
      left: _xOffset,
      top: _yOffset,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xOffset += details.delta.dx;
            _yOffset += details.delta.dy;
          });
        },
        onTap: _openDashboard,
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              // Tạo hình viên nhộng (Capsule) bo tròn tối đa sạch sẽ
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                // Khi alert: Đổi màu viền sang đỏ Viettel mảnh, bình thường dùng màu xám DMS siêu nhạt
                color: _isAlerting ? viettelRed : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  // Đổ bóng mờ mịn, loại bỏ hoàn toàn viền sáng đỏ phát quang loè loẹt
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chỉ số FPS (Chuyển icon/text sang đỏ Viettel nếu có lỗi để cảnh báo trực quan)
                Icon(
                  Icons.thunderstorm_outlined, // Icon tối giản, kỹ thuật hơn
                  color: _isAlerting
                      ? viettelRed
                      : const Color(0xFF10B981), // Đỏ Viettel hoặc Xanh lá dịu
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_fps.toStringAsFixed(0)} FPS',
                  style: _isAlerting
                      ? textStyle.copyWith(color: viettelRed)
                      : textStyle,
                ),

                // Thanh phân cách đứng thanh lịch, mờ nhẹ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 1,
                    height: 12,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),

                // Chỉ số RAM
                const Icon(
                  Icons.analytics_outlined,
                  color: Color(
                    0xFF3B82F6,
                  ), // Xám xanh dương dịu chuyên cho kỹ thuật
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text('${_ram.toStringAsFixed(0)} MB', style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
