import 'api_client.dart';

class WebStatsService {
  final ApiClient _apiClient = ApiClient();

  static final WebStatsService _instance = WebStatsService._internal();
  factory WebStatsService() => _instance;
  WebStatsService._internal();

  /// Tăng số lượt truy cập chung hôm nay
  Future<void> incrementWebVisits() async {
    try {
      await _apiClient.post('/api/web-stats/visits/increment');
    } catch (_) {
      // Bỏ qua lỗi ngầm nếu mất mạng hoặc offline
    }
  }

  /// Ghi nhận tài khoản truy cập hôm nay
  Future<void> recordUserVisit({String? userId}) async {
    try {
      final Map<String, dynamic> body = userId != null ? {'userId': userId} : {};
      await _apiClient.post('/api/web-stats/user-visits/record', data: body);
    } catch (_) {
      // Bỏ qua lỗi ngầm
    }
  }
}
