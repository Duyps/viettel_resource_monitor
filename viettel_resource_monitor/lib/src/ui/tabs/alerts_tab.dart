import 'package:flutter/material.dart';
import '../../models/resource_alert.dart';

class AlertsTab extends StatelessWidget {
  final List<ResourceAlert> alerts;

  const AlertsTab({Key? key, required this.alerts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Lịch sử Cảnh báo (Phiên làm việc hiện tại)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: alerts.isEmpty
              ? const Center(child: Text('Chưa có cảnh báo nào được ghi nhận.'))
              : ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final alert = alerts[idx];
                    
                    Color alertColor;
                    IconData alertIcon;
                    
                    switch (alert.alertType) {
                      case AlertType.memoryLeak:
                        alertColor = Colors.orange;
                        alertIcon = Icons.memory;
                        break;
                      case AlertType.highCpu:
                        alertColor = const Color(0xFFEE0000);
                        alertIcon = Icons.developer_board;
                        break;
                      case AlertType.fpsDrop:
                        alertColor = Colors.orangeAccent;
                        alertIcon = Icons.speed;
                        break;
                      case AlertType.slowNetwork:
                        alertColor = const Color(0xFFEE0000);
                        alertIcon = Icons.network_check;
                        break;
                      case AlertType.sessionSummary:
                        alertColor = Colors.blue;
                        alertIcon = Icons.summarize;
                        break;
                    }

                    return ListTile(
                      tileColor: Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(alertIcon, color: alertColor, size: 20),
                      ),
                      title: Text(alert.message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                      subtitle: Text('Màn hình: ${alert.screenName}\nLúc: ${alert.timestamp.toString().substring(11, 19)}', style: const TextStyle(fontSize: 11, height: 1.5)),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
