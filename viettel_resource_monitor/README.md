# Viettel Resource Monitor 📊

Một thư viện giám sát tài nguyên phần cứng (RAM, CPU, FPS, Network) dành riêng cho ứng dụng Flutter, được thiết kế theo nguyên lý **Zero-Overhead** (Không gây quá tải tài nguyên), giao diện thân thiện và tích hợp công cụ AI chẩn đoán thông minh.

## Tính Năng Nổi Bật 🚀
- 📈 **Giám sát thời gian thực:** Đo lường RAM, CPU, FPS và Network liên tục trên từng màn hình cụ thể.
- ⚡ **Zero-Overhead Dashboard:** Sử dụng `CustomPainter` tối ưu 100% thay vì các thư viện nặng như `fl_chart`. Giao diện Dashboard sẽ hoàn toàn dừng vẽ (Pause Rendering) khi đang chạy ngầm để không chiếm CPU/GPU.
- 🔔 **Hệ thống Cảnh báo (Alerts):** Tự động đẩy thông báo ra Console (CLI Table) hoặc Mini Panel khi chỉ số hệ thống vượt ngưỡng an toàn.
- 🧠 **AI Chẩn Đoán Hệ Thống (Heuristic Diagnosis):** Thuật toán tự động tìm ra điểm nghẽn của ứng dụng:
  - 💧 Rò rỉ RAM (Memory Leak)
  - 🛑 Nghẽn luồng chính (Main Thread Block)
  - 💥 Quá tải GPU do vẽ đè (UI Overdraw Jank)
  - 🐢 Nghẽn mạng (Slow API Latency)
- ⚙️ **Tính toán độc lập (Isolate Worker):** Công cụ chẩn đoán chạy trên luồng phụ (`compute()`), đảm bảo luồng UI (Main Thread) luôn đạt 60 FPS trong lúc phân tích lượng dữ liệu khổng lồ.

---

## Cài đặt 📦

1. Thêm gói vào `pubspec.yaml` của bạn:
```yaml
dependencies:
  viettel_resource_monitor:
    path: ./viettel_resource_monitor
```

2. Cài đặt các gói phụ thuộc:
```bash
flutter pub get
```

---

## Hướng dẫn sử dụng 🛠️

### 1. Khởi tạo hệ thống
Tại `main.dart`, hãy gọi hàm khởi tạo `ViettelResourceMonitor.instance.init` trước khi chạy ứng dụng:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ViettelResourceMonitor.instance.init(
    ViettelResourceMonitorConfig(
      enableFPS: true,
      enableNetwork: true,
      alertConfig: const ViettelAlertConfig(
        maxMemoryMB: 300, 
        maxNetworkDurationMs: 1500,
        minFps: 40,
        maxCpuPercentage: 50,
      ),
      onAlert: (alert) {
        debugPrint('⚠️ Cảnh báo tài nguyên: ${alert.message}');
      },
    ),
  );

  runApp(const MyApp());
}
```

### 2. Gắn Wrapper & Observer
Bạn cần bọc thẻ `builder` và thêm `navigatorObservers` vào trong `MaterialApp` để thư viện tự động thu thập dữ liệu trên từng màn hình:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: ViettelResourceMonitor.builder(),
      navigatorObservers: [ViettelResourceMonitor.instance.navigatorObserver],
      home: HomeScreen(),
    );
  }
}
```

### 3. Xem báo cáo Dashboard
Ứng dụng sẽ có một **Mini Panel** hiển thị nhỏ ở góc dưới màn hình. 
Bấm vào Mini Panel này để mở **Bảng Điều Khiển Chuyên Sâu (Dashboard)** với 5 phân hệ:
1. **RAM/CPU:** Biểu đồ ngang so sánh mức tiêu thụ tài nguyên giữa các màn hình.
2. **FPS Timeline:** Biểu đồ đường (Line Chart) mô phỏng khung hình trên giây.
3. **Network API:** Danh sách các cuộc gọi API và thời gian phản hồi.
4. **Chẩn Đoán:** Nút kích hoạt AI Chẩn Đoán dựa trên dữ liệu thu thập.
5. **Cảnh Báo:** Lịch sử ghi nhận các sự cố tụt FPS hoặc RAM vượt ngưỡng.

---

## Thiết kế Kiến Trúc 📐

- Thu thập khung hình thông qua `WidgetsBinding.instance.addTimingsCallback`.
- Ghi nhận RAM & CPU qua `ProcessInfo`.
- Đánh chặn Network API thông qua `HttpOverrides.global`.
- Phân tích bệnh lý Heuristic độc lập với `compute(runHeuristicAnalysis)`.

Dự án này là minh chứng cho việc đo lường hiệu năng có thể đạt được độ tin cậy tuyệt đối mà không cần sử dụng `DevTools` gắn qua cáp USB, rất thuận tiện cho quá trình QA/Tester.
