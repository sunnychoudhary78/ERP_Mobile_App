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

  Future<List<int>> downloadBytes(String path) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? <int>[];
  }

  // Future<dynamic> get(
  //   String endpoint, {
  //   Map<String, dynamic>? queryParams,
  // }) async {
  //   try {
  //     final response = await _dio.get(endpoint, queryParameters: queryParams);
  //     return _handle(response);
  //   } on DioException catch (e) {
  //     throw _extractException(e);
  //   }
  // }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: headers != null ? Options(headers: headers) : null,
      );
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

    final errorMessage = _findErrorMessage(errorData);
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      return Exception(
        'HTTP $statusCode${errorMessage == null ? '' : ': $errorMessage'}',
      );
    }

    if (errorMessage != null) {
      return Exception(errorMessage);
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

  String? _findErrorMessage(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List) {
      for (final item in value) {
        final message = _findErrorMessage(item);
        if (message != null) return message;
      }
      return null;
    }
    if (value is! Map) return null;

    for (final key in const ['message', 'error', 'detail']) {
      final message = _findErrorMessage(value[key]);
      if (message != null) return message;
    }

    for (final key in const ['data', 'errors']) {
      final message = _findErrorMessage(value[key]);
      if (message != null) return message;
    }

    return null;
  }
}
