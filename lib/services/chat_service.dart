import 'package:dio/dio.dart';
import 'api_client.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final ApiClient _apiClient = ApiClient.instance;

  Future<Map<String, dynamic>> continueGuidedChat({
    String? sessionId,
    String? message,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/Chat/guided',
      data: {
        if (sessionId != null) 'sessionId': sessionId,
        if (message != null) 'message': message,
      },
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/Chat/guided/sessions');
    final data = response.data?['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getChatSessionDetail(String sessionId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/Chat/guided/sessions/$sessionId');
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<bool> deleteChatSession(String sessionId) async {
    final response = await _apiClient.dio.delete<Map<String, dynamic>>('/api/Chat/guided/sessions/$sessionId');
    return response.data?['success'] == true;
  }
}
