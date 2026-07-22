import 'package:dio/dio.dart';
import '../models/plan.dart';
import '../models/payment_transaction.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<PricingPlan>> getPlans() async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/Plans',
      options: Options(
        extra: const {ApiClient.skipAuthHeaderKey: true},
      ),
    );
    final data = response.data;
    if (data == null) return [];
    
    final list = data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    return list.map((json) => PricingPlan.fromJson(json)).toList();
  }

  Future<List<PaymentTransaction>> getMyTransactionHistory() async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/payment-history/my-history',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PaymentTransaction.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> createPaymentTransaction(String planId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/payment/create',
      data: {'planId': planId},
    );
    return response.data ?? {};
  }

  Future<void> cancelPaymentTransaction(String transactionCode) async {
    await _apiClient.dio.post<void>(
      '/api/payment/cancel',
      queryParameters: {'code': transactionCode},
    );
  }

  Future<void> activateEduKey(String key) async {
    await _apiClient.dio.post<void>(
      '/api/edu/activate',
      data: {'activationKey': key},
    );
  }

  Future<void> registerSchool({
    required String schoolName,
    required String contactName,
    required String email,
    required String phoneNumber,
    required int studentCount,
    required String notes,
    required String planId,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/edu/register',
      data: {
        'schoolName': schoolName,
        'contactName': contactName,
        'email': email,
        'phoneNumber': phoneNumber,
        'studentCount': studentCount,
        'notes': notes,
        'planId': planId,
      },
    );
  }
}
