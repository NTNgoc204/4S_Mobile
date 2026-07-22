import 'package:dio/dio.dart';
import 'api_client.dart';

class QuizService {
  QuizService._();

  static final QuizService instance = QuizService._();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getQuestions() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/Questions');
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getQuestionOptions() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/QuestionOptions');
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getUserAnswers() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/UserAnswers');
    final data = response.data?['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createUserAnswer({
    required String questionId,
    required String answer,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/UserAnswers',
      data: {
        'questionId': questionId,
        'answer': answer,
      },
    );
  }

  Future<void> updateUserAnswer({
    required String questionId,
    required String answer,
  }) async {
    await _apiClient.dio.put<void>(
      '/api/UserAnswers',
      data: {
        'questionId': questionId,
        'answer': answer,
      },
    );
  }

  Future<void> deleteUserAnswers() async {
    await _apiClient.dio.delete<void>('/api/UserAnswers');
  }

  Future<List<Map<String, dynamic>>> getQuestionCategories() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/QuestionCategories');
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>?> evaluateCategory(String categoryId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/AiEvaluations/evaluate/$categoryId',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> getCategoryEvaluation(String categoryId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/AiEvaluations/$categoryId',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> evaluateOverall() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/UserAiSummaries/evaluate',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> getOverallSummary() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/UserAiSummaries',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }
}
