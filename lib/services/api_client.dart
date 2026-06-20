import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _accessTokenKey = 'access_token';
  static const skipAuthRefreshKey = 'skipAuthRefresh';
  static const skipAuthHeaderKey = 'skipAuthHeader';
  static const _retryKey = 'authRetry';

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: const {'ngrok-skip-browser-warning': 'true'},
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  PersistCookieJar? _cookieJar;
  Future<void> Function()? _onSessionExpired;
  bool _initialized = false;

  Future<void> init({Future<void> Function()? onSessionExpired}) async {
    if (onSessionExpired != null) {
      _onSessionExpired = onSessionExpired;
    }
    if (_initialized) return;

    final documentsDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${documentsDir.path}/.cookies'),
    );

    dio.interceptors.add(CookieManager(_cookieJar!));
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra[skipAuthHeaderKey] == true) {
            handler.next(options);
            return;
          }

          final token = await accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final requestOptions = error.requestOptions;
          final canRefresh =
              response?.statusCode == 401 &&
              requestOptions.extra[skipAuthRefreshKey] != true &&
              requestOptions.extra[_retryKey] != true;

          if (!canRefresh) {
            handler.next(error);
            return;
          }

          try {
            final newToken = await refreshAccessToken();
            requestOptions.extra[_retryKey] = true;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch<dynamic>(requestOptions);
            handler.resolve(retryResponse);
          } catch (_) {
            await clearSession();
            await _onSessionExpired?.call();
            handler.next(error);
          }
        },
      ),
    );

    _initialized = true;
  }

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);

  Future<bool> get hasAccessToken async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String> refreshAccessToken() async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/Auth/refresh-token',
      options: Options(
        extra: const {skipAuthRefreshKey: true, skipAuthHeaderKey: true},
      ),
    );

    final token =
        response.data?['accessToken'] as String? ??
        response.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('No access token received from server');
    }

    await saveAccessToken(token);
    return token;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _cookieJar?.deleteAll();
  }

  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await dio.get<List<dynamic>>(
      '/api/Plans',
      options: Options(
        extra: const {skipAuthHeaderKey: true},
      ),
    );
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    final response = await dio.get<List<dynamic>>('/api/Questions');
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getQuestionOptions() async {
    final response = await dio.get<List<dynamic>>('/api/QuestionOptions');
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getUserAnswers() async {
    final response = await dio.get<Map<String, dynamic>>('/api/UserAnswers');
    final data = response.data?['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createUserAnswer({
    required String questionId,
    required String answer,
  }) async {
    await dio.post<void>(
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
    await dio.put<void>(
      '/api/UserAnswers',
      data: {
        'questionId': questionId,
        'answer': answer,
      },
    );
  }

  Future<void> deleteUserAnswers() async {
    await dio.delete<void>('/api/UserAnswers');
  }

  Future<List<Map<String, dynamic>>> getQuestionCategories() async {
    final response = await dio.get<List<dynamic>>('/api/QuestionCategories');
    final data = response.data;
    if (data == null) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>?> evaluateCategory(String categoryId) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/AiEvaluations/evaluate/$categoryId',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> getCategoryEvaluation(String categoryId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/AiEvaluations/$categoryId',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> evaluateOverall() async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/UserAiSummaries/evaluate',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> getOverallSummary() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/UserAiSummaries',
      options: Options(
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    return response.data;
  }
}
