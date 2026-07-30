import 'package:dio/dio.dart';

class SubscriptionInterceptor extends Interceptor {
  final void Function() onSubscriptionExpired;

  SubscriptionInterceptor({required this.onSubscriptionExpired});

  bool _isExpired(Response? response) {
    if (response?.statusCode == 402) return true;
    final data = response?.data;
    if (data is Map && data['expired'] == true) return true;
    return false;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_isExpired(response)) {
      onSubscriptionExpired();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isExpired(err.response)) {
      onSubscriptionExpired();
    }
    handler.next(err);
  }
}
