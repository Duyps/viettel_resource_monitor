import 'package:flutter/material.dart';
import '../../models/screen_session.dart';

class NetworkTab extends StatelessWidget {
  final List<ScreenSession> allSessions;

  const NetworkTab({Key? key, required this.allSessions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allRequests = allSessions.expand((s) => s.networkMetrics).toList();
    allRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Độ trễ API & Network Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: allRequests.isEmpty
              ? const Center(child: Text('Chưa có yêu cầu mạng nào được ghi nhận.'))
              : ListView.separated(
                  itemCount: allRequests.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final req = allRequests[idx];
                    final isSlow = req.durationMilliseconds > 2000;
                    return ListTile(
                      tileColor: Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSlow ? const Color(0xFFEE0000).withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(req.method, style: TextStyle(color: isSlow ? const Color(0xFFEE0000) : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(req.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      subtitle: Text('${req.statusCode} • Payload: ${req.responseSizeBytes}B', style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                        '${req.durationMilliseconds}ms',
                        style: TextStyle(
                          color: isSlow ? const Color(0xFFEE0000) : Colors.black87,
                          fontWeight: isSlow ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
