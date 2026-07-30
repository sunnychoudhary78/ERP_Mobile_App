import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/network_providers.dart';
import '../services/crypto_helper.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ApiService {
  final Dio _dio;
  final Ref ref;

  ApiService(this._dio, this.ref);

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final encryptedData = CryptoHelper.encryptPayload(data);
      final response = await _dio.post(
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint,
        data: encryptedData,
      );
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final encryptedData = CryptoHelper.encryptPayload(data);
      final response = await _dio.patch(endpoint, data: encryptedData);
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final encryptedData = CryptoHelper.encryptPayload(data);
      final response = await _dio.put(endpoint, data: encryptedData);
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> delete(String endpoint, Map<String, dynamic> data) async {
    try {
      final encryptedData = CryptoHelper.encryptPayload(data);
      final response = await _dio.delete(endpoint, data: encryptedData);
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> deleteNoBody(String endpoint) async {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    try {
      final response = await _dio.delete(path);
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> postMultipart(String endpoint, FormData formData) async {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final ct =
        '${Headers.multipartFormDataContentType}; boundary=${formData.boundary}';
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: ct),
      );
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<dynamic> putMultipart(String endpoint, FormData formData) async {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final ct =
        '${Headers.multipartFormDataContentType}; boundary=${formData.boundary}';
    try {
      final response = await _dio.put(
        path,
        data: formData,
        options: Options(contentType: ct),
      );
      return _handle(response);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  dynamic _handle(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      try {
        return CryptoHelper.decryptPayload(response.data);
      } catch (e) {
        debugPrint('Decryption failed: $e');
        return response.data;
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
    );
  }

  Exception _extractException(DioException e) {
    dynamic rawError = e.response?.data;
    dynamic errorData;
    try {
      errorData = CryptoHelper.decryptPayload(rawError);
    } catch (_) {
      errorData = rawError;
    }

    if (e.response?.statusCode == 402 ||
        (errorData is Map && errorData['expired'] == true)) {
      ref.read(sessionGuardProvider).trigger(() {
        ref.read(authProvider.notifier).forceSubscriptionExpired();
      });
      return Exception('SUBSCRIPTION_EXPIRED');
    }

    if (errorData is Map) {
      if (errorData['message'] != null) {
        return Exception(errorData['message']);
      }
      if (errorData['error'] != null) {
        return Exception(errorData['error']);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection');
    }

    return Exception('Something went wrong');
  }
}
