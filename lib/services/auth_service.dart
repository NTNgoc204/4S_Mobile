import 'package:dio/dio.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiClient _apiClient = ApiClient.instance;

  Future<void> init({Future<void> Function()? onSessionExpired}) {
    return _apiClient.init(onSessionExpired: onSessionExpired);
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/Auth/login',
      data: {'email': email, 'password': password},
      options: Options(
        extra: const {
          ApiClient.skipAuthRefreshKey: true,
          ApiClient.skipAuthHeaderKey: true,
        },
      ),
    );

    final token =
        response.data?['accessToken'] as String? ??
        response.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('No access token received from server');
    }

    await _apiClient.saveAccessToken(token);
    return getMe();
  }

  Future<String> refreshAccessToken() {
    return _apiClient.refreshAccessToken();
  }

  Future<UserProfile> getMe() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/Auth/me',
    );
    return UserProfile.fromMeResponse(response.data ?? const {});
  }

  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/Auth/upload-avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final avatarUrl = response.data?['avatarUrl'] as String?;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      throw StateError('No avatar URL received from server');
    }

    return avatarUrl;
  }

  Future<UserProfile?> restoreSession() async {
    await _apiClient.init();

    if (await _apiClient.hasAccessToken) {
      try {
        return await getMe();
      } catch (_) {
        // Fall through and try the refresh-token cookie below.
      }
    }

    try {
      await refreshAccessToken();
      return await getMe();
    } catch (_) {
      await _apiClient.clearSession();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post<void>(
        '/api/Auth/logout',
        options: Options(extra: const {ApiClient.skipAuthRefreshKey: true}),
      );
    } catch (_) {
      // Local session must be cleared even if server logout fails.
    } finally {
      await _apiClient.clearSession();
    }
  }

  String getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ?? data['title'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (error.response?.statusCode == 401) {
        return 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.';
      }
      if (error.response?.statusCode == 400) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
    }

    return 'Không thể kết nối máy chủ. Vui lòng thử lại.';
  }
}
