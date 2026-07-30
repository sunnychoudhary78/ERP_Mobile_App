import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'api_constants.dart';
import 'subscription_interceptor.dart';

class DioClient {
  final Dio dio;

  DioClient({
    required TokenStorage tokenStorage,
    required void Function() onSubscriptionExpired,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: '${ApiConstants.baseUrl}/',
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 25),
            contentType: 'application/json',
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('REQUEST ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('RESPONSE ${response.statusCode}');
          handler.next(response);
        },
        onError: (e, handler) {
          debugPrint('DIO ERROR ${e.requestOptions.uri} ${e.message}');
          handler.next(e);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getJwt();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    dio.interceptors.add(
      SubscriptionInterceptor(onSubscriptionExpired: onSubscriptionExpired),
    );
  }
}
