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

  Future<void> registerStep1({
    required String email,
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    String gender = 'Other',
  }) async {
    // Normalize dateOfBirth to ISO 8601 UTC (backend expects a DateTime string like 2026-06-04T16:31:17.420Z)
    String dobPayload = dateOfBirth;
    try {
      final parsed = DateTime.parse(dateOfBirth);
      dobPayload = parsed.toUtc().toIso8601String();
    } catch (_) {
      // keep original if parsing fails
    }

    await _apiClient.dio.post<void>(
      '/api/auth/register-step1',
      data: {
        'email': email,
        'fullName': fullName,
        'dateOfBirth': dobPayload,
        'address': address,
        'phoneNumber': phoneNumber,
        'gender': gender,
      },
      options: Options(
        extra: const {
          ApiClient.skipAuthRefreshKey: true,
          ApiClient.skipAuthHeaderKey: true,
        },
      ),
    );
  }

  Future<String> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/verify-otp',
      data: {'email': email, 'otp': otp},
      options: Options(
        extra: const {
          ApiClient.skipAuthRefreshKey: true,
          ApiClient.skipAuthHeaderKey: true,
        },
      ),
    );

    final verifyToken = response.data?['verifyToken'] as String?;
    if (verifyToken == null || verifyToken.isEmpty) {
      throw StateError('No verify token received from server');
    }
    return verifyToken;
  }

  Future<void> registerStep3({
    required String verifyToken,
    required String password,
  }) async {
    // Backend expects lowercase keys: verifyToken, password
    final payload = {'verifyToken': verifyToken, 'password': password};
    // Debug: log payload
    // ignore: avoid_print
    print('AuthService.registerStep3 payload: \\$payload');
    try {
      await _apiClient.dio.post<void>(
        '/api/auth/register-step3',
        data: payload,
        options: Options(
          extra: const {
            ApiClient.skipAuthRefreshKey: true,
            ApiClient.skipAuthHeaderKey: true,
          },
        ),
      );
    } catch (err) {
      // Log detailed Dio error for server diagnostics
      // ignore: avoid_print
      if (err is DioException) {
        final resp = err.response;
        // ignore: avoid_print
        print(
          'AuthService.registerStep3 DioException: status=${resp?.statusCode}',
        );
        // ignore: avoid_print
        print('AuthService.registerStep3 response.data: ${resp?.data}');
        // ignore: avoid_print
        print('AuthService.registerStep3 response.headers: ${resp?.headers}');
        // ignore: avoid_print
        print(
          'AuthService.registerStep3 request payload: ${err.requestOptions.data}',
        );
      } else {
        // ignore: avoid_print
        print('AuthService.registerStep3 error: $err');
      }
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.dio.post<void>(
      '/api/Auth/forgot-password',
      data: {'email': email},
      options: Options(
        extra: const {
          ApiClient.skipAuthRefreshKey: true,
          ApiClient.skipAuthHeaderKey: true,
        },
      ),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/Auth/reset-password',
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      options: Options(
        extra: const {
          ApiClient.skipAuthRefreshKey: true,
          ApiClient.skipAuthHeaderKey: true,
        },
      ),
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.put<void>(
      '/api/Auth/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
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
        return 'Thông tin gửi lên không hợp lệ. Vui lòng kiểm tra lại.';
      }
    }

    return 'Không thể kết nối máy chủ. Vui lòng thử lại.';
  }
}
