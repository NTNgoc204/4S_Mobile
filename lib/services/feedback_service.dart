import 'api_client.dart';

class FeedbackService {
  FeedbackService._();

  static final FeedbackService instance = FeedbackService._();

  final ApiClient _apiClient = ApiClient.instance;

  /// Lấy danh sách câu hỏi khảo sát đang hoạt động
  Future<List<Map<String, dynamic>>> getActiveQuestions() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/feedback-questions/active',
    );
    final data = response.data?['data'];
    if (data == null || data is! List) return [];

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  /// Gửi phản hồi khảo sát của người dùng
  Future<void> submitFeedback({
    required String userEmail,
    required String userFullName,
    required List<Map<String, dynamic>> answers,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/feedbacks',
      data: {
        'userEmail': userEmail,
        'userFullName': userFullName,
        'answers': answers,
      },
    );
  }
}
